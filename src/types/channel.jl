# https://docs.discord.com/developers/resources/channel

export DiscordChannel, PermissionOverwrite, ThreadMetadata, ThreadMember, ForumTag,
    DefaultReaction, FollowedChannel, ChannelType, ChannelTypes, ChannelFlags, ChannelFlag,
    VideoQualityMode, VideoQualityModes, SortOrderType, SortOrderTypes,
    ForumLayoutType, ForumLayoutTypes

@discord_enum ChannelType UInt8 begin
    GUILD_TEXT = 0
    DM = 1
    GUILD_VOICE = 2
    GROUP_DM = 3
    GUILD_CATEGORY = 4
    GUILD_ANNOUNCEMENT = 5
    ANNOUNCEMENT_THREAD = 10
    PUBLIC_THREAD = 11
    PRIVATE_THREAD = 12
    GUILD_STAGE_VOICE = 13
    GUILD_DIRECTORY = 14
    GUILD_FORUM = 15
    GUILD_MEDIA = 16
end

@discord_enum VideoQualityMode UInt8 begin
    AUTO = 1
    FULL = 2
end

@discord_enum SortOrderType UInt8 begin
    LATEST_ACTIVITY = 0
    CREATION_DATE = 1
end

@discord_enum ForumLayoutType UInt8 begin
    NOT_SET = 0
    LIST_VIEW = 1
    GALLERY_VIEW = 2
end

@discord_flags ChannelFlags UInt32 :number begin
    pinned = 1 << 1
    require_tag = 1 << 4
    hide_media_download_options = 1 << 15
    is_spoiler_channel = 1 << 21
end

"""
    PermissionOverwrite

A per-channel permission overwrite; `type` is 0 for a role, 1 for a member.
"""
@discord_object struct PermissionOverwrite
    id::Snowflake
    type::Int
    allow::Permissions
    deny::Permissions
end

@discord_object struct ThreadMetadata
    archived::Bool
    auto_archive_duration::Int
    archive_timestamp::DateTime
    locked::Bool
    invitable::Optional{Bool}
    create_timestamp::OptionalNullable{DateTime}
end

"""
    ThreadMember

A user's membership in a thread. `id` (the thread) and `user_id` are omitted on
members inside `GUILD_CREATE` threads; `member` is only sent when requested
with `with_member`.
"""
@discord_object struct ThreadMember
    id::Optional{Snowflake}
    user_id::Optional{Snowflake}
    join_timestamp::DateTime
    flags::Int
    member::Optional{GuildMember}
end

"""
    ForumTag

A tag applicable to threads in a forum or media channel. At most one of
`emoji_id` and `emoji_name` is set.
"""
@discord_object struct ForumTag
    id::Snowflake
    name::String
    moderated::Bool
    emoji_id::Nullable{Snowflake}
    emoji_name::Nullable{String}
end

@discord_object struct DefaultReaction
    emoji_id::Nullable{Snowflake}
    emoji_name::Nullable{String}
end

@discord_object struct FollowedChannel
    channel_id::Snowflake
    webhook_id::Snowflake
end

"""
    DiscordChannel

A guild channel, DM, group DM, or thread. Which fields are set depends on
`type` — threads carry `thread_metadata`, forum and media channels the
`default_*` fields, and so on.
"""
@discord_object struct DiscordChannel
    id::Snowflake
    type::ChannelType
    guild_id::Optional{Snowflake}
    position::Optional{Int}
    permission_overwrites::Optional{Vector{PermissionOverwrite}}
    name::OptionalNullable{String}
    topic::OptionalNullable{String}
    nsfw::Optional{Bool}
    last_message_id::OptionalNullable{Snowflake}
    bitrate::Optional{Int}
    user_limit::Optional{Int}
    rate_limit_per_user::Optional{Int}
    recipients::Optional{Vector{User}}
    icon::OptionalNullable{String}
    owner_id::Optional{Snowflake}
    application_id::Optional{Snowflake}
    managed::Optional{Bool}
    parent_id::OptionalNullable{Snowflake}
    last_pin_timestamp::OptionalNullable{DateTime}
    rtc_region::OptionalNullable{String}
    video_quality_mode::Optional{VideoQualityMode}
    message_count::Optional{Int}
    member_count::Optional{Int}
    thread_metadata::Optional{ThreadMetadata}
    member::Optional{ThreadMember}
    default_auto_archive_duration::Optional{Int}
    permissions::Optional{Permissions}
    app_permissions::Optional{Permissions}
    flags::Optional{ChannelFlags}
    total_message_sent::Optional{Int}
    available_tags::Optional{Vector{ForumTag}}
    applied_tags::Optional{Vector{Snowflake}}
    default_reaction_emoji::OptionalNullable{DefaultReaction}
    default_thread_rate_limit_per_user::Optional{Int}
    default_sort_order::OptionalNullable{SortOrderType}
    default_forum_layout::Optional{ForumLayoutType}
end

"""
    mention(c::DiscordChannel) -> String

The mention string for `c`, e.g. `"<#103735883630395392>"`.
"""
mention(c::DiscordChannel) = mention_channel(c.id)
