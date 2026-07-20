# Discord's message formatting mini-language:
# https://docs.discord.com/developers/reference#message-formatting

mention_user(id::SnowflakeLike) = "<@$(snowflake(id))>"
mention_channel(id::SnowflakeLike) = "<#$(snowflake(id))>"
mention_role(id::SnowflakeLike) = "<@&$(snowflake(id))>"
mention_command(name::AbstractString, id::SnowflakeLike) = "</$name:$(snowflake(id))>"

"""
    emoji_tag(name, id; animated=false) -> String

The message form of a custom emoji, e.g. `"<:party:1234567890>"`.
"""
emoji_tag(name::AbstractString, id::SnowflakeLike; animated::Bool=false) =
    "<$(animated ? "a" : ""):$name:$(snowflake(id))>"

"""
    discord_timestamp(t::DateTime; style=:f) -> String

A `<t:...>` tag that Discord clients render in the reader's local time zone.
Styles: `:t` short time, `:T` long time, `:d` short date, `:D` long date,
`:f` short date-time (default), `:F` long date-time, `:R` relative ("3 hours ago").
"""
function discord_timestamp(t::DateTime; style::Symbol=:f)
    style in (:t, :T, :d, :D, :f, :F, :R) || throw(ArgumentError("unknown timestamp style :$style"))
    unix = round(Int, datetime2unix(t))
    "<t:$unix:$style>"
end

inline_code(s::AbstractString) = string('`', s, '`')
code_block(s::AbstractString; language::AbstractString="") = string("```", language, '\n', s, "\n```")

"""
    escape_markdown(s) -> String

Backslash-escape the characters Discord treats as markdown, so `s` renders
literally in a message.
"""
escape_markdown(s::AbstractString) = replace(s, r"([\\*_~`|>#-])" => s"\\\1")
