# https://docs.discord.com/developers/resources/audit-log

export AuditLog, AuditLogEntry, AuditLogChange, AuditLogEntryInfo,
    AuditLogEvent, AuditLogEvents

@discord_enum AuditLogEvent UInt8 begin
    GUILD_UPDATE = 1
    CHANNEL_CREATE = 10
    CHANNEL_UPDATE = 11
    CHANNEL_DELETE = 12
    CHANNEL_OVERWRITE_CREATE = 13
    CHANNEL_OVERWRITE_UPDATE = 14
    CHANNEL_OVERWRITE_DELETE = 15
    MEMBER_KICK = 20
    MEMBER_PRUNE = 21
    MEMBER_BAN_ADD = 22
    MEMBER_BAN_REMOVE = 23
    MEMBER_UPDATE = 24
    MEMBER_ROLE_UPDATE = 25
    MEMBER_MOVE = 26
    MEMBER_DISCONNECT = 27
    BOT_ADD = 28
    ROLE_CREATE = 30
    ROLE_UPDATE = 31
    ROLE_DELETE = 32
    INVITE_CREATE = 40
    INVITE_UPDATE = 41
    INVITE_DELETE = 42
    WEBHOOK_CREATE = 50
    WEBHOOK_UPDATE = 51
    WEBHOOK_DELETE = 52
    EMOJI_CREATE = 60
    EMOJI_UPDATE = 61
    EMOJI_DELETE = 62
    MESSAGE_DELETE = 72
    MESSAGE_BULK_DELETE = 73
    MESSAGE_PIN = 74
    MESSAGE_UNPIN = 75
    INTEGRATION_CREATE = 80
    INTEGRATION_UPDATE = 81
    INTEGRATION_DELETE = 82
    STAGE_INSTANCE_CREATE = 83
    STAGE_INSTANCE_UPDATE = 84
    STAGE_INSTANCE_DELETE = 85
    STICKER_CREATE = 90
    STICKER_UPDATE = 91
    STICKER_DELETE = 92
    GUILD_SCHEDULED_EVENT_CREATE = 100
    GUILD_SCHEDULED_EVENT_UPDATE = 101
    GUILD_SCHEDULED_EVENT_DELETE = 102
    THREAD_CREATE = 110
    THREAD_UPDATE = 111
    THREAD_DELETE = 112
    APPLICATION_COMMAND_PERMISSION_UPDATE = 121
    SOUNDBOARD_SOUND_CREATE = 130
    SOUNDBOARD_SOUND_UPDATE = 131
    SOUNDBOARD_SOUND_DELETE = 132
    AUTO_MODERATION_RULE_CREATE = 140
    AUTO_MODERATION_RULE_UPDATE = 141
    AUTO_MODERATION_RULE_DELETE = 142
    AUTO_MODERATION_BLOCK_MESSAGE = 143
    AUTO_MODERATION_FLAG_TO_CHANNEL = 144
    AUTO_MODERATION_USER_COMMUNICATION_DISABLED = 145
    AUTO_MODERATION_QUARANTINE_USER = 146
    CREATOR_MONETIZATION_REQUEST_CREATED = 150
    CREATOR_MONETIZATION_TERMS_ACCEPTED = 151
    ONBOARDING_PROMPT_CREATE = 163
    ONBOARDING_PROMPT_UPDATE = 164
    ONBOARDING_PROMPT_DELETE = 165
    ONBOARDING_CREATE = 166
    ONBOARDING_UPDATE = 167
    HOME_SETTINGS_CREATE = 190
    HOME_SETTINGS_UPDATE = 191
    VOICE_CHANNEL_STATUS_CREATE = 192
    VOICE_CHANNEL_STATUS_DELETE = 193
end

"""
    AuditLogChange

One changed field on the entry's target. `new_value`/`old_value` mirror the type of the
field named by `key`, so they are left untyped.
"""
@discord_object struct AuditLogChange
    new_value::Optional{Any}
    old_value::Optional{Any}
    key::String
end

"""
    AuditLogEntryInfo

Extra context for some audit log entries; which fields are set depends on `action_type`.
"""
@discord_object struct AuditLogEntryInfo
    application_id::Optional{Snowflake}
    auto_moderation_rule_name::Optional{String}
    auto_moderation_rule_trigger_type::Optional{String}
    channel_id::Optional{Snowflake}
    count::Optional{String}
    delete_member_days::Optional{String}
    id::Optional{Snowflake}
    integration_type::Optional{String}
    members_removed::Optional{String}
    message_id::Optional{Snowflake}
    role_name::Optional{String}
    status::Optional{String}
    type::Optional{String}
end

@discord_object struct AuditLogEntry
    target_id::Nullable{String}
    changes::Optional{Vector{AuditLogChange}}
    user_id::Nullable{Snowflake}
    id::Snowflake
    action_type::AuditLogEvent
    options::Optional{AuditLogEntryInfo}
    reason::Optional{String}
end

"""
    AuditLog

A page of a guild's audit log, with the entries plus the objects they reference.
"""
@discord_object struct AuditLog
    application_commands::Vector{ApplicationCommand}
    audit_log_entries::Vector{AuditLogEntry}
    auto_moderation_rules::Vector{AutoModerationRule}
    guild_scheduled_events::Vector{GuildScheduledEvent}
    integrations::Vector{Integration}
    threads::Vector{DiscordChannel}
    users::Vector{User}
    webhooks::Vector{Webhook}
end
