# Client and events

## The client

```julia
client = Client(token;
    intents = Intent.default,          # which event groups Discord sends you
    shards = :auto,                    # or an integer
    cache = CacheConfig(),             # entity cache sizes
    presence = nothing)                # initial status/activity
```

The client owns a REST handle (`client.api`), one gateway connection per shard,
the entity cache, and your handlers. `start!(client)` connects; `stop!(client)`
shuts everything down cleanly.

## Intents

Discord only sends the event groups you ask for. `Intent.default` is every
non-privileged intent; the three privileged ones (`guild_members`,
`guild_presences`, `message_content`) must also be enabled in the developer
portal:

```julia
intents = Intent.default | Intent.message_content
intents = Intent.guilds | Intent.guild_messages          # or start minimal
```

## Handlers

Register with `on!` and a do-block; every handler gets the client and the
typed event. Handlers run on their own tasks, so a slow one never blocks the
gateway, and a throwing one is logged rather than fatal.

```julia
on!(client, GuildMemberAdd) do c, ev
    ch = get(c.cache.guilds, ev.guild_id, nothing)
    @info "$(display_name(ev.member.user)) joined $(ch === nothing ? ev.guild_id : ch.name)"
end
```

`on!` returns the handler, which `off!(client, GuildMemberAdd, handler)`
removes again.

Events that carry a whole entity wrap it under a named field — `ev.message`
for `MessageCreate`, `ev.guild` for `GuildCreate`, `ev.channel` for
`ChannelCreate` — plus whatever extra fields the gateway adds (like
`ev.guild_id` on `MessageCreate`). Payload-shaped events like `TypingStart`
mirror the payload directly.

Anything Discord ships that Nobelium doesn't know yet arrives as an
`UnknownEvent` with the raw payload, so new features never crash your bot.

## Waiting for one event

`wait_for` turns event handling inside out — handy for conversational flows:

```julia
respond(c, interaction; content="Are you sure? React 👍 within 30 seconds.")

ev = wait_for(client, MessageReactionAdd; timeout=30) do c, ev
    ev.user_id == interaction.user.id && ev.emoji.name == "👍"
end

ev === nothing && return followup(c, interaction; content="Timed out.")
```

## Reconnection

Shards heartbeat continuously, resume sessions after network blips, and
re-identify with exponential backoff when a resume isn't possible. Fatal
closes — a bad token, intents you haven't been granted — throw a
`GatewayClosedError` from `start!` instead of retrying forever.
