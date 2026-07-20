# https://docs.discord.com/developers/resources/voice

export VoiceState, VoiceRegion

"""
    VoiceState

A user's voice connection status in a guild.
"""
@discord_object struct VoiceState
    guild_id::Optional{Snowflake}
    channel_id::Nullable{Snowflake}
    user_id::Snowflake
    member::Optional{GuildMember}
    session_id::String
    deaf::Bool
    mute::Bool
    self_deaf::Bool
    self_mute::Bool
    self_stream::Optional{Bool}
    self_video::Bool
    suppress::Bool
    request_to_speak_timestamp::Nullable{DateTime}
end

@discord_object struct VoiceRegion
    id::String
    name::String
    optimal::Bool
    deprecated::Bool
    custom::Bool
end
