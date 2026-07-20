# https://docs.discord.com/developers/resources/message#embed-object

export Embed, EmbedFooter, EmbedImage, EmbedThumbnail, EmbedVideo, EmbedProvider,
    EmbedAuthor, EmbedField, EmbedFlags, EmbedFlag, EmbedMediaFlags, EmbedMediaFlag

@discord_flags EmbedFlags UInt8 :number begin
    is_content_inventory_entry = 1 << 5
end

@discord_flags EmbedMediaFlags UInt8 :number begin
    is_animated = 1 << 5
end

@discord_object struct EmbedFooter
    text::String
    icon_url::Optional{String}
    proxy_icon_url::Optional{String}
end

@discord_object struct EmbedImage
    url::String
    proxy_url::Optional{String}
    height::Optional{Int}
    width::Optional{Int}
    content_type::Optional{String}
    placeholder::Optional{String}
    placeholder_version::Optional{Int}
    description::Optional{String}
    flags::Optional{EmbedMediaFlags}
end

"""
    EmbedThumbnail

An embed thumbnail; Discord documents it with the same structure as
`EmbedImage`.
"""
@discord_object struct EmbedThumbnail
    url::String
    proxy_url::Optional{String}
    height::Optional{Int}
    width::Optional{Int}
    content_type::Optional{String}
    placeholder::Optional{String}
    placeholder_version::Optional{Int}
    description::Optional{String}
    flags::Optional{EmbedMediaFlags}
end

@discord_object struct EmbedVideo
    url::Optional{String}
    proxy_url::Optional{String}
    height::Optional{Int}
    width::Optional{Int}
    content_type::Optional{String}
    placeholder::Optional{String}
    placeholder_version::Optional{Int}
    description::Optional{String}
    flags::Optional{EmbedMediaFlags}
end

@discord_object struct EmbedProvider
    name::Optional{String}
    url::Optional{String}
end

@discord_object struct EmbedAuthor
    name::String
    url::Optional{String}
    icon_url::Optional{String}
    proxy_icon_url::Optional{String}
end

@discord_object struct EmbedField
    name::String
    value::String
    inline::Optional{Bool}
end

"""
    Embed

Rich content attached to a message. `type` is one of `"rich"`, `"image"`,
`"video"`, `"gifv"`, `"article"`, `"link"`, or `"poll_result"` — always
`"rich"` for embeds sent by bots and webhooks.
"""
@discord_object struct Embed
    title::Optional{String}
    type::Optional{String}
    description::Optional{String}
    url::Optional{String}
    timestamp::Optional{DateTime}
    color::Optional{Int}
    footer::Optional{EmbedFooter}
    image::Optional{EmbedImage}
    thumbnail::Optional{EmbedThumbnail}
    video::Optional{EmbedVideo}
    provider::Optional{EmbedProvider}
    author::Optional{EmbedAuthor}
    fields::Optional{Vector{EmbedField}}
    flags::Optional{EmbedFlags}
end
