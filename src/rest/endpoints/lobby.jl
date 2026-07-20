# https://docs.discord.com/developers/resources/lobby

export create_lobby, create_or_join_lobby, get_lobby, modify_lobby, delete_lobby,
    add_lobby_member, bulk_lobby_member_update, remove_lobby_member, leave_lobby,
    link_channel_to_lobby, unlink_channel_from_lobby, send_lobby_message, get_lobby_messages,
    update_lobby_message_moderation_metadata, create_lobby_channel_invite_for_self,
    create_lobby_channel_invite_for_user

"""
    create_lobby(api; metadata, members, idle_timeout_seconds) -> Lobby

[Docs](https://docs.discord.com/developers/resources/lobby#create-lobby)
"""
create_lobby(api::API; kwargs...) =
    request(api, Route(:POST, "/lobbies"); body=kwargs, into=Lobby)

"""
    create_or_join_lobby(api; secret, idle_timeout_seconds, lobby_metadata,
                         member_metadata) -> Lobby

Creates a lobby for `secret` if none exists yet, otherwise joins the caller to
the existing one. Requires the `sdk.social_layer` OAuth2 scope.
[Docs](https://docs.discord.com/developers/resources/lobby#create-or-join-lobby)
"""
create_or_join_lobby(api::API; kwargs...) =
    request(api, Route(:PUT, "/lobbies"); body=kwargs, into=Lobby, auth=:bearer)

"""
    get_lobby(api, lobby_id) -> Lobby

[Docs](https://docs.discord.com/developers/resources/lobby#get-lobby)
"""
get_lobby(api::API, lobby::SnowflakeLike) =
    request(api, Route(:GET, "/lobbies/{lobby_id}"), snowflake(lobby); into=Lobby)

"""
    modify_lobby(api, lobby_id; metadata, members, idle_timeout_seconds) -> Lobby

[Docs](https://docs.discord.com/developers/resources/lobby#modify-lobby)
"""
modify_lobby(api::API, lobby::SnowflakeLike; kwargs...) =
    request(api, Route(:PATCH, "/lobbies/{lobby_id}"), snowflake(lobby); body=kwargs, into=Lobby)

"""
    delete_lobby(api, lobby_id)

[Docs](https://docs.discord.com/developers/resources/lobby#delete-lobby)
"""
delete_lobby(api::API, lobby::SnowflakeLike) =
    request(api, Route(:DELETE, "/lobbies/{lobby_id}"), snowflake(lobby))

"""
    add_lobby_member(api, lobby_id, user_id; metadata, flags) -> LobbyMember

Adds a user to the lobby, or updates their membership if already a member.
[Docs](https://docs.discord.com/developers/resources/lobby#add-a-member-to-a-lobby)
"""
add_lobby_member(api::API, lobby::SnowflakeLike, user::SnowflakeLike; kwargs...) =
    request(api, Route(:PUT, "/lobbies/{lobby_id}/members/{user_id}"),
            snowflake(lobby), snowflake(user); body=kwargs, into=LobbyMember)

"""
    bulk_lobby_member_update(api, lobby_id, members) -> Vector{LobbyMember}

`members` is 1-25 entries, each with `id`, and optional `metadata`, `flags`,
`remove_member`. Removed members are omitted from the result.
[Docs](https://docs.discord.com/developers/resources/lobby#bulk-lobby-member-update)
"""
bulk_lobby_member_update(api::API, lobby::SnowflakeLike, members) =
    request(api, Route(:POST, "/lobbies/{lobby_id}/members/bulk"), snowflake(lobby);
            body=members, into=Vector{LobbyMember})

"""
    remove_lobby_member(api, lobby_id, user_id)

[Docs](https://docs.discord.com/developers/resources/lobby#remove-a-member-from-a-lobby)
"""
remove_lobby_member(api::API, lobby::SnowflakeLike, user::SnowflakeLike) =
    request(api, Route(:DELETE, "/lobbies/{lobby_id}/members/{user_id}"),
            snowflake(lobby), snowflake(user))

