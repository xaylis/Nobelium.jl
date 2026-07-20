# https://docs.discord.com/developers/resources/sku
# https://docs.discord.com/developers/resources/entitlement
# https://docs.discord.com/developers/resources/subscription

export SKU, SKUType, SKUTypes, SKUFlags, SKUFlag, Entitlement, EntitlementType,
    EntitlementTypes, Subscription, SubscriptionStatus, SubscriptionStatuses

@discord_enum SKUType UInt8 begin
    DURABLE = 2
    CONSUMABLE = 3
    SUBSCRIPTION = 5
    SUBSCRIPTION_GROUP = 6
end

@discord_flags SKUFlags UInt16 :number begin
    available = 1 << 2
    guild_subscription = 1 << 7
    user_subscription = 1 << 8
end

"""
    SKU

A premium offering an application sells on Discord — a durable item, a
consumable, or a subscription.
"""
@discord_object struct SKU
    id::Snowflake
    type::SKUType
    application_id::Snowflake
    name::String
    slug::String
    flags::SKUFlags
end

@discord_enum EntitlementType UInt8 begin
    PURCHASE = 1
    PREMIUM_SUBSCRIPTION = 2
    DEVELOPER_GIFT = 3
    TEST_MODE_PURCHASE = 4
    FREE_PURCHASE = 5
    USER_GIFT = 6
    PREMIUM_PURCHASE = 7
    APPLICATION_SUBSCRIPTION = 8
end

"""
    Entitlement

A user's or guild's access to a [`SKU`](@ref). `starts_at`/`ends_at` are
absent on test entitlements and null on perpetual ones.
"""
@discord_object struct Entitlement
    id::Snowflake
    sku_id::Snowflake
    application_id::Snowflake
    user_id::Optional{Snowflake}
    type::EntitlementType
    deleted::Bool
    starts_at::OptionalNullable{DateTime}
    ends_at::OptionalNullable{DateTime}
    guild_id::Optional{Snowflake}
    consumed::Optional{Bool}
end

# `@discord_enum` pluralizes by appending 's', which here would produce
# `SubscriptionStatuss`; spelled out by hand to keep the documented name.
module SubscriptionStatuses
struct T
    value::UInt8
end
T(x::T) = x
const ACTIVE = T(0)
const INACTIVE = T(1)
const ENDING = T(2)
const NAMES = Base.Dict{UInt8,Symbol}(0 => :ACTIVE, 1 => :INACTIVE, 2 => :ENDING)
end

const SubscriptionStatus = SubscriptionStatuses.T

StructTypes.StructType(::Type{SubscriptionStatus}) = StructTypes.CustomStruct()
StructTypes.lower(x::SubscriptionStatus) = x.value
StructTypes.lowertype(::Type{SubscriptionStatus}) = UInt8
StructTypes.construct(::Type{SubscriptionStatus}, x::Number; kw...) = SubscriptionStatus(UInt8(x))
Base.:(==)(x::SubscriptionStatus, n::Integer) = x.value == n
Base.:(==)(n::Integer, x::SubscriptionStatus) = x.value == n
Base.hash(x::SubscriptionStatus, h::UInt) = hash(x.value, h)

function Base.show(io::IO, x::SubscriptionStatus)
    label = get(SubscriptionStatuses.NAMES, x.value, nothing)
    label === nothing && return print(io, "SubscriptionStatus(", x.value, ')')
    print(io, "SubscriptionStatuses.", label)
end

"""
    Subscription

A user's recurring purchase of one or more [`SKU`](@ref)s. `country` is only
present when queried with a private OAuth scope.
"""
@discord_object struct Subscription
    id::Snowflake
    user_id::Snowflake
    sku_ids::Vector{Snowflake}
    entitlement_ids::Vector{Snowflake}
    renewal_sku_ids::Nullable{Vector{Snowflake}}
    current_period_start::DateTime
    current_period_end::DateTime
    status::SubscriptionStatus
    canceled_at::Nullable{DateTime}
    country::Optional{String}
end
