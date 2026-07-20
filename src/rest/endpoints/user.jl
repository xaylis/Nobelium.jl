# https://docs.discord.com/developers/resources/user

export get_current_user, get_user, modify_current_user, get_current_user_guilds,
    get_current_user_guild_member, leave_guild, create_dm, create_group_dm,
    get_current_user_connections, get_current_user_application_role_connection,
    update_current_user_application_role_connection

"""
    get_current_user(api) -> User

Fetch the bot's own user. With a bearer token, requires the `identify` scope.
[Docs](https://docs.discord.com/developers/resources/user#get-current-user)
"""
get_current_user(api::API; kwargs...) =
    request(api, Route(:GET, "/users/@me"); into=User, kwargs...)

"""
    get_user(api, user_id) -> User

[Docs](https://docs.discord.com/developers/resources/user#get-user)
"""
get_user(api::API, user::SnowflakeLike) =
    request(api, Route(:GET, "/users/{user_id}"), snowflake(user); into=User)

"""
    modify_current_user(api; username, avatar, banner) -> User

Update the bot's own account. `avatar` and `banner` take image data URIs, or
`nothing` to remove.
[Docs](https://docs.discord.com/developers/resources/user#modify-current-user)
"""
modify_current_user(api::API; kwargs...) =
    request(api, Route(:PATCH, "/users/@me"); body=kwargs, into=User)

"""
    get_current_user_guilds(api; before, after, limit, with_counts) -> Vector{Guild}

The guilds the bot is in, as partial [`Guild`](@ref)s (200 per page, paginate
with `before`/`after`).
[Docs](https://docs.discord.com/developers/resources/user#get-current-user-guilds)
"""
get_current_user_guilds(api::API; kwargs...) =
    request(api, Route(:GET, "/users/@me/guilds"); query=kwargs, into=Vector{Guild})

"""
    get_current_user_guild_member(api, guild_id) -> GuildMember

[Docs](https://docs.discord.com/developers/resources/user#get-current-user-guild-member)
"""
get_current_user_guild_member(api::API, guild::SnowflakeLike) =
    request(api, Route(:GET, "/users/@me/guilds/{guild_id}/member"), snowflake(guild);
            into=GuildMember)

"""
    leave_guild(api, guild_id)

[Docs](https://docs.discord.com/developers/resources/user#leave-guild)
"""
leave_guild(api::API, guild::SnowflakeLike) =
    request(api, Route(:DELETE, "/users/@me/guilds/{guild_id}"), snowflake(guild))

"""
    create_dm(api, recipient_id) -> DiscordChannel

Open (or fetch the existing) DM channel with a user.
[Docs](https://docs.discord.com/developers/resources/user#create-dm)
"""
create_dm(api::API, recipient::SnowflakeLike) =
    request(api, Route(:POST, "/users/@me/channels");
            body=(recipient_id=snowflake(recipient),), into=DiscordChannel)

"""
    create_group_dm(api; access_tokens, nicks) -> DiscordChannel

[Docs](https://docs.discord.com/developers/resources/user#create-group-dm)
"""
create_group_dm(api::API; kwargs...) =
    request(api, Route(:POST, "/users/@me/channels"); body=kwargs, into=DiscordChannel)

"""
    get_current_user_connections(api) -> Vector{Connection}

Requires the `connections` OAuth2 scope.
[Docs](https://docs.discord.com/developers/resources/user#get-current-user-connections)
"""
get_current_user_connections(api::API) =
    request(api, Route(:GET, "/users/@me/connections"); into=Vector{Connection})

"""
    get_current_user_application_role_connection(api, application_id) -> ApplicationRoleConnection

Requires an OAuth2 token with the `role_connections.write` scope.
[Docs](https://docs.discord.com/developers/resources/user#get-current-user-application-role-connection)
"""
get_current_user_application_role_connection(api::API, application::SnowflakeLike) =
    request(api, Route(:GET, "/users/@me/applications/{application_id}/role-connection"),
            snowflake(application); into=ApplicationRoleConnection, auth=:bearer)

"""
    update_current_user_application_role_connection(api, application_id; platform_name, platform_username, metadata) -> ApplicationRoleConnection

[Docs](https://docs.discord.com/developers/resources/user#update-current-user-application-role-connection)
"""
update_current_user_application_role_connection(api::API, application::SnowflakeLike; kwargs...) =
    request(api, Route(:PUT, "/users/@me/applications/{application_id}/role-connection"),
            snowflake(application); body=kwargs, into=ApplicationRoleConnection, auth=:bearer)
