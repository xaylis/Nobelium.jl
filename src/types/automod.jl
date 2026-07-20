# https://docs.discord.com/developers/resources/auto-moderation

export AutoModerationRule, AutoModerationTriggerMetadata, AutoModerationAction,
    AutoModerationActionMetadata, AutoModerationTriggerType, AutoModerationTriggerTypes,
    AutoModerationKeywordPresetType, AutoModerationKeywordPresetTypes,
    AutoModerationEventType, AutoModerationEventTypes,
    AutoModerationActionType, AutoModerationActionTypes

@discord_enum AutoModerationTriggerType UInt8 begin
    KEYWORD = 1
    SPAM = 3
    KEYWORD_PRESET = 4
    MENTION_SPAM = 5
    MEMBER_PROFILE = 6
end

@discord_enum AutoModerationKeywordPresetType UInt8 begin
    PROFANITY = 1
    SEXUAL_CONTENT = 2
    SLURS = 3
end

@discord_enum AutoModerationEventType UInt8 begin
    MESSAGE_SEND = 1
    MEMBER_UPDATE = 2
end

@discord_enum AutoModerationActionType UInt8 begin
    BLOCK_MESSAGE = 1
    SEND_ALERT_MESSAGE = 2
    TIMEOUT = 3
    BLOCK_MEMBER_INTERACTION = 4
end

"""
    AutoModerationTriggerMetadata

Trigger-specific rule configuration; which fields are relevant depends on the rule's
trigger type.
"""
@discord_object struct AutoModerationTriggerMetadata
    keyword_filter::Optional{Vector{String}}
    regex_patterns::Optional{Vector{String}}
    presets::Optional{Vector{AutoModerationKeywordPresetType}}
    allow_list::Optional{Vector{String}}
    mention_total_limit::Optional{Int}
    mention_raid_protection_enabled::Optional{Bool}
end

"""
    AutoModerationActionMetadata

Action-specific configuration; which fields are relevant depends on the action's type.
"""
@discord_object struct AutoModerationActionMetadata
    channel_id::Optional{Snowflake}
    duration_seconds::Optional{Int}
    custom_message::Optional{String}
end

@discord_object struct AutoModerationAction
    type::AutoModerationActionType
    metadata::Optional{AutoModerationActionMetadata}
end

"""
    AutoModerationRule

A rule that automatically takes actions when its trigger matches user content.
"""
@discord_object struct AutoModerationRule
    id::Snowflake
    guild_id::Snowflake
    name::String
    creator_id::Snowflake
    event_type::AutoModerationEventType
    trigger_type::AutoModerationTriggerType
    trigger_metadata::AutoModerationTriggerMetadata
    actions::Vector{AutoModerationAction}
    enabled::Bool
    exempt_roles::Vector{Snowflake}
    exempt_channels::Vector{Snowflake}
end
