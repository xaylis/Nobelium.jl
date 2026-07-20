# https://docs.discord.com/developers/resources/voice

export list_voice_regions, get_current_user_voice_state, get_user_voice_state,
    modify_current_user_voice_state, modify_user_voice_state

"""
    list_voice_regions(api) -> Vector{VoiceRegion}

[Docs](https://docs.discord.com/developers/resources/voice#list-voice-regions)
"""
list_voice_regions(api::API) =
    request(api, Route(:GET, "/voice/regions"); into=Vector{VoiceRegion})

"""
    get_current_user_voice_state(api, guild_id) -> VoiceState

[Docs](https://docs.discord.com/developers/resources/voice#get-current-user-voice-state)
"""
get_current_user_voice_state(api::API, guild::SnowflakeLike) =
    request(api, Route(:GET, "/guilds/{guild_id}/voice-states/@me"), snowflake(guild);
            into=VoiceState)

"""
    get_user_voice_state(api, guild_id, user_id) -> VoiceState

[Docs](https://docs.discord.com/developers/resources/voice#get-user-voice-state)
"""
get_user_voice_state(api::API, guild::SnowflakeLike, user::SnowflakeLike) =
    request(api, Route(:GET, "/guilds/{guild_id}/voice-states/{user_id}"),
            snowflake(guild), snowflake(user); into=VoiceState)

"""
    modify_current_user_voice_state(api, guild_id; channel_id, suppress, request_to_speak_timestamp)

Update the bot's voice state in a Stage channel, e.g. to request to speak.
[Docs](https://docs.discord.com/developers/resources/voice#modify-current-user-voice-state)
"""
modify_current_user_voice_state(api::API, guild::SnowflakeLike; kwargs...) =
    request(api, Route(:PATCH, "/guilds/{guild_id}/voice-states/@me"), snowflake(guild);
            body=kwargs)

"""
    modify_user_voice_state(api, guild_id, user_id; channel_id, suppress)

[Docs](https://docs.discord.com/developers/resources/voice#modify-user-voice-state)
"""
modify_user_voice_state(api::API, guild::SnowflakeLike, user::SnowflakeLike; kwargs...) =
    request(api, Route(:PATCH, "/guilds/{guild_id}/voice-states/{user_id}"),
            snowflake(guild), snowflake(user); body=kwargs)
