# https://docs.discord.com/developers/resources/sticker

export Sticker, StickerItem, StickerPack, StickerType, StickerTypes,
    StickerFormatType, StickerFormatTypes

@discord_enum StickerType UInt8 begin
    STANDARD = 1
    GUILD = 2
end

@discord_enum StickerFormatType UInt8 begin
    PNG = 1
    APNG = 2
    LOTTIE = 3
    GIF = 4
end

"""
    Sticker

`tags` is a comma-separated list of autocomplete keywords for standard
stickers, or the name of the associated emoji for guild stickers.
"""
@discord_object struct Sticker
    id::Snowflake
    pack_id::Optional{Snowflake}
    name::String
    description::Nullable{String}
    tags::String
    type::StickerType
    format_type::StickerFormatType
    available::Optional{Bool}
    guild_id::Optional{Snowflake}
    user::Optional{User}
    sort_value::Optional{Int}
end

@discord_object struct StickerItem
    id::Snowflake
    name::String
    format_type::StickerFormatType
end

@discord_object struct StickerPack
    id::Snowflake
    stickers::Vector{Sticker}
    name::String
    sku_id::Snowflake
    cover_sticker_id::Optional{Snowflake}
    description::String
    banner_asset_id::Optional{Snowflake}
end
