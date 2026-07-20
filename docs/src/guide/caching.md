# Caching

The gateway streams entity updates continuously; the client folds them into
bounded, thread-safe stores before your handlers run:

```julia
client.cache.guilds     # Snowflake => Guild
client.cache.channels   # Snowflake => DiscordChannel
client.cache.users      # Snowflake => User
client.cache.members    # (guild_id, user_id) => GuildMember
client.cache.messages   # Snowflake => Message
```

Reads never hit the network — `get` returns your `default` when the entity
isn't cached:

```julia
guild = get(client.cache.guilds, guild_id, nothing)
guild === nothing && (guild = get_guild(client.api, guild_id))
```

That pattern is deliberate: REST functions never silently serve stale cache;
when you want fresh data, you ask Discord.

## Sizing

Each store has a capacity; when full, the least-recently-used tenth is evicted
in one sweep:

```julia
Client(token; cache=CacheConfig(messages=10_000, members=50_000))
```

Set a store's capacity around your working set. Guild, channel, user, and
member stores fill from `GUILD_CREATE` on startup; messages accumulate as they
happen.