"""
    leave_lobby(api, lobby_id)

Removes the caller from the lobby. Requires a bearer token.
[Docs](https://docs.discord.com/developers/resources/lobby#leave-lobby)
"""
leave_lobby(api::API, lobby::SnowflakeLike) =
    request(api, Route(:DELETE, "/lobbies/{lobby_id}/members/@me"), snowflake(lobby); auth=:bearer)

"""
    link_channel_to_lobby(api, lobby_id; channel_id) -> Lobby

Requires a bearer token and the `CanLinkLobby` member flag.
[Docs](https://docs.discord.com/developers/resources/lobby#link-channel-to-lobby)
"""
link_channel_to_lobby(api::API, lobby::SnowflakeLike; channel_id::SnowflakeLike) =
    request(api, Route(:PATCH, "/lobbies/{lobby_id}/channel-linking"), snowflake(lobby);
            body=(; channel_id=snowflake(channel_id)), into=Lobby, auth=:bearer)

"""
    unlink_channel_from_lobby(api, lobby_id) -> Lobby

Requires a bearer token and the `CanLinkLobby` member flag.
[Docs](https://docs.discord.com/developers/resources/lobby#unlink-channel-from-lobby)
"""
unlink_channel_from_lobby(api::API, lobby::SnowflakeLike) =
    request(api, Route(:PATCH, "/lobbies/{lobby_id}/channel-linking"), snowflake(lobby);
            body=NamedTuple(), into=Lobby, auth=:bearer)

"""
    send_lobby_message(api, lobby_id; content, metadata, flags) -> Any

Requires the `sdk.social_layer` OAuth2 scope.
[Docs](https://docs.discord.com/developers/resources/lobby#send-a-lobby-message)
"""
send_lobby_message(api::API, lobby::SnowflakeLike; kwargs...) =
    request(api, Route(:POST, "/lobbies/{lobby_id}/messages"), snowflake(lobby);
            body=kwargs, into=Any, auth=:bearer)

"""
    get_lobby_messages(api, lobby_id; limit) -> Any

Requires the `sdk.social_layer` OAuth2 scope.
[Docs](https://docs.discord.com/developers/resources/lobby#get-lobby-messages)
"""
get_lobby_messages(api::API, lobby::SnowflakeLike; kwargs...) =
    request(api, Route(:GET, "/lobbies/{lobby_id}/messages"), snowflake(lobby);
            query=kwargs, into=Any, auth=:bearer)

"""
    update_lobby_message_moderation_metadata(api, lobby_id, message_id, metadata)

`metadata` is up to 5 free-form key-value pairs (keys ≤1024 chars, values ≤2000 chars).
[Docs](https://docs.discord.com/developers/resources/lobby#update-lobby-message-moderation-metadata)
"""
update_lobby_message_moderation_metadata(api::API, lobby::SnowflakeLike, message::SnowflakeLike, metadata) =
    request(api, Route(:PUT, "/lobbies/{lobby_id}/messages/{message_id}/moderation-metadata"),
            snowflake(lobby), snowflake(message); body=metadata)

"""
    create_lobby_channel_invite_for_self(api, lobby_id) -> Any

Requires the `sdk.social_layer` OAuth2 scope.
[Docs](https://docs.discord.com/developers/resources/lobby#create-lobby-channel-invite-for-self)
"""
create_lobby_channel_invite_for_self(api::API, lobby::SnowflakeLike) =
    request(api, Route(:POST, "/lobbies/{lobby_id}/members/@me/invites"), snowflake(lobby);
            into=Any, auth=:bearer)

"""
    create_lobby_channel_invite_for_user(api, lobby_id, user_id) -> Any

[Docs](https://docs.discord.com/developers/resources/lobby#create-lobby-channel-invite-for-user)
"""
create_lobby_channel_invite_for_user(api::API, lobby::SnowflakeLike, user::SnowflakeLike) =
    request(api, Route(:POST, "/lobbies/{lobby_id}/members/{user_id}/invites"),
            snowflake(lobby), snowflake(user); into=Any)
