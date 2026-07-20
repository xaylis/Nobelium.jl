# https://docs.discord.com/developers/resources/message#attachment-object

export Attachment, AttachmentFlags, AttachmentFlag

@discord_flags AttachmentFlags UInt8 :number begin
    is_clip = 1 << 0
    is_thumbnail = 1 << 1
    is_remix = 1 << 2
    is_spoiler = 1 << 3
    is_animated = 1 << 5
end

"""
    Attachment

A file attached to a message. `duration_secs`/`waveform` are set for voice
messages; `clip_participants`/`clip_created_at`/`application` are set for
stream clips.
"""
@discord_object struct Attachment
    id::Snowflake
    filename::String
    title::Optional{String}
    description::Optional{String}
    content_type::Optional{String}
    size::Int
    url::String
    proxy_url::String
    height::OptionalNullable{Int}
    width::OptionalNullable{Int}
    placeholder::Optional{String}
    placeholder_version::Optional{Int}
    ephemeral::Optional{Bool}
    duration_secs::Optional{Float64}
    waveform::Optional{String}
    flags::Optional{AttachmentFlags}
    clip_participants::Optional{Vector{User}}
    clip_created_at::Optional{DateTime}
    application::OptionalNullable{Application}
end
