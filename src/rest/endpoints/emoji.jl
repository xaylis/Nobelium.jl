# https://docs.discord.com/developers/resources/emoji

export list_guild_emojis, get_guild_emoji, create_guild_emoji, modify_guild_emoji,
    delete_guild_emoji, list_application_emojis, get_application_emoji,
    create_application_emoji, modify_application_emoji, delete_application_emoji

"""
    list_guild_emojis(api, guild_id) -> Vector{Emoji}

[Docs](https://docs.discord.com/developers/resources/emoji#list-guild-emojis)
"""
list_guild_emojis(api::API, guild::SnowflakeLike) =
    request(api, Route(:GET, "/guilds/{guild_id}/emojis"), snowflake(guild);
            into=Vector{Emoji})

"""
    get_guild_emoji(api, guild_id, emoji_id) -> Emoji

[Docs](https://docs.discord.com/developers/resources/emoji#get-guild-emoji)
"""
get_guild_emoji(api::API, guild::SnowflakeLike, emoji::SnowflakeLike) =
    request(api, Route(:GET, "/guilds/{guild_id}/emojis/{emoji_id}"),
            snowflake(guild), snowflake(emoji); into=Emoji)

"""
    create_guild_emoji(api, guild_id; name, image, roles, reason) -> Emoji

`image` is an image data URI, at most 256 KiB. Requires the
`CREATE_GUILD_EXPRESSIONS` permission.
[Docs](https://docs.discord.com/developers/resources/emoji#create-guild-emoji)
"""
function create_guild_emoji(api::API, guild::SnowflakeLike; reason=nothing, kwargs...)
    request(api, Route(:POST, "/guilds/{guild_id}/emojis"), snowflake(guild);
            body=kwargs, into=Emoji, reason)
end

"""
    modify_guild_emoji(api, guild_id, emoji_id; name, roles, reason) -> Emoji

[Docs](https://docs.discord.com/developers/resources/emoji#modify-guild-emoji)
"""
function modify_guild_emoji(api::API, guild::SnowflakeLike, emoji::SnowflakeLike;
                            reason=nothing, kwargs...)
    request(api, Route(:PATCH, "/guilds/{guild_id}/emojis/{emoji_id}"),
            snowflake(guild), snowflake(emoji); body=kwargs, into=Emoji, reason)
end

"""
    delete_guild_emoji(api, guild_id, emoji_id; reason)

[Docs](https://docs.discord.com/developers/resources/emoji#delete-guild-emoji)
"""
function delete_guild_emoji(api::API, guild::SnowflakeLike, emoji::SnowflakeLike;
                            reason=nothing)
    request(api, Route(:DELETE, "/guilds/{guild_id}/emojis/{emoji_id}"),
            snowflake(guild), snowflake(emoji); reason)
end

"""
    list_application_emojis(api, application_id) -> JSON3.Object

Emojis owned by the application, wrapped as `{"items": [...]}`.
[Docs](https://docs.discord.com/developers/resources/emoji#list-application-emojis)
"""
list_application_emojis(api::API, application::SnowflakeLike) =
    request(api, Route(:GET, "/applications/{application_id}/emojis"),
            snowflake(application); into=Any)

"""
    get_application_emoji(api, application_id, emoji_id) -> Emoji

[Docs](https://docs.discord.com/developers/resources/emoji#get-application-emoji)
"""
get_application_emoji(api::API, application::SnowflakeLike, emoji::SnowflakeLike) =
    request(api, Route(:GET, "/applications/{application_id}/emojis/{emoji_id}"),
            snowflake(application), snowflake(emoji); into=Emoji)

"""
    create_application_emoji(api, application_id; name, image) -> Emoji

`image` is an image data URI, at most 256 KiB.
[Docs](https://docs.discord.com/developers/resources/emoji#create-application-emoji)
"""
create_application_emoji(api::API, application::SnowflakeLike; kwargs...) =
    request(api, Route(:POST, "/applications/{application_id}/emojis"),
            snowflake(application); body=kwargs, into=Emoji)

"""
    modify_application_emoji(api, application_id, emoji_id; name) -> Emoji

[Docs](https://docs.discord.com/developers/resources/emoji#modify-application-emoji)
"""
modify_application_emoji(api::API, application::SnowflakeLike, emoji::SnowflakeLike; kwargs...) =
    request(api, Route(:PATCH, "/applications/{application_id}/emojis/{emoji_id}"),
            snowflake(application), snowflake(emoji); body=kwargs, into=Emoji)

"""
    delete_application_emoji(api, application_id, emoji_id)

[Docs](https://docs.discord.com/developers/resources/emoji#delete-application-emoji)
"""
delete_application_emoji(api::API, application::SnowflakeLike, emoji::SnowflakeLike) =
    request(api, Route(:DELETE, "/applications/{application_id}/emojis/{emoji_id}"),
            snowflake(application), snowflake(emoji))
