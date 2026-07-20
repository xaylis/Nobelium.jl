# https://docs.discord.com/developers/resources/soundboard

export send_soundboard_sound, list_default_soundboard_sounds, list_guild_soundboard_sounds,
    get_guild_soundboard_sound, create_guild_soundboard_sound, modify_guild_soundboard_sound,
    delete_guild_soundboard_sound

"""
    send_soundboard_sound(api, channel_id; sound_id, source_guild_id)

`source_guild_id` is required when playing a sound from a different guild's
soundboard. Requires `SPEAK` and `USE_SOUNDBOARD`, and `USE_EXTERNAL_SOUNDS`
for sounds from another guild.
[Docs](https://docs.discord.com/developers/resources/soundboard#send-soundboard-sound)
"""
function send_soundboard_sound(api::API, channel::SnowflakeLike;
                               sound_id::SnowflakeLike, source_guild_id=missing)
    body = (; sound_id=snowflake(sound_id),
            source_guild_id=source_guild_id === missing ? missing : snowflake(source_guild_id))
    request(api, Route(:POST, "/channels/{channel_id}/send-soundboard-sound"),
            snowflake(channel); body)
end

"""
    list_default_soundboard_sounds(api) -> Vector{SoundboardSound}

[Docs](https://docs.discord.com/developers/resources/soundboard#list-default-soundboard-sounds)
"""
list_default_soundboard_sounds(api::API) =
    request(api, Route(:GET, "/soundboard-default-sounds"); into=Vector{SoundboardSound})

"""
    list_guild_soundboard_sounds(api, guild_id) -> Vector{SoundboardSound}

[Docs](https://docs.discord.com/developers/resources/soundboard#list-guild-soundboard-sounds)
"""
function list_guild_soundboard_sounds(api::API, guild::SnowflakeLike)
    result = request(api, Route(:GET, "/guilds/{guild_id}/soundboard-sounds"),
                     snowflake(guild); into=Any)
    SoundboardSound[_reconstruct(SoundboardSound, s) for s in result.items]
end

"""
    get_guild_soundboard_sound(api, guild_id, sound_id) -> SoundboardSound

[Docs](https://docs.discord.com/developers/resources/soundboard#get-guild-soundboard-sound)
"""
get_guild_soundboard_sound(api::API, guild::SnowflakeLike, sound::SnowflakeLike) =
    request(api, Route(:GET, "/guilds/{guild_id}/soundboard-sounds/{sound_id}"),
            snowflake(guild), snowflake(sound); into=SoundboardSound)

"""
    create_guild_soundboard_sound(api, guild_id; name, sound, volume, emoji_id, emoji_name,
                                  reason) -> SoundboardSound

`sound` is a data URI of a base64-encoded MP3 or Ogg file.
[Docs](https://docs.discord.com/developers/resources/soundboard#create-guild-soundboard-sound)
"""
function create_guild_soundboard_sound(api::API, guild::SnowflakeLike; reason=nothing, kwargs...)
    request(api, Route(:POST, "/guilds/{guild_id}/soundboard-sounds"), snowflake(guild);
            body=kwargs, into=SoundboardSound, reason)
end

"""
    modify_guild_soundboard_sound(api, guild_id, sound_id; name, volume, emoji_id, emoji_name,
                                  reason) -> SoundboardSound

[Docs](https://docs.discord.com/developers/resources/soundboard#modify-guild-soundboard-sound)
"""
function modify_guild_soundboard_sound(api::API, guild::SnowflakeLike, sound::SnowflakeLike;
                                       reason=nothing, kwargs...)
    request(api, Route(:PATCH, "/guilds/{guild_id}/soundboard-sounds/{sound_id}"),
            snowflake(guild), snowflake(sound); body=kwargs, into=SoundboardSound, reason)
end

"""
    delete_guild_soundboard_sound(api, guild_id, sound_id; reason)

[Docs](https://docs.discord.com/developers/resources/soundboard#delete-guild-soundboard-sound)
"""
function delete_guild_soundboard_sound(api::API, guild::SnowflakeLike, sound::SnowflakeLike;
                                       reason=nothing)
    request(api, Route(:DELETE, "/guilds/{guild_id}/soundboard-sounds/{sound_id}"),
            snowflake(guild), snowflake(sound); reason)
end
