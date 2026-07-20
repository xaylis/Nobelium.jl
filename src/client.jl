export Client, start!, stop!, update_presence!, request_guild_members!,
    update_voice_state!, request_soundboard_sounds!, activity

"""
    Client(token; intents=Intent.default, shards=:auto, cache=CacheConfig(), presence=nothing)

A gateway-connected bot: REST access through `client.api`, events through
[`on!`](@ref), entity caches under `client.cache`.

```julia
client = Client(ENV["DISCORD_TOKEN"]; intents=Intent.default | Intent.message_content)
on!(client, MessageCreate) do c, ev
    ev.message.author.bot === true && return
    startswith(ev.message.content, "!ping") && create_message(c.api, ev.message.channel_id; content="pong")
end
start!(client)
```

`shards=:auto` asks Discord for the recommended count; pass an integer to force
one. `presence` takes the same shape as [`update_presence!`](@ref)'s keywords.
"""
mutable struct Client
    const token::String
    const api::API
    const intents::Intents
    const dispatcher::Dispatcher
    const cache::Cache
    presence::Any
    shard_spec::Union{Int,Symbol}
    gateway_url::String
    shards::Vector{Shard}
    tasks::Vector{Task}
    running::Bool
end

function Client(token::AbstractString;
                intents::Intents=Intent.default,
                shards::Union{Integer,Symbol}=:auto,
                cache::CacheConfig=CacheConfig(),
                presence=nothing,
                api_kwargs...)
    token = String(strip(token))
    Client(token, API(token; api_kwargs...), intents, Dispatcher(), Cache(cache),
           presence, shards isa Symbol ? shards : Int(shards),
           "wss://gateway.discord.gg", Shard[], Task[], false)
end

Base.show(io::IO, c::Client) =
    print(io, "Client(", length(c.shards), " shard", length(c.shards) == 1 ? "" : "s",
          c.running ? ", running" : ", stopped", ")")

"""
    on!(handler, client, EventType)

Register `handler(client, event)` for a gateway event type. Returns the handler
so it can be removed again with [`off!`](@ref).

```julia
on!(client, GuildMemberAdd) do c, ev
    @info "\$(display_name(ev.member.user)) joined"
end
```
"""
on!(f, c::Client, T::Type{<:AbstractEvent}) = _register!(c.dispatcher, T, f)

"""
    off!(client, EventType, handler)

Remove a handler previously added with [`on!`](@ref).
"""
off!(c::Client, T::Type{<:AbstractEvent}, f) = _unregister!(c.dispatcher, T, f)

"""
    wait_for(pred, client, EventType; timeout=nothing) -> event or nothing

Block until an event of `EventType` satisfying `pred(client, event)` arrives,
or `timeout` seconds pass (returning `nothing`).

```julia
ev = wait_for(client, MessageCreate; timeout=30) do c, ev
    ev.message.author.id == user_id
end
```
"""
wait_for(pred, c::Client, T::Type{<:AbstractEvent}; timeout=nothing) =
    _wait_for(pred, c.dispatcher, T; timeout)
wait_for(c::Client, T::Type{<:AbstractEvent}; timeout=nothing) =
    _wait_for((_, _) -> true, c.dispatcher, T; timeout)

"""
    start!(client; async=false)

Connect to the gateway. Blocks until [`stop!`](@ref) is called; with
`async=true` it returns once every shard has received READY instead.
"""
function start!(client::Client; async::Bool=false)
    client.running && throw(ArgumentError("client is already running"))
    client.running = true

    info = get_gateway_bot(client.api)
    client.gateway_url = info.url
    count = client.shard_spec === :auto ? info.shards : client.shard_spec
    concurrency = max(info.session_start_limit.max_concurrency, 1)

    client.shards = [Shard(i, count, client) for i in 0:count-1]
    client.tasks = map(client.shards) do shard
        shard.running = true
        wave = shard.id ÷ concurrency
        errormonitor(@async begin
            sleep(5.0 * wave)
            run_shard!(shard)
        end)
    end

    for shard in client.shards
        wait(shard.ready)
        if shard.fatal !== nothing
            stop!(client)
            throw(shard.fatal)
        end
    end
    async && return client

    foreach(wait, client.tasks)
    for shard in client.shards
        shard.fatal === nothing || throw(shard.fatal)
    end
    client
end

"""
    stop!(client)

Disconnect all shards and stop the client.
"""
function stop!(client::Client)
    client.running = false
    for shard in client.shards
        shard.running = false
        shard.ws === nothing || close_ws(shard.ws, 1000)
    end
    client
end

# Which shard a guild's events arrive on.
_shard_for(c::Client, guild) =
    c.shards[Int(snowflake(guild).value >> 22 % length(c.shards)) + 1]

