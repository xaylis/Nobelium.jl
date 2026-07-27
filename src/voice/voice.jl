export VoiceClient, connect_voice!, disconnect_voice!, play!, set_speaking!

# Experimental voice support: joins a channel, negotiates the voice gateway
# (v8) and UDP transport, and streams pre-encoded Opus frames. Send-only, no
# DAVE end-to-end encryption yet — see the voice guide for the caveats.

module VoiceOp
const identify = 0
const select_protocol = 1
const ready = 2
const heartbeat = 3
const session_description = 4
const speaking = 5
const heartbeat_ack = 6
const resume = 7
const hello = 8
const resumed = 9
const client_disconnect = 13
end

const VOICE_GATEWAY_VERSION = 8

"""
    VoiceClient

A live connection to a voice channel, produced by [`connect_voice!`](@ref).
"""
mutable struct VoiceClient
    const client::Client
    const guild_id::Snowflake
    const channel_id::Snowflake
    const user_id::Snowflake
    const session_id::String
    const token::String
    const endpoint::String
    ws::Any
    udp::Union{Sockets.UDPSocket,Nothing}
    voice_ip::String
    voice_port::Int
    ssrc::UInt32
    secret_key::Vector{UInt8}
    seq_ack::Int
    rtp_seq::UInt16
    rtp_timestamp::UInt32
    nonce_counter::UInt32
    speaking::Bool
    running::Bool
    failure::Any                 # what ended the connection, for error reporting
    const ready::Base.Event
end

VoiceClient(client, guild_id, channel_id, user_id, session_id, token, endpoint) =
    VoiceClient(client, guild_id, channel_id, user_id, session_id, token, endpoint,
                nothing, nothing, "", 0, 0, UInt8[], -1,
                rand(UInt16), rand(UInt32), 0, false, false, nothing, Base.Event())

"""
    connect_voice!(client, guild_id, channel_id; timeout=10) -> VoiceClient

Join a voice channel and complete the voice handshake. Requires
`libsodium_jll` to be loaded alongside Nobelium (it provides the mandatory
transport encryption), and the `guild_voice_states` intent.

```julia
using Nobelium, libsodium_jll
vc = connect_voice!(client, guild_id, channel_id)
play!(vc, OpusFrames(frames))
disconnect_voice!(vc)
```
"""
function connect_voice!(client::Client, guild::SnowflakeLike, channel::SnowflakeLike;
                        timeout::Real=10)
    voice_encryption_available() ||
        error("voice needs transport encryption: run `using libsodium_jll` before connecting")
    gid = snowflake(guild)
    me = get_current_user(client.api).id

    state = Ref{Any}(nothing)
    server = Ref{Any}(nothing)
    t1 = @async begin
        state[] = wait_for(client, VoiceStateUpdate; timeout) do _, ev
            ev.voice_state.guild_id === gid && ev.voice_state.user_id == me
        end
    end
    t2 = @async begin
        server[] = wait_for(client, VoiceServerUpdate; timeout) do _, ev
            ev.guild_id == gid
        end
    end
    update_voice_state!(client, gid, channel)
    wait(t1); wait(t2)
    state[] === nothing && error("voice state update never arrived (missing guild_voice_states intent?)")
    server[] === nothing && error("voice server update never arrived")
    server[].endpoint === nothing && error("voice server has no endpoint (try again later)")

    vc = VoiceClient(client, gid, snowflake(channel), me,
                     state[].voice_state.session_id, server[].token,
                     String(server[].endpoint))
    vc.running = true
    errormonitor(@async _run_voice!(vc))
    wait(vc.ready)
    if !vc.running
        reason = vc.failure === nothing ?
            "the voice gateway closed before sending a session description" :
            sprint(showerror, vc.failure)
        error("voice handshake failed: $reason")
    end
    vc
end

_voice_payload(vc::VoiceClient, op::Int, d) =
    HTTP.WebSockets.send(vc.ws, JSON3.write((; op, d)))

function _run_voice!(vc::VoiceClient)
    url = "wss://$(vc.endpoint)/?v=$VOICE_GATEWAY_VERSION"
    try
        HTTP.WebSockets.open(url; suppress_close_error=true) do ws
            vc.ws = ws
            # The voice gateway expects identify promptly, so this must not wait
            # on a REST call — connect_voice! already knows who we are.
            _voice_payload(vc, VoiceOp.identify, (;
                server_id = vc.guild_id,
                user_id = vc.user_id,
                session_id = vc.session_id,
                token = vc.token,
                max_dave_protocol_version = 0,
            ))
            while vc.running
                msg = try
                    HTTP.WebSockets.receive(ws)
                catch e
                    vc.failure === nothing && (vc.failure = e)
                    break
                end
                _handle_voice_payload!(vc, JSON3.read(msg isa AbstractString ? String(msg) : String(copy(msg))))
            end
        end
    catch e
        e isa InterruptException && rethrow()
        vc.failure = e
        @error "voice connection failed" exception = (e, catch_backtrace())
    finally
        vc.running = false
        vc.ws = nothing
        notify(vc.ready)
    end
end

# Heartbeats outlive nothing: the websocket can go away between any two beats,
# and on a dropped connection it does so without a close frame. A send failure
# here means the connection is gone, not that anything went wrong, so stop
# quietly and leave the teardown to _run_voice!.
function _heartbeat_loop!(vc::VoiceClient, interval::Real)
    while vc.running && vc.ws !== nothing
        try
            _voice_payload(vc, VoiceOp.heartbeat,
                           (; t = time_ns() ÷ 1_000_000, seq_ack = vc.seq_ack))
        catch e
            e isa InterruptException && rethrow()
            return
        end
        # Wake often enough that disconnecting doesn't have to wait out a whole
        # interval, which is when a beat would land on an already-closed socket.
        deadline = time() + interval
        while vc.running && vc.ws !== nothing && time() < deadline
            sleep(clamp(deadline - time(), 0.01, 0.5))
        end
    end
    nothing
