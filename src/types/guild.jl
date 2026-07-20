# https://docs.discord.com/developers/resources/guild

export Guild, GuildPreview, GuildWidget, GuildWidgetSettings, Ban,
    WelcomeScreen, WelcomeScreenChannel, Integration, IntegrationAccount,
    IntegrationApplication, IncidentsData, VerificationLevel, VerificationLevels,
    DefaultMessageNotificationLevel, DefaultMessageNotificationLevels,
    ExplicitContentFilterLevel, ExplicitContentFilterLevels, MFALevel, MFALevels,
    NSFWLevel, NSFWLevels, PremiumTier, PremiumTiers, SystemChannelFlags,
    SystemChannelFlag,  IntegrationExpireBehavior,
    IntegrationExpireBehaviors

@discord_enum VerificationLevel UInt8 begin
    NONE = 0
    LOW = 1
    MEDIUM = 2
    HIGH = 3
    VERY_HIGH = 4
end

@discord_enum DefaultMessageNotificationLevel UInt8 begin
    ALL_MESSAGES = 0
    ONLY_MENTIONS = 1
end

@discord_enum ExplicitContentFilterLevel UInt8 begin
    DISABLED = 0
    MEMBERS_WITHOUT_ROLES = 1
    ALL_MEMBERS = 2
end

@discord_enum MFALevel UInt8 begin
    NONE = 0
    ELEVATED = 1
end

@discord_enum NSFWLevel UInt8 begin
    DEFAULT = 0
    EXPLICIT = 1
    SAFE = 2
    AGE_RESTRICTED = 3
end

@discord_enum PremiumTier UInt8 begin
    NONE = 0
    TIER_1 = 1
    TIER_2 = 2
    TIER_3 = 3
end

@discord_enum IntegrationExpireBehavior UInt8 begin
    REMOVE_ROLE = 0
    KICK = 1
end

@discord_flags SystemChannelFlags UInt64 :number begin
    suppress_join_notifications = 1 << 0
    suppress_premium_subscriptions = 1 << 1
    suppress_guild_reminder_notifications = 1 << 2
    suppress_join_notification_replies = 1 << 3
    suppress_role_subscription_purchase_notifications = 1 << 4
    suppress_role_subscription_purchase_notification_replies = 1 << 5
end


@discord_object struct WelcomeScreenChannel
    channel_id::Snowflake
    description::String
    emoji_id::Nullable{Snowflake}
    emoji_name::Nullable{String}
end

"""
    WelcomeScreen

The welcome screen of a Community guild, shown to new members.
"""
@discord_object struct WelcomeScreen
    description::Nullable{String}
    welcome_channels::Vector{WelcomeScreenChannel}
end

"""
    IncidentsData

Timestamps of a guild's security incident actions and detections.
"""
@discord_object struct IncidentsData
    invites_disabled_until::Nullable{DateTime}
    dms_disabled_until::Nullable{DateTime}
    dm_spam_detected_at::OptionalNullable{DateTime}
    raid_detected_at::OptionalNullable{DateTime}
end

"""
    Guild

A Discord server. `owner` and `permissions` only appear on partial guilds from
`get_current_user_guilds`; the approximate counts require `with_counts=true`.
"""
@discord_object struct Guild
    id::Snowflake
    # required by the docs, but interactions carry partial guilds without it
    name::Optional{String}
    icon::OptionalNullable{String}
    icon_hash::OptionalNullable{String}
    splash::OptionalNullable{String}
    discovery_splash::OptionalNullable{String}
    owner::Optional{Bool}
    owner_id::Optional{Snowflake}
    permissions::Optional{Permissions}
    region::OptionalNullable{String}
    afk_channel_id::OptionalNullable{Snowflake}
    afk_timeout::Optional{Int}
    widget_enabled::Optional{Bool}
    widget_channel_id::OptionalNullable{Snowflake}
    verification_level::Optional{VerificationLevel}
    default_message_notifications::Optional{DefaultMessageNotificationLevel}
    explicit_content_filter::Optional{ExplicitContentFilterLevel}
    roles::Optional{Vector{Role}}
    emojis::Optional{Vector{Emoji}}
    features::Optional{Vector{String}}
    mfa_level::Optional{MFALevel}
    application_id::OptionalNullable{Snowflake}
    system_channel_id::OptionalNullable{Snowflake}
    system_channel_flags::Optional{SystemChannelFlags}
    rules_channel_id::OptionalNullable{Snowflake}
    max_presences::OptionalNullable{Int}
    max_members::Optional{Int}
    vanity_url_code::OptionalNullable{String}
    description::OptionalNullable{String}
    banner::OptionalNullable{String}
    premium_tier::Optional{PremiumTier}
    premium_subscription_count::Optional{Int}
    preferred_locale::Optional{String}
    public_updates_channel_id::OptionalNullable{Snowflake}
    max_video_channel_users::Optional{Int}
    max_stage_video_channel_users::Optional{Int}
    approximate_member_count::Optional{Int}
    approximate_presence_count::Optional{Int}
    welcome_screen::Optional{WelcomeScreen}
    nsfw_level::Optional{NSFWLevel}
    stickers::Optional{Vector{Sticker}}
    premium_progress_bar_enabled::Optional{Bool}
    safety_alerts_channel_id::OptionalNullable{Snowflake}
    incidents_data::OptionalNullable{IncidentsData}
end

"""
    GuildPreview

A publicly previewable summary of a guild, from `get_guild_preview`.
"""
@discord_object struct GuildPreview
    id::Snowflake
    name::String
    icon::Nullable{String}
    splash::Nullable{String}
    discovery_splash::Nullable{String}
    emojis::Vector{Emoji}
    features::Vector{String}
    approximate_member_count::Int
    approximate_presence_count::Int
    description::Nullable{String}
    stickers::Vector{Sticker}
end

@discord_object struct GuildWidgetSettings
    enabled::Bool
    channel_id::Nullable{Snowflake}
end

"""
    GuildWidget

The public widget of a guild. Member fields are anonymized.
"""
@discord_object struct GuildWidget
    id::Snowflake
    name::String
    instant_invite::Nullable{String}
    channels::Vector{DiscordChannel}
    members::Vector{User}
    presence_count::Int
end


@discord_object struct Ban
    reason::Nullable{String}
    user::User
end

@discord_object struct IntegrationAccount
    id::String
    name::String
end

@discord_object struct IntegrationApplication
    id::Snowflake
    name::String
    icon::Nullable{String}
    description::String
    bot::Optional{User}
end

"""
    Integration

A guild integration (`twitch`, `youtube`, `discord`, or `guild_subscription`).
"""
@discord_object struct Integration
    id::Snowflake
    name::String
    type::String
    enabled::Bool
    syncing::Optional{Bool}
    role_id::Optional{Snowflake}
    enable_emoticons::Optional{Bool}
    expire_behavior::Optional{IntegrationExpireBehavior}
    expire_grace_period::Optional{Int}
    user::Optional{User}
    account::IntegrationAccount
    synced_at::Optional{DateTime}
    subscriber_count::Optional{Int}
    revoked::Optional{Bool}
    application::Optional{IntegrationApplication}
    scopes::Optional{Vector{String}}
end
