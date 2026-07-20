export CacheConfig

# A bounded, thread-safe store with LRU-ish eviction: entries carry a logical
# access stamp, and when the store overflows the oldest tenth is dropped in one
# sweep — cheap enough to sit on the gateway hot path.

mutable struct Store{K,V}
    const lock::ReentrantLock
    const data::Dict{K,Tuple{V,Int}}
    const capacity::Int
    stamp::Int
end

Store{K,V}(capacity::Integer) where {K,V} =
    Store{K,V}(ReentrantLock(), Dict{K,Tuple{V,Int}}(), capacity, 0)

function Base.get(s::Store{K,V}, key, default) where {K,V}
    lock(s.lock) do
        entry = get(s.data, key, nothing)
        entry === nothing && return default
        s.data[key] = (entry[1], s.stamp += 1)
        entry[1]
    end
end

function Base.setindex!(s::Store{K,V}, value, key) where {K,V}
    s.capacity <= 0 && return value
    lock(s.lock) do
        s.data[key] = (value, s.stamp += 1)
        if length(s.data) > s.capacity
            drop = min(length(s.data) - s.capacity + max(1, s.capacity ÷ 10), length(s.data))
            for (k, _) in sort!(collect(pairs(s.data)); by = p -> p.second[2])[1:drop]
                delete!(s.data, k)
            end
        end
    end
    value
end

Base.delete!(s::Store, key) = (lock(() -> delete!(s.data, key), s.lock); s)
Base.length(s::Store) = lock(() -> length(s.data), s.lock)
Base.empty!(s::Store) = (lock(() -> empty!(s.data), s.lock); s)

"""
    CacheConfig(; guilds=1_000, channels=10_000, users=10_000, members=10_000, messages=1_000)

Capacities for the client-side cache, one bounded store per entity kind. The
gateway keeps these fresh before your handlers run; set a capacity to `0` to
effectively disable a store.
"""
struct CacheConfig
    guilds::Int
    channels::Int
    users::Int
    members::Int
    messages::Int
end

CacheConfig(; guilds=1_000, channels=10_000, users=10_000, members=10_000, messages=1_000) =
    CacheConfig(guilds, channels, users, members, messages)

struct Cache
    guilds::Store{Snowflake,Guild}
    channels::Store{Snowflake,DiscordChannel}
    users::Store{Snowflake,User}
    members::Store{Tuple{Snowflake,Snowflake},GuildMember}
    messages::Store{Snowflake,Message}
end

Cache(c::CacheConfig=CacheConfig()) = Cache(
    Store{Snowflake,Guild}(c.guilds),
    Store{Snowflake,DiscordChannel}(c.channels),
    Store{Snowflake,User}(c.users),
    Store{Tuple{Snowflake,Snowflake},GuildMember}(c.members),
    Store{Snowflake,Message}(c.messages),
)
