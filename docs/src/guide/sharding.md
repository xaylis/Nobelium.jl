# Sharding

Above ~1000 guilds (2500 at the hard limit) Discord requires splitting the
gateway connection into shards. Nobelium handles the whole dance:

```julia
client = Client(token)             # shards=:auto is the default
start!(client)
```

With `:auto`, the client asks `GET /gateway/bot` for the recommended shard
count and Discord's `max_concurrency`, then brings shards up in the mandated
identify buckets (one identify per bucket per five seconds).

Force a count if you know better:

```julia
client = Client(token; shards=4)
```

Every shard feeds the same handler registry and cache, so your code doesn't
change at all. A guild's events always arrive on the shard
`(guild_id >> 22) % shard_count` — the client uses that internally to route
`request_guild_members!` and voice-state updates to the right connection.

For very large bots that spread shards across processes, run one `Client` per
process with an explicit shard count and split the shard IDs yourself — the
building blocks (`Nobelium.Shard`) are public enough to compose.
