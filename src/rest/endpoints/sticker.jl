# https://docs.discord.com/developers/resources/sticker

export get_sticker, list_sticker_packs, get_sticker_pack, list_guild_stickers,
    get_guild_sticker, create_guild_sticker, modify_guild_sticker, delete_guild_sticker

"""
    get_sticker(api, sticker_id) -> Sticker

[Docs](https://docs.discord.com/developers/resources/sticker#get-sticker)
"""
get_sticker(api::API, sticker::SnowflakeLike) =
    request(api, Route(:GET, "/stickers/{sticker_id}"), snowflake(sticker); into=Sticker)

"""
    list_sticker_packs(api) -> JSON3.Object

The sticker packs available to Nitro subscribers, wrapped as
`{"sticker_packs": [...]}`.
[Docs](https://docs.discord.com/developers/resources/sticker#list-sticker-packs)
"""
list_sticker_packs(api::API) =
    request(api, Route(:GET, "/sticker-packs"); into=Any)

"""
    get_sticker_pack(api, pack_id) -> StickerPack

[Docs](https://docs.discord.com/developers/resources/sticker#get-sticker-pack)
"""
get_sticker_pack(api::API, pack::SnowflakeLike) =
    request(api, Route(:GET, "/sticker-packs/{pack_id}"), snowflake(pack);
            into=StickerPack)

"""
    list_guild_stickers(api, guild_id) -> Vector{Sticker}

Includes the `user` field if the bot has `CREATE_GUILD_EXPRESSIONS` or
`MANAGE_GUILD_EXPRESSIONS`.
[Docs](https://docs.discord.com/developers/resources/sticker#list-guild-stickers)
"""
list_guild_stickers(api::API, guild::SnowflakeLike) =
    request(api, Route(:GET, "/guilds/{guild_id}/stickers"), snowflake(guild);
            into=Vector{Sticker})

"""
    get_guild_sticker(api, guild_id, sticker_id) -> Sticker

[Docs](https://docs.discord.com/developers/resources/sticker#get-guild-sticker)
"""
get_guild_sticker(api::API, guild::SnowflakeLike, sticker::SnowflakeLike) =
    request(api, Route(:GET, "/guilds/{guild_id}/stickers/{sticker_id}"),
            snowflake(guild), snowflake(sticker); into=Sticker)

"""
    create_guild_sticker(api, guild_id, file::DiscordFile; name, description, tags, reason) -> Sticker

`file` is the sticker image (PNG, APNG, GIF, or Lottie JSON, at most 512 KiB).
Unlike other uploads, this endpoint takes its fields as top-level form data.
[Docs](https://docs.discord.com/developers/resources/sticker#create-guild-sticker)
"""
function create_guild_sticker(api::API, guild::SnowflakeLike, file::DiscordFile;
                              name, description, tags, reason=nothing)
    form = HTTP.Form(Pair{String,Any}[
        "name" => string(name),
        "description" => string(description),
        "tags" => string(tags),
        "file" => HTTP.Multipart(file.filename, IOBuffer(file.data), file.content_type),
    ])
    request(api, Route(:POST, "/guilds/{guild_id}/stickers"), snowflake(guild);
            body=form, into=Sticker, reason)
end

"""
    modify_guild_sticker(api, guild_id, sticker_id; name, description, tags, reason) -> Sticker

[Docs](https://docs.discord.com/developers/resources/sticker#modify-guild-sticker)
"""
function modify_guild_sticker(api::API, guild::SnowflakeLike, sticker::SnowflakeLike;
                              reason=nothing, kwargs...)
    request(api, Route(:PATCH, "/guilds/{guild_id}/stickers/{sticker_id}"),
            snowflake(guild), snowflake(sticker); body=kwargs, into=Sticker, reason)
end

"""
    delete_guild_sticker(api, guild_id, sticker_id; reason)

[Docs](https://docs.discord.com/developers/resources/sticker#delete-guild-sticker)
"""
function delete_guild_sticker(api::API, guild::SnowflakeLike, sticker::SnowflakeLike;
                              reason=nothing)
    request(api, Route(:DELETE, "/guilds/{guild_id}/stickers/{sticker_id}"),
            snowflake(guild), snowflake(sticker); reason)
end
