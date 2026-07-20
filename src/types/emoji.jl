# https://docs.discord.com/developers/resources/emoji

export Emoji

"""
    Emoji

A custom guild or application emoji. In reaction payloads for standard unicode
emoji, `id` is null and `name` holds the unicode character.
"""
@discord_object struct Emoji
    id::Nullable{Snowflake}
    name::Nullable{String}
    roles::Optional{Vector{Snowflake}}
    user::Optional{User}
    require_colons::Optional{Bool}
    managed::Optional{Bool}
    animated::Optional{Bool}
    available::Optional{Bool}
end
