# https://docs.discord.com/developers/resources/message

export get_channel_messages, get_channel_message, create_message, crosspost_message,
    create_reaction, delete_own_reaction, delete_user_reaction, get_reactions,
    delete_all_reactions, delete_all_reactions_for_emoji, edit_message, delete_message,
    bulk_delete_messages, get_channel_pins, pin_message, unpin_message

"""
    get_channel_messages(api, channel_id; around, before, after, limit) -> Vector{Message}

`around`, `before`, and `after` are mutually exclusive.
[Docs](https://docs.discord.com/developers/resources/message#get-channel-messages)
"""
get_channel_messages(api::API, channel::SnowflakeLike; kwargs...) =
    request(api, Route(:GET, "/channels/{channel_id}/messages"), snowflake(channel);
            query=kwargs, into=Vector{Message})

"""
    get_channel_message(api, channel_id, message_id) -> Message

[Docs](https://docs.discord.com/developers/resources/message#get-channel-message)
"""
get_channel_message(api::API, channel::SnowflakeLike, message::SnowflakeLike) =
    request(api, Route(:GET, "/channels/{channel_id}/messages/{message_id}"),
            snowflake(channel), snowflake(message); into=Message)

"""
    create_message(api, channel_id; content, embeds, components, sticker_ids, poll, files, ...) -> Message

At least one of `content`, `embeds`, `sticker_ids`, `components`, `files`,
`poll`, or `shared_client_theme` is required.
[Docs](https://docs.discord.com/developers/resources/message#create-message)
"""
create_message(api::API, channel::SnowflakeLike; files=nothing, kwargs...) =
    request(api, Route(:POST, "/channels/{channel_id}/messages"), snowflake(channel);
            body=kwargs, files, into=Message)

"""
    crosspost_message(api, channel_id, message_id) -> Message

Publish a message in an Announcement Channel to following channels.
[Docs](https://docs.discord.com/developers/resources/message#crosspost-message)
"""
crosspost_message(api::API, channel::SnowflakeLike, message::SnowflakeLike) =
    request(api, Route(:POST, "/channels/{channel_id}/messages/{message_id}/crosspost"),
            snowflake(channel), snowflake(message); into=Message)

"""
    create_reaction(api, channel_id, message_id, emoji)

`emoji` is `"name:id"` for a custom emoji or the raw unicode character for a
standard one.
[Docs](https://docs.discord.com/developers/resources/message#create-reaction)
"""
create_reaction(api::API, channel::SnowflakeLike, message::SnowflakeLike, emoji::AbstractString) =
    request(api, Route(:PUT, "/channels/{channel_id}/messages/{message_id}/reactions/{emoji}/@me"),
            snowflake(channel), snowflake(message), emoji)

"""
    delete_own_reaction(api, channel_id, message_id, emoji)

[Docs](https://docs.discord.com/developers/resources/message#delete-own-reaction)
"""
delete_own_reaction(api::API, channel::SnowflakeLike, message::SnowflakeLike, emoji::AbstractString) =
    request(api, Route(:DELETE, "/channels/{channel_id}/messages/{message_id}/reactions/{emoji}/@me"),
            snowflake(channel), snowflake(message), emoji)

"""
    delete_user_reaction(api, channel_id, message_id, emoji, user_id)

[Docs](https://docs.discord.com/developers/resources/message#delete-user-reaction)
"""
delete_user_reaction(api::API, channel::SnowflakeLike, message::SnowflakeLike,
                     emoji::AbstractString, user::SnowflakeLike) =
    request(api, Route(:DELETE, "/channels/{channel_id}/messages/{message_id}/reactions/{emoji}/{user_id}"),
            snowflake(channel), snowflake(message), emoji, snowflake(user))

