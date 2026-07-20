# https://docs.discord.com/developers/topics/permissions#role-object

export Role, RoleTags, RoleColors, RoleFlags, RoleFlag

@discord_flags RoleFlags UInt64 :number begin
    in_prompt = 1 << 0
end

@discord_object struct RoleColors
    primary_color::Int
    secondary_color::Nullable{Int}
    tertiary_color::Nullable{Int}
end

"""
    RoleTags

Metadata on managed roles. The `null`-typed fields (`premium_subscriber`,
`available_for_purchase`, `guild_connections`) act as booleans: `nothing` when
the tag applies, `missing` when it doesn't.
"""
@discord_object struct RoleTags
    bot_id::Optional{Snowflake}
    integration_id::Optional{Snowflake}
    premium_subscriber::Optional{Nothing}
    subscription_listing_id::Optional{Snowflake}
    available_for_purchase::Optional{Nothing}
    guild_connections::Optional{Nothing}
end

"""
    Role

A guild role. `color` is deprecated in favor of `colors`.
"""
@discord_object struct Role
    id::Snowflake
    name::String
    color::Int
    colors::RoleColors
    hoist::Bool
    icon::OptionalNullable{String}
    unicode_emoji::OptionalNullable{String}
    position::Int
    permissions::Permissions
    managed::Bool
    mentionable::Bool
    tags::Optional{RoleTags}
    flags::RoleFlags
end

"""
    mention(r::Role) -> String

The mention string for `r`, e.g. `"<@&41771983423143936>"`.
"""
mention(r::Role) = mention_role(r.id)