"""
    activity(name; type=0, state=nothing, url=nothing) -> NamedTuple

An activity for [`update_presence!`](@ref). Types: 0 playing, 1 streaming,
2 listening, 3 watching, 4 custom (uses `state`), 5 competing.
"""
function activity(name::AbstractString; type::Integer=0, state=nothing, url=nothing)
    a = (; name, type = Int(type))
    state === nothing || (a = (; a..., state))
    url === nothing || (a = (; a..., url))
    a
end

"""
    update_presence!(client; status="online", activities=[], afk=false, since=nothing)

Set the bot's presence on every shard. `status` is one of `"online"`, `"idle"`,
`"dnd"`, or `"invisible"`.

```julia
update_presence!(client; status="idle", activities=[activity("the long game"; type=3)])
```
"""
function update_presence!(client::Client; status::AbstractString="online",
                          activities=[], afk::Bool=false, since=nothing)
    d = (; since, activities, status, afk)
    client.presence = d
    for shard in client.shards
        shard.ws === nothing || send_payload(shard, Opcode.presence_update, d)
    end
    nothing
end

"""
    request_guild_members!(client, guild_id; query="", limit=0, presences, user_ids, nonce)

Ask the gateway to stream a guild's members back as `GuildMembersChunk` events.
Requires the `guild_members` intent for a full listing.
"""
function request_guild_members!(client::Client, guild::SnowflakeLike; query="", limit=0, kwargs...)
    d = (; guild_id = snowflake(guild), query, limit,
         (Symbol(k) => v for (k, v) in kwargs if v !== missing)...)
    send_payload(_shard_for(client, guild), Opcode.request_guild_members, d)
end

"""
    update_voice_state!(client, guild_id, channel_id; self_mute=false, self_deaf=false)

Join a voice channel (or leave, with `channel_id=nothing`).
"""
function update_voice_state!(client::Client, guild::SnowflakeLike, channel;
                             self_mute::Bool=false, self_deaf::Bool=false)
    d = (; guild_id = snowflake(guild),
         channel_id = channel === nothing ? nothing : snowflake(channel),
         self_mute, self_deaf)
    send_payload(_shard_for(client, guild), Opcode.voice_state_update, d)
end

"""
    request_soundboard_sounds!(client, guild_ids)

Ask for `SoundboardSounds` events for the given guilds.
"""
function request_soundboard_sounds!(client::Client, guilds::AbstractVector)
    ids = [snowflake(g) for g in guilds]
    isempty(ids) && return
    send_payload(_shard_for(client, first(ids)), Opcode.request_soundboard_sounds,
                 (; guild_ids = ids))
end

# --- gateway-driven cache maintenance --------------------------------------
# These run on the shard reader before user handlers; they must stay cheap.

_update_cache!(::Client, ev) = nothing

function _update_cache!(c::Client, ev::GuildCreate)
    g = ev.guild
    c.cache.guilds[g.id] = g
    for ch in coalesce(ev.channels, ())
        c.cache.channels[ch.id] = ch
    end
    for m in coalesce(ev.members, ())
        m.user === missing && continue
        c.cache.members[(g.id, m.user.id)] = m
        c.cache.users[m.user.id] = m.user
    end
    nothing
end

_update_cache!(c::Client, ev::GuildUpdate) = (c.cache.guilds[ev.guild.id] = ev.guild; nothing)
_update_cache!(c::Client, ev::GuildDelete) = (delete!(c.cache.guilds, ev.id); nothing)

_update_cache!(c::Client, ev::ChannelCreate) = (c.cache.channels[ev.channel.id] = ev.channel; nothing)
_update_cache!(c::Client, ev::ChannelUpdate) = (c.cache.channels[ev.channel.id] = ev.channel; nothing)
_update_cache!(c::Client, ev::ChannelDelete) = (delete!(c.cache.channels, ev.channel.id); nothing)
_update_cache!(c::Client, ev::ThreadCreate) = (c.cache.channels[ev.channel.id] = ev.channel; nothing)
_update_cache!(c::Client, ev::ThreadUpdate) = (c.cache.channels[ev.channel.id] = ev.channel; nothing)
_update_cache!(c::Client, ev::ThreadDelete) = (delete!(c.cache.channels, ev.id); nothing)

function _update_cache!(c::Client, ev::GuildMemberAdd)
    m = ev.member
    m.user === missing && return nothing
    c.cache.members[(ev.guild_id, m.user.id)] = m
    c.cache.users[m.user.id] = m.user
    nothing
end

_update_cache!(c::Client, ev::GuildMemberRemove) =
    (delete!(c.cache.members, (ev.guild_id, ev.user.id)); nothing)

function _update_cache!(c::Client, ev::MessageCreate)
    m = ev.message
    c.cache.messages[m.id] = m
    c.cache.users[m.author.id] = m.author
    nothing
end

_update_cache!(c::Client, ev::MessageDelete) = (delete!(c.cache.messages, ev.id); nothing)
_update_cache!(c::Client, ev::UserUpdate) = (c.cache.users[ev.user.id] = ev.user; nothing)