end

function _handle_voice_payload!(vc::VoiceClient, payload)
    haskey(payload, :seq) && (vc.seq_ack = payload.seq)
    op = payload.op

    if op == VoiceOp.hello
        interval = payload.d.heartbeat_interval / 1000
        errormonitor(@async _heartbeat_loop!(vc, interval))
    elseif op == VoiceOp.ready
        vc.ssrc = UInt32(payload.d.ssrc)
        VOICE_ENCRYPTION_MODE in payload.d.modes ||
            error("voice server doesn't offer $VOICE_ENCRYPTION_MODE")
        ip, port = _discover_ip!(vc, String(payload.d.ip), Int(payload.d.port))
        _voice_payload(vc, VoiceOp.select_protocol, (;
            protocol = "udp",
            data = (; address = ip, port, mode = VOICE_ENCRYPTION_MODE),
        ))
    elseif op == VoiceOp.session_description
        vc.secret_key = Vector{UInt8}(payload.d.secret_key)
        notify(vc.ready)
    end
    nothing
end

# This runs on the websocket reader, so blocking here stops us reading the
# gateway too: a probe that never comes back would stall until Discord gave up on
# the handshake, reporting nothing useful. Bound the wait and say what happened.
function _recv_probe(udp::Sockets.UDPSocket, seconds::Real)
    got = Ref{Any}(nothing)
    done = Ref(false)
    errormonitor(@async begin
        try
            got[] = Sockets.recv(udp)
        catch e
            got[] = e
        finally
            done[] = true
        end
    end)
    deadline = time() + seconds
    while !done[] && time() < deadline
        sleep(0.02)
    end
    done[] || error("no reply to the UDP IP-discovery probe after $(seconds)s — " *
                    "outbound UDP to Discord's voice servers is most likely blocked")
    got[] isa Exception && throw(got[])
    got[]::Vector{UInt8}
end

# Discord's IP discovery: a 74-byte probe carrying our ssrc comes back with
# the public address the server sees.
function _discover_ip!(vc::VoiceClient, server_ip::String, server_port::Int)
    vc.voice_ip = server_ip
    vc.voice_port = server_port
    udp = Sockets.UDPSocket()
    Sockets.bind(udp, Sockets.ip"0.0.0.0", 0)
    vc.udp = udp

    probe = zeros(UInt8, 74)
    probe[1:2] = reinterpret(UInt8, [hton(UInt16(0x1))])
    probe[3:4] = reinterpret(UInt8, [hton(UInt16(70))])
    probe[5:8] = reinterpret(UInt8, [hton(vc.ssrc)])
    Sockets.send(udp, Sockets.getaddrinfo(server_ip), server_port, probe)

    response = _recv_probe(udp, 5)
    length(response) >= 74 ||
        error("IP-discovery reply was $(length(response)) bytes, expected at least 74")
    stop = findfirst(iszero, @view response[9:72])
    stop === nothing && error("IP-discovery reply had no null-terminated address")
    ip = String(response[9:stop+7])
    port = Int(ntoh(reinterpret(UInt16, response[73:74])[1]))
    ip, port
end

"""
    set_speaking!(vc::VoiceClient, speaking=true)

Toggle the speaking indicator. `play!` does this automatically.
"""
function set_speaking!(vc::VoiceClient, speaking::Bool=true)
    vc.speaking = speaking
    _voice_payload(vc, VoiceOp.speaking,
                   (; speaking = speaking ? 1 : 0, delay = 0, ssrc = vc.ssrc))
end

function _send_frame!(vc::VoiceClient, opus::AbstractVector{UInt8})
    header = rtp_header(vc.rtp_seq, vc.rtp_timestamp, vc.ssrc)
    vc.nonce_counter += UInt32(1)
    packet = encrypt_rtp_packet(opus, header, vc.nonce_counter, vc.secret_key)
    Sockets.send(vc.udp, Sockets.getaddrinfo(vc.voice_ip), vc.voice_port, packet)
    vc.rtp_seq += UInt16(1)
    vc.rtp_timestamp += UInt32(SAMPLES_PER_FRAME)
    nothing
end

"""
    play!(vc::VoiceClient, source::AudioSource)

Stream an audio source (20 ms Opus frames) to the channel, blocking until it
ends. Frames are paced in real time.
"""
function play!(vc::VoiceClient, source::AudioSource)
    isempty(vc.secret_key) && error("voice connection not ready")
    set_speaking!(vc, true)
    start = time()
    sent = 0
    try
        for frame in source
            _send_frame!(vc, frame)
            sent += 1
            target = start + sent * FRAME_MILLIS / 1000
            delay = target - time()
            delay > 0 && sleep(delay)
        end
        for _ in 1:5
            _send_frame!(vc, SILENCE_FRAME)
            sleep(FRAME_MILLIS / 1000)
        end
    finally
        # If the connection dropped mid-playback this send fails too; don't let
        # that replace the error that actually ended playback.
        try
            set_speaking!(vc, false)
        catch e
            e isa InterruptException && rethrow()
        end
    end
    nothing
end

"""
    disconnect_voice!(vc::VoiceClient)

Leave the voice channel and tear the connection down.
"""
function disconnect_voice!(vc::VoiceClient)
    vc.running = false
    update_voice_state!(vc.client, vc.guild_id, nothing)
    vc.ws === nothing || try
        HTTP.WebSockets.close(vc.ws, HTTP.WebSockets.CloseFrameBody(1000, ""))
    catch
    end
    vc.udp === nothing || close(vc.udp)
    nothing
end
