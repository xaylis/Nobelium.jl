# One websocket connection to the gateway. The state machine lives in
# handle_payload! and is transport-agnostic so tests can drive it directly;
# run_shard! adds the real websocket, reconnection, and backoff around it.

# Opcodes: https://docs.discord.com/developers/events/gateway#payload-structure
module Opcode
const dispatch = 0
const heartbeat = 1
const identify = 2
const presence_update = 3
const voice_state_update = 4
const resume = 6
const reconnect = 7
const request_guild_members = 8
const invalid_session = 9
const hello = 10
const heartbeat_ack = 11
const request_soundboard_sounds = 31
const request_channel_info = 43
end

# Close codes that end the session for good — reconnecting can't help.
const FATAL_CLOSE_CODES = (4004, 4010, 4011, 4012, 4013, 4014)
# Codes after which the session is gone but a fresh identify is fine.
const RESET_SESSION_CODES = (4007, 4009)

mutable struct Shard
    const id::Int
    const count::Int
    const client::Any        # owning Client
    ws::Any
    session_id::Union{String,Nothing}
    resume_url::Union{String,Nothing}
    seq::Union{Int,Nothing}
    heartbeat_interval::Float64
    acked::Bool
    last_beat::Float64
    latency::Float64
    running::Bool
    fatal::Union{GatewayClosedError,Nothing}
    const ready::Base.Event
end

Shard(id::Int, count::Int, client) =
    Shard(id, count, client, nothing, nothing, nothing, nothing,
          41.25, true, 0.0, 0.0, false, nothing, Base.Event())

# Transport interface; production methods for HTTP.WebSockets, test doubles
# just add their own methods.
send_message(ws::HTTP.WebSockets.WebSocket, s::AbstractString) = HTTP.WebSockets.send(ws, s)
close_ws(ws::HTTP.WebSockets.WebSocket, code::Int) =
    try
        HTTP.WebSockets.close(ws, HTTP.WebSockets.CloseFrameBody(code, ""))
    catch
    end

send_payload(shard::Shard, op::Int, d) =
    send_message(shard.ws, JSON3.write((; op, d)))

function handle_payload!(shard::Shard, text::AbstractString)
    payload = JSON3.read(text)
    op = payload.op

    if op == Opcode.dispatch
        shard.seq = payload.s
        _handle_dispatch!(shard, String(payload.t), payload.d)
    elseif op == Opcode.heartbeat
        send_payload(shard, Opcode.heartbeat, shard.seq)
    elseif op == Opcode.reconnect
        @debug "shard $(shard.id): server requested reconnect"
        close_ws(shard.ws, 4000)
    elseif op == Opcode.invalid_session
        if payload.d === true
            _resume!(shard)
        else
            shard.session_id = nothing
            shard.seq = nothing
            sleep(1 + 4rand())
            _identify!(shard)
        end
    elseif op == Opcode.hello
        shard.heartbeat_interval = payload.d.heartbeat_interval / 1000
        shard.acked = true
        _start_heartbeat!(shard)
        shard.session_id === nothing ? _identify!(shard) : _resume!(shard)
    elseif op == Opcode.heartbeat_ack
        shard.acked = true
        shard.latency = time() - shard.last_beat
    end
    nothing
end

# Included in parse-failure logs so bug reports carry the offending JSON.
function _payload_excerpt(d, limit=4096)
    s = redact(JSON3.write(d))
    length(s) <= limit ? s : first(s, limit) * "…"
end

function _handle_dispatch!(shard::Shard, name::String, d)
    if name == "READY"
        shard.session_id = String(d.session_id)
        shard.resume_url = String(d.resume_gateway_url)
    end
    T = get(EVENT_TYPES, name, nothing)
    event = if T === nothing
        UnknownEvent(name, d)
    elseif d === nothing || fieldcount(T) == 0 
        T()
    else
        try
            StructTypes.construct(T, d)
        catch e
            @error "shard $(shard.id): failed to parse $name payload" payload = _payload_excerpt(d) exception = (e, catch_backtrace())
            UnknownEvent(name, d)
        end
    end
    client = shard.client
    try
        _update_cache!(client, event)
    catch e
        @error "cache update for $name failed" exception = (e, catch_backtrace())
    end
    dispatch!(client.dispatcher, client, event)
    name == "READY" && notify(shard.ready)
    nothing
end

function _identify!(shard::Shard)
    client = shard.client
    d = (;
        token = client.token,
        properties = (; os = string(Sys.KERNEL), browser = "Nobelium", device = "Nobelium"),
        intents = client.intents.value,
        shard = [shard.id, shard.count],
    )
    client.presence === nothing || (d = (; d..., presence = client.presence))
    send_payload(shard, Opcode.identify, d)
end

_resume!(shard::Shard) =
    send_payload(shard, Opcode.resume,
                 (token = shard.client.token, session_id = shard.session_id, seq = shard.seq))

function _start_heartbeat!(shard::Shard)
    ws = shard.ws
    interval = shard.heartbeat_interval
    errormonitor(@async begin
        sleep(interval * rand())
        while shard.running && shard.ws === ws
            if !shard.acked
                @warn "shard $(shard.id): heartbeat not acknowledged, reconnecting"
                close_ws(ws, 4000)
                break
            end
            shard.acked = false
            shard.last_beat = time()
            try
                send_payload(shard, Opcode.heartbeat, shard.seq)
            catch
                break
            end
            sleep(interval)
        end
    end)
end

_gateway_url(shard::Shard) =
    string(something(shard.resume_url, shard.client.gateway_url),
           "/?v=", API_VERSION, "&encoding=json")

function run_shard!(shard::Shard)
    backoff = 1.0
    while shard.running
        code = nothing
        try
            HTTP.WebSockets.open(_gateway_url(shard); suppress_close_error=true) do ws
                shard.ws = ws
                backoff = 1.0
                while shard.running
                    msg = try
                        HTTP.WebSockets.receive(ws)
                    catch e
                        if e isa HTTP.WebSockets.WebSocketError &&
                           e.message isa HTTP.WebSockets.CloseFrameBody
                            code = Int(e.message.status)
                        end
                        break
                    end
                    handle_payload!(shard, msg isa AbstractString ? String(msg) : String(copy(msg)))
                end
            end
        catch e
            e isa InterruptException && rethrow()
            @debug "shard $(shard.id): connection error" exception = e
        end
        shard.ws = nothing
        shard.running || break

        if code in FATAL_CLOSE_CODES
            shard.fatal = GatewayClosedError(code, "", false)
            shard.running = false
            notify(shard.ready)   # unblock anyone waiting on startup
            @error "shard $(shard.id): fatal gateway close" exception = shard.fatal
            # a fatal close (bad token, bad intents) dooms every shard equally
            stop!(shard.client)
            break
        end
        if code in RESET_SESSION_CODES
            shard.session_id = nothing
            shard.seq = nothing
        end
        code === nothing || @warn "shard $(shard.id): gateway closed with code $code, reconnecting"
        sleep(backoff * (0.75 + rand() / 2))
        backoff = min(backoff * 2, 60.0)
    end
    nothing
end
