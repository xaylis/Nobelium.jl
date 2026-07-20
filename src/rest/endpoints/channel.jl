# https://docs.discord.com/developers/resources/channel

export get_channel, modify_channel, set_voice_channel_status, delete_channel,
    edit_channel_permissions, get_channel_invites, create_channel_invite,
    delete_channel_permission, follow_announcement_channel, trigger_typing_indicator,
    group_dm_add_recipient, group_dm_remove_recipient, start_thread_from_message,
    start_thread_without_message, start_thread_in_forum_or_media_channel, join_thread,
    add_thread_member, leave_thread, remove_thread_member, get_thread_member,
    list_thread_members, list_public_archived_threads, list_private_archived_threads,
    list_joined_private_archived_threads

"""
    get_channel(api, channel_id) -> DiscordChannel

For threads, the result includes a `member` field for the current user.
[Docs](https://docs.discord.com/developers/resources/channel#get-channel)
"""
get_channel(api::API, channel::SnowflakeLike) =
    request(api, Route(:GET, "/channels/{channel_id}"), snowflake(channel);
            into=DiscordChannel)

"""
    modify_channel(api, channel_id; reason, name, topic, position, ...) -> DiscordChannel

Accepted fields depend on the channel: `name`/`icon` for group DMs, the full
set for guild channels, `archived`/`locked`/`invitable` and friends for threads.
[Docs](https://docs.discord.com/developers/resources/channel#modify-channel)
"""
function modify_channel(api::API, channel::SnowflakeLike; reason=nothing, kwargs...)
    request(api, Route(:PATCH, "/channels/{channel_id}"), snowflake(channel);
            body=kwargs, into=DiscordChannel, reason)
end

"""
    set_voice_channel_status(api, channel_id; status, reason)

Set (or clear, with `status=nothing`) a voice channel's status.
[Docs](https://docs.discord.com/developers/resources/channel#set-voice-channel-status)
"""
function set_voice_channel_status(api::API, channel::SnowflakeLike; reason=nothing, kwargs...)
    request(api, Route(:PUT, "/channels/{channel_id}/voice-status"), snowflake(channel);
            body=kwargs, reason)
end

"""
    delete_channel(api, channel_id; reason) -> DiscordChannel

Delete a channel, or close a DM. Deleting a guild channel cannot be undone.
[Docs](https://docs.discord.com/developers/resources/channel#delete%2Fclose-channel)
"""
function delete_channel(api::API, channel::SnowflakeLike; reason=nothing)
    request(api, Route(:DELETE, "/channels/{channel_id}"), snowflake(channel);
            into=DiscordChannel, reason)
end

"""
    edit_channel_permissions(api, channel_id, overwrite_id; allow, deny, type, reason)

`type` is 0 for a role overwrite, 1 for a member overwrite.
[Docs](https://docs.discord.com/developers/resources/channel#edit-channel-permissions)
"""
function edit_channel_permissions(api::API, channel::SnowflakeLike, overwrite::SnowflakeLike;
                                  reason=nothing, kwargs...)
    request(api, Route(:PUT, "/channels/{channel_id}/permissions/{overwrite_id}"),
            snowflake(channel), snowflake(overwrite); body=kwargs, reason)
end

"""
    get_channel_invites(api, channel_id) -> Vector{Invite}

[Docs](https://docs.discord.com/developers/resources/channel#get-channel-invites)
"""
get_channel_invites(api::API, channel::SnowflakeLike) =
    request(api, Route(:GET, "/channels/{channel_id}/invites"), snowflake(channel);
            into=Vector{Invite})

"""
    create_channel_invite(api, channel_id; max_age, max_uses, temporary, unique, target_type, ..., reason) -> Invite

`files` carries the `target_users_file` CSV of user IDs for guest invites.
[Docs](https://docs.discord.com/developers/resources/channel#create-channel-invite)
"""
function create_channel_invite(api::API, channel::SnowflakeLike;
                               reason=nothing, files=nothing, kwargs...)
    request(api, Route(:POST, "/channels/{channel_id}/invites"), snowflake(channel);
            body=kwargs, files, into=Invite, reason)
