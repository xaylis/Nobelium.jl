# The REST API

Every documented Discord endpoint is a plain function named after the docs'
own verb — `create_message`, `modify_guild`, `list_guild_members`,
`get_channel`. The first argument is an [`API`](../reference/client.md) handle:
either a standalone one or the client's.

```julia
api = API(ENV["DISCORD_TOKEN"])        # REST without a gateway connection
api = client.api                       # or from a running client

me      = get_current_user(api)
channel = get_channel(api, 1392713127724060802)
msg     = create_message(api, channel.id; content="hello from Julia")
edit_message(api, channel.id, msg.id; content="hello *again*")
```

## Conventions

- **IDs** — anywhere an ID is expected you can pass a `Snowflake`, an integer,
  or a decimal string.
- **JSON body fields** are keyword arguments. Leave a keyword out to not send
  it; pass `nothing` to send an explicit `null` (Discord's "clear this field"):

  ```julia
  modify_channel(api, ch; topic="new topic")     # set
  modify_channel(api, ch; topic=nothing)         # clear
  ```

- **Query parameters** are also keywords on the functions that take them:
  `list_guild_members(api, guild; limit=1000, after=last_id)`.
- **Audit log reasons** — moderation endpoints accept `reason`, which shows up
  in the guild's audit log: `delete_message(api, ch, msg; reason="spam")`.
- **Files** — endpoints that accept uploads take
  `files=[DiscordFile("plot.png", png_bytes)]`.
- **Returns** are typed: `Message`, `Guild`, `Vector{GuildMember}`, ... and
  `nothing` for 204 responses.

## Rate limits

You don't manage them. Requests flow through a limiter that learns Discord's
per-route buckets from response headers, respects the global limit, and sleeps
through 429s. Server errors retry with backoff. If Discord keeps rate limiting
after several rounds you get a `RateLimitedError`; hard failures surface as
[`APIError`](errors.md).

## Calling something we missed

All endpoints funnel through one pipeline, which is public enough for
emergencies:

```julia
Nobelium.request(api, Nobelium.Route(:GET, "/some/{thing}"), id; into=Any)
```