"""
    get_reactions(api, channel_id, message_id, emoji; type, after, limit) -> Vector{User}

`type` distinguishes normal (`0`) from burst/super (`1`) reactions.
[Docs](https://docs.discord.com/developers/resources/message#get-reactions)
"""
get_reactions(api::API, channel::SnowflakeLike, message::SnowflakeLike, emoji::AbstractString; kwargs...) =
    request(api, Route(:GET, "/channels/{channel_id}/messages/{message_id}/reactions/{emoji}"),
            snowflake(channel), snowflake(message), emoji; query=kwargs, into=Vector{User})

"""
    delete_all_reactions(api, channel_id, message_id)

[Docs](https://docs.discord.com/developers/resources/message#delete-all-reactions)
"""
delete_all_reactions(api::API, channel::SnowflakeLike, message::SnowflakeLike) =
    request(api, Route(:DELETE, "/channels/{channel_id}/messages/{message_id}/reactions"),
            snowflake(channel), snowflake(message))

"""
    delete_all_reactions_for_emoji(api, channel_id, message_id, emoji)

[Docs](https://docs.discord.com/developers/resources/message#delete-all-reactions-for-emoji)
"""
delete_all_reactions_for_emoji(api::API, channel::SnowflakeLike, message::SnowflakeLike, emoji::AbstractString) =
    request(api, Route(:DELETE, "/channels/{channel_id}/messages/{message_id}/reactions/{emoji}"),
            snowflake(channel), snowflake(message), emoji)

"""
    edit_message(api, channel_id, message_id; content, embeds, flags, attachments, files, ...) -> Message

All parameters are optional and nullable; `attachments` must list every
attachment (kept and new) that should remain after the edit.
[Docs](https://docs.discord.com/developers/resources/message#edit-message)
"""
function edit_message(api::API, channel::SnowflakeLike, message::SnowflakeLike; files=nothing, kwargs...)
    request(api, Route(:PATCH, "/channels/{channel_id}/messages/{message_id}"),
            snowflake(channel), snowflake(message); body=kwargs, files, into=Message)
end

"""
    delete_message(api, channel_id, message_id; reason)

[Docs](https://docs.discord.com/developers/resources/message#delete-message)
"""
function delete_message(api::API, channel::SnowflakeLike, message::SnowflakeLike; reason=nothing)
    request(api, Route(:DELETE, "/channels/{channel_id}/messages/{message_id}"),
            snowflake(channel), snowflake(message); reason)
end

"""
    bulk_delete_messages(api, channel_id; messages, reason)

Deletes 2-100 messages in one call; none may be older than 2 weeks.
[Docs](https://docs.discord.com/developers/resources/message#bulk-delete-messages)
"""
function bulk_delete_messages(api::API, channel::SnowflakeLike; reason=nothing, kwargs...)
    request(api, Route(:POST, "/channels/{channel_id}/messages/bulk-delete"), snowflake(channel);
            body=kwargs, reason)
end

"""
    get_channel_pins(api, channel_id; before, limit)

Returns `{items: [MessagePin], has_more: Bool}`; paginate with `before` set
to the last item's `pinned_at`.
[Docs](https://docs.discord.com/developers/resources/message#get-channel-pins)
"""
get_channel_pins(api::API, channel::SnowflakeLike; kwargs...) =
    request(api, Route(:GET, "/channels/{channel_id}/messages/pins"), snowflake(channel);
            query=kwargs, into=Any)

"""
    pin_message(api, channel_id, message_id; reason)

[Docs](https://docs.discord.com/developers/resources/message#pin-message)
"""
function pin_message(api::API, channel::SnowflakeLike, message::SnowflakeLike; reason=nothing)
    request(api, Route(:PUT, "/channels/{channel_id}/messages/pins/{message_id}"),
            snowflake(channel), snowflake(message); reason)
end

"""
    unpin_message(api, channel_id, message_id; reason)

[Docs](https://docs.discord.com/developers/resources/message#unpin-message)
"""
function unpin_message(api::API, channel::SnowflakeLike, message::SnowflakeLike; reason=nothing)
    request(api, Route(:DELETE, "/channels/{channel_id}/messages/pins/{message_id}"),
            snowflake(channel), snowflake(message); reason)
end
