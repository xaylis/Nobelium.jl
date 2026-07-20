# https://docs.discord.com/developers/resources/soundboard

export SoundboardSound

"""
    SoundboardSound

A custom sound that can be played in a guild's voice channels via the
soundboard. `sound_id` doubles as the sound's own id.
"""
@discord_object struct SoundboardSound
    name::String
    sound_id::Snowflake
    volume::Float64
    emoji_id::Nullable{Snowflake}
    emoji_name::Nullable{String}
    guild_id::Optional{Snowflake}
    available::Bool
    user::Optional{User}
end
