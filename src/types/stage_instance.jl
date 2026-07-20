# https://docs.discord.com/developers/resources/stage-instance

export StageInstance, StageInstancePrivacyLevel, StageInstancePrivacyLevels

@discord_enum StageInstancePrivacyLevel UInt8 begin
    PUBLIC = 1
    GUILD_ONLY = 2
end

"""
    StageInstance

A live Stage: the topic and settings of an ongoing event in a Stage channel.
"""
@discord_object struct StageInstance
    id::Snowflake
    guild_id::Snowflake
    channel_id::Snowflake
    topic::String
    privacy_level::StageInstancePrivacyLevel
    discoverable_disabled::Bool
    guild_scheduled_event_id::Nullable{Snowflake}
end