end

"""
    delete_channel_permission(api, channel_id, overwrite_id; reason)

[Docs](https://docs.discord.com/developers/resources/channel#delete-channel-permission)
"""
function delete_channel_permission(api::API, channel::SnowflakeLike, overwrite::SnowflakeLike;
                                   reason=nothing)
    request(api, Route(:DELETE, "/channels/{channel_id}/permissions/{overwrite_id}"),
            snowflake(channel), snowflake(overwrite); reason)
end

"""
    follow_announcement_channel(api, channel_id; webhook_channel_id, reason) -> FollowedChannel

Crosspost the announcement channel's messages into `webhook_channel_id`.
[Docs](https://docs.discord.com/developers/resources/channel#follow-announcement-channel)
"""
function follow_announcement_channel(api::API, channel::SnowflakeLike; reason=nothing, kwargs...)
    request(api, Route(:POST, "/channels/{channel_id}/followers"), snowflake(channel);
            body=kwargs, into=FollowedChannel, reason)
end

"""
    trigger_typing_indicator(api, channel_id)

Shows "bot is typing..." for a few seconds or until a message is sent.
[Docs](https://docs.discord.com/developers/resources/channel#trigger-typing-indicator)
"""
trigger_typing_indicator(api::API, channel::SnowflakeLike) =
    request(api, Route(:POST, "/channels/{channel_id}/typing"), snowflake(channel))

"""
    group_dm_add_recipient(api, channel_id, user_id; access_token, nick)

`access_token` must carry the `gdm.join` OAuth2 scope.
[Docs](https://docs.discord.com/developers/resources/channel#group-dm-add-recipient)
"""
group_dm_add_recipient(api::API, channel::SnowflakeLike, user::SnowflakeLike; kwargs...) =
    request(api, Route(:PUT, "/channels/{channel_id}/recipients/{user_id}"),
            snowflake(channel), snowflake(user); body=kwargs)

"""
    group_dm_remove_recipient(api, channel_id, user_id)

[Docs](https://docs.discord.com/developers/resources/channel#group-dm-remove-recipient)
"""
group_dm_remove_recipient(api::API, channel::SnowflakeLike, user::SnowflakeLike) =
    request(api, Route(:DELETE, "/channels/{channel_id}/recipients/{user_id}"),
            snowflake(channel), snowflake(user))

"""
    start_thread_from_message(api, channel_id, message_id; name, auto_archive_duration, rate_limit_per_user, reason) -> DiscordChannel

[Docs](https://docs.discord.com/developers/resources/channel#start-thread-from-message)
"""
function start_thread_from_message(api::API, channel::SnowflakeLike, message::SnowflakeLike;
                                   reason=nothing, kwargs...)
    request(api, Route(:POST, "/channels/{channel_id}/messages/{message_id}/threads"),
            snowflake(channel), snowflake(message); body=kwargs, into=DiscordChannel, reason)
end

"""
    start_thread_without_message(api, channel_id; name, type, auto_archive_duration, invitable, rate_limit_per_user, reason) -> DiscordChannel

[Docs](https://docs.discord.com/developers/resources/channel#start-thread-without-message)
"""
function start_thread_without_message(api::API, channel::SnowflakeLike; reason=nothing, kwargs...)
    request(api, Route(:POST, "/channels/{channel_id}/threads"), snowflake(channel);
            body=kwargs, into=DiscordChannel, reason)
end

"""
    start_thread_in_forum_or_media_channel(api, channel_id; name, message, applied_tags, files, ..., reason) -> DiscordChannel

Creates a thread and its first message in one call; `message` takes the forum
thread message params. The result carries the new message nested under `message`.
[Docs](https://docs.discord.com/developers/resources/channel#start-thread-in-forum-or-media-channel)
"""
function start_thread_in_forum_or_media_channel(api::API, channel::SnowflakeLike;
                                                reason=nothing, files=nothing, kwargs...)
    request(api, Route(:POST, "/channels/{channel_id}/threads"), snowflake(channel);
            body=kwargs, files, into=DiscordChannel, reason)
