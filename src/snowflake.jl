# Discord IDs ("snowflakes") are 64-bit unsigned integers that encode their own
# creation time. On the wire they travel as strings, because they don't fit in
# the 53-bit mantissa of a JSON number.

const DISCORD_EPOCH_MS = 1_420_070_400_000  # 2015-01-01T00:00:00 UTC

"""
    Snowflake(id)

A Discord ID. Construct from an integer or a decimal string; most Nobelium
functions also accept raw integers and strings anywhere an ID is expected.

```julia
julia> timestamp(Snowflake(175928847299117063))
2016-04-30T11:18:25.796
```
"""
struct Snowflake
    value::UInt64
end

Snowflake(id::Snowflake) = id
Snowflake(id::Integer) = Snowflake(UInt64(id))
Snowflake(id::AbstractString) = Snowflake(parse(UInt64, id))

"""
    Snowflake(t::DateTime)

A synthetic snowflake for time `t` (UTC), useful as a `before`/`after` cursor
when paginating by time.
"""
Snowflake(t::DateTime) = Snowflake(UInt64(Dates.value(t - unix2datetime(0)) - DISCORD_EPOCH_MS) << 22)

"""
    snowflake(x) -> Snowflake

Normalize `x` — a `Snowflake`, integer, or decimal string — to a `Snowflake`.
"""
snowflake(x) = Snowflake(x)

const SnowflakeLike = Union{Snowflake,Integer,AbstractString}

"""
    timestamp(id::Snowflake) -> DateTime

The UTC creation time encoded in `id`.
"""
timestamp(id::Snowflake) = unix2datetime((Int64(id.value >> 22) + DISCORD_EPOCH_MS) / 1000)

Base.convert(::Type{Snowflake}, x::SnowflakeLike) = Snowflake(x)
Base.UInt64(id::Snowflake) = id.value
Base.string(id::Snowflake) = string(id.value)
Base.print(io::IO, id::Snowflake) = print(io, id.value)
Base.show(io::IO, id::Snowflake) = print(io, "Snowflake(", id.value, ")")

Base.isless(a::Snowflake, b::Snowflake) = isless(a.value, b.value)
Base.hash(id::Snowflake, h::UInt) = hash(id.value, h)
Base.:(==)(id::Snowflake, x::Integer) = id.value == x
Base.:(==)(x::Integer, id::Snowflake) = id.value == x

StructTypes.StructType(::Type{Snowflake}) = StructTypes.StringType()
StructTypes.construct(::Type{Snowflake}, s::AbstractString; kw...) = Snowflake(s)
# Discord documents snowflakes as strings, but a few gateway payloads carry them
# as bare numbers; accept both.
StructTypes.construct(::Type{Snowflake}, n::Integer; kw...) = Snowflake(n)
