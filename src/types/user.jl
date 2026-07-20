# https://docs.discord.com/developers/resources/user

export User, AvatarDecorationData, Connection, ApplicationRoleConnection,
    UserFlags, UserFlag, PremiumType, PremiumTypes, ConnectionVisibilityType,
    ConnectionVisibilityTypes, mention, display_name

@discord_flags UserFlags UInt64 :number begin
    staff = 1 << 0
    partner = 1 << 1
    hypesquad = 1 << 2
    bug_hunter_level_1 = 1 << 3
    hypesquad_bravery = 1 << 6
    hypesquad_brilliance = 1 << 7
    hypesquad_balance = 1 << 8
    premium_early_supporter = 1 << 9
    team_pseudo_user = 1 << 10
    bug_hunter_level_2 = 1 << 14
    verified_bot = 1 << 16
    verified_developer = 1 << 17
    certified_moderator = 1 << 18
    bot_http_interactions = 1 << 19
    active_developer = 1 << 22
end

@discord_enum PremiumType UInt8 begin
    NONE = 0
    NITRO_CLASSIC = 1
    NITRO = 2
    NITRO_BASIC = 3
end

@discord_enum ConnectionVisibilityType UInt8 begin
    INVISIBLE = 0
    EVERYONE = 1
end

@discord_object struct AvatarDecorationData
    asset::String
    sku_id::Snowflake
end

"""
    User

A Discord user account. Bots see most fields only on themselves or via OAuth2;
`email` and `verified` require the `email` scope.
"""
@discord_object struct User
    id::Snowflake
    username::String
    discriminator::String
    # nullable per the docs, but also absent in webhook-author partials
    global_name::OptionalNullable{String}
    avatar::OptionalNullable{String}
    bot::Optional{Bool}
    system::Optional{Bool}
    mfa_enabled::Optional{Bool}
    banner::OptionalNullable{String}
    accent_color::OptionalNullable{Int}
    locale::Optional{String}
    verified::Optional{Bool}
    email::OptionalNullable{String}
    flags::Optional{UserFlags}
    premium_type::Optional{PremiumType}
    public_flags::Optional{UserFlags}
    avatar_decoration_data::OptionalNullable{AvatarDecorationData}
end

"""
    Connection

A linked third-party account (Steam, Twitch, ...) on a user's profile.
"""
@discord_object struct Connection
    id::String
    name::String
    type::String
    revoked::Optional{Bool}
    integrations::Optional{Vector{Any}}
    verified::Bool
    friend_sync::Bool
    show_activity::Bool
    two_way_link::Bool
    visibility::ConnectionVisibilityType
end

"""
    ApplicationRoleConnection

The role-connection metadata a user has attached for an application.
"""
@discord_object struct ApplicationRoleConnection
    platform_name::Nullable{String}
    platform_username::Nullable{String}
    metadata::Dict{String,String}
end

"""
    mention(u::User) -> String

The mention string for `u`, e.g. `"<@80351110224678912>"`.
"""
mention(u::User) = mention_user(u.id)

"""
    display_name(u::User) -> String

The name clients show for `u`: the global display name when set, otherwise the
username.
"""
function display_name(u::User)
    name = u.global_name
    name === nothing || name === missing ? u.username : name
end