end

"""
    join_thread(api, channel_id)

[Docs](https://docs.discord.com/developers/resources/channel#join-thread)
"""
join_thread(api::API, channel::SnowflakeLike) =
    request(api, Route(:PUT, "/channels/{channel_id}/thread-members/@me"), snowflake(channel))

"""
    add_thread_member(api, channel_id, user_id)

[Docs](https://docs.discord.com/developers/resources/channel#add-thread-member)
"""
add_thread_member(api::API, channel::SnowflakeLike, user::SnowflakeLike) =
    request(api, Route(:PUT, "/channels/{channel_id}/thread-members/{user_id}"),
            snowflake(channel), snowflake(user))

"""
    leave_thread(api, channel_id)

[Docs](https://docs.discord.com/developers/resources/channel#leave-thread)
"""
leave_thread(api::API, channel::SnowflakeLike) =
    request(api, Route(:DELETE, "/channels/{channel_id}/thread-members/@me"),
            snowflake(channel))

"""
    remove_thread_member(api, channel_id, user_id)

[Docs](https://docs.discord.com/developers/resources/channel#remove-thread-member)
"""
remove_thread_member(api::API, channel::SnowflakeLike, user::SnowflakeLike) =
    request(api, Route(:DELETE, "/channels/{channel_id}/thread-members/{user_id}"),
            snowflake(channel), snowflake(user))

"""
    get_thread_member(api, channel_id, user_id; with_member) -> ThreadMember

[Docs](https://docs.discord.com/developers/resources/channel#get-thread-member)
"""
get_thread_member(api::API, channel::SnowflakeLike, user::SnowflakeLike; kwargs...) =
    request(api, Route(:GET, "/channels/{channel_id}/thread-members/{user_id}"),
            snowflake(channel), snowflake(user); query=kwargs, into=ThreadMember)

"""
    list_thread_members(api, channel_id; with_member, after, limit) -> Vector{ThreadMember}

[Docs](https://docs.discord.com/developers/resources/channel#list-thread-members)
"""
list_thread_members(api::API, channel::SnowflakeLike; kwargs...) =
    request(api, Route(:GET, "/channels/{channel_id}/thread-members"), snowflake(channel);
            query=kwargs, into=Vector{ThreadMember})

"""
    list_public_archived_threads(api, channel_id; before, limit)

Most recently archived first; `before` is an ISO8601 timestamp. The result has
`threads`, `members`, and `has_more` keys.
[Docs](https://docs.discord.com/developers/resources/channel#list-public-archived-threads)
"""
list_public_archived_threads(api::API, channel::SnowflakeLike; kwargs...) =
    request(api, Route(:GET, "/channels/{channel_id}/threads/archived/public"),
            snowflake(channel); query=kwargs, into=Any)

"""
    list_private_archived_threads(api, channel_id; before, limit)

Requires both `READ_MESSAGE_HISTORY` and `MANAGE_THREADS`. Same result shape as
[`list_public_archived_threads`](@ref).
[Docs](https://docs.discord.com/developers/resources/channel#list-private-archived-threads)
"""
list_private_archived_threads(api::API, channel::SnowflakeLike; kwargs...) =
    request(api, Route(:GET, "/channels/{channel_id}/threads/archived/private"),
            snowflake(channel); query=kwargs, into=Any)

"""
    list_joined_private_archived_threads(api, channel_id; before, limit)

Private archived threads the bot has joined; paginates by thread id, not
timestamp. Same result shape as [`list_public_archived_threads`](@ref).
[Docs](https://docs.discord.com/developers/resources/channel#list-joined-private-archived-threads)
"""
list_joined_private_archived_threads(api::API, channel::SnowflakeLike; kwargs...) =
    request(api, Route(:GET, "/channels/{channel_id}/users/@me/threads/archived/private"),
            snowflake(channel); query=kwargs, into=Any)
