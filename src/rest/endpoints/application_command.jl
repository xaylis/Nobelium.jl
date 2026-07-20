# https://docs.discord.com/developers/interactions/application-commands

export get_global_application_commands, create_global_application_command,
    get_global_application_command, edit_global_application_command,
    delete_global_application_command, bulk_overwrite_global_application_commands,
    get_guild_application_commands, create_guild_application_command,
    get_guild_application_command, edit_guild_application_command,
    delete_guild_application_command, bulk_overwrite_guild_application_commands,
    get_guild_application_command_permissions, get_application_command_permissions,
    edit_application_command_permissions

"""
    get_global_application_commands(api, application_id; with_localizations) -> Vector{ApplicationCommand}

[Docs](https://docs.discord.com/developers/interactions/application-commands#get-global-application-commands)
"""
get_global_application_commands(api::API, application::SnowflakeLike; kwargs...) =
    request(api, Route(:GET, "/applications/{application_id}/commands"),
            snowflake(application); query=kwargs, into=Vector{ApplicationCommand})

"""
    create_global_application_command(api, application_id; name, description, options, ...) -> ApplicationCommand

Creating a command with the same name as an existing one overwrites it.
[Docs](https://docs.discord.com/developers/interactions/application-commands#create-global-application-command)
"""
create_global_application_command(api::API, application::SnowflakeLike; kwargs...) =
    request(api, Route(:POST, "/applications/{application_id}/commands"),
            snowflake(application); body=kwargs, into=ApplicationCommand)

"""
    get_global_application_command(api, application_id, command_id) -> ApplicationCommand

[Docs](https://docs.discord.com/developers/interactions/application-commands#get-global-application-command)
"""
get_global_application_command(api::API, application::SnowflakeLike, command::SnowflakeLike) =
    request(api, Route(:GET, "/applications/{application_id}/commands/{command_id}"),
            snowflake(application), snowflake(command); into=ApplicationCommand)

"""
    edit_global_application_command(api, application_id, command_id; name, description, ...) -> ApplicationCommand

[Docs](https://docs.discord.com/developers/interactions/application-commands#edit-global-application-command)
"""
edit_global_application_command(api::API, application::SnowflakeLike, command::SnowflakeLike;
                                kwargs...) =
    request(api, Route(:PATCH, "/applications/{application_id}/commands/{command_id}"),
            snowflake(application), snowflake(command); body=kwargs, into=ApplicationCommand)

"""
    delete_global_application_command(api, application_id, command_id)

[Docs](https://docs.discord.com/developers/interactions/application-commands#delete-global-application-command)
"""
delete_global_application_command(api::API, application::SnowflakeLike, command::SnowflakeLike) =
    request(api, Route(:DELETE, "/applications/{application_id}/commands/{command_id}"),
            snowflake(application), snowflake(command))

"""
    bulk_overwrite_global_application_commands(api, application_id, commands) -> Vector{ApplicationCommand}

Replace all global commands with `commands`.
[Docs](https://docs.discord.com/developers/interactions/application-commands#bulk-overwrite-global-application-commands)
"""
bulk_overwrite_global_application_commands(api::API, application::SnowflakeLike,
                                           commands::AbstractVector) =
    request(api, Route(:PUT, "/applications/{application_id}/commands"),
            snowflake(application); body=commands, into=Vector{ApplicationCommand})

"""
    get_guild_application_commands(api, application_id, guild_id; with_localizations) -> Vector{ApplicationCommand}

[Docs](https://docs.discord.com/developers/interactions/application-commands#get-guild-application-commands)
"""
get_guild_application_commands(api::API, application::SnowflakeLike, guild::SnowflakeLike;
                               kwargs...) =
    request(api, Route(:GET, "/applications/{application_id}/guilds/{guild_id}/commands"),
            snowflake(application), snowflake(guild);
            query=kwargs, into=Vector{ApplicationCommand})

"""
    create_guild_application_command(api, application_id, guild_id; name, description, ...) -> ApplicationCommand

Guild commands are available immediately.
[Docs](https://docs.discord.com/developers/interactions/application-commands#create-guild-application-command)
"""
create_guild_application_command(api::API, application::SnowflakeLike, guild::SnowflakeLike;
                                 kwargs...) =
    request(api, Route(:POST, "/applications/{application_id}/guilds/{guild_id}/commands"),
            snowflake(application), snowflake(guild); body=kwargs, into=ApplicationCommand)

"""
    get_guild_application_command(api, application_id, guild_id, command_id) -> ApplicationCommand

[Docs](https://docs.discord.com/developers/interactions/application-commands#get-guild-application-command)
"""
get_guild_application_command(api::API, application::SnowflakeLike, guild::SnowflakeLike,
                              command::SnowflakeLike) =
    request(api,
            Route(:GET, "/applications/{application_id}/guilds/{guild_id}/commands/{command_id}"),
            snowflake(application), snowflake(guild), snowflake(command);
            into=ApplicationCommand)

"""
    edit_guild_application_command(api, application_id, guild_id, command_id; name, ...) -> ApplicationCommand

[Docs](https://docs.discord.com/developers/interactions/application-commands#edit-guild-application-command)
"""
edit_guild_application_command(api::API, application::SnowflakeLike, guild::SnowflakeLike,
                               command::SnowflakeLike; kwargs...) =
    request(api,
            Route(:PATCH, "/applications/{application_id}/guilds/{guild_id}/commands/{command_id}"),
            snowflake(application), snowflake(guild), snowflake(command);
            body=kwargs, into=ApplicationCommand)

"""
    delete_guild_application_command(api, application_id, guild_id, command_id)

[Docs](https://docs.discord.com/developers/interactions/application-commands#delete-guild-application-command)
"""
delete_guild_application_command(api::API, application::SnowflakeLike, guild::SnowflakeLike,
                                 command::SnowflakeLike) =
    request(api,
            Route(:DELETE, "/applications/{application_id}/guilds/{guild_id}/commands/{command_id}"),
            snowflake(application), snowflake(guild), snowflake(command))

"""
    bulk_overwrite_guild_application_commands(api, application_id, guild_id, commands) -> Vector{ApplicationCommand}

Replace all of the guild's commands with `commands`.
[Docs](https://docs.discord.com/developers/interactions/application-commands#bulk-overwrite-guild-application-commands)
"""
bulk_overwrite_guild_application_commands(api::API, application::SnowflakeLike,
                                          guild::SnowflakeLike, commands::AbstractVector) =
    request(api, Route(:PUT, "/applications/{application_id}/guilds/{guild_id}/commands"),
            snowflake(application), snowflake(guild);
            body=commands, into=Vector{ApplicationCommand})

"""
    get_guild_application_command_permissions(api, application_id, guild_id) -> Vector{GuildApplicationCommandPermissions}

Permission overwrites for all of the application's commands in the guild.
[Docs](https://docs.discord.com/developers/interactions/application-commands#get-guild-application-command-permissions)
"""
get_guild_application_command_permissions(api::API, application::SnowflakeLike,
                                          guild::SnowflakeLike) =
    request(api,
            Route(:GET, "/applications/{application_id}/guilds/{guild_id}/commands/permissions"),
            snowflake(application), snowflake(guild);
            into=Vector{GuildApplicationCommandPermissions})

"""
    get_application_command_permissions(api, application_id, guild_id, command_id) -> GuildApplicationCommandPermissions

[Docs](https://docs.discord.com/developers/interactions/application-commands#get-application-command-permissions)
"""
get_application_command_permissions(api::API, application::SnowflakeLike, guild::SnowflakeLike,
                                    command::SnowflakeLike) =
    request(api,
            Route(:GET, "/applications/{application_id}/guilds/{guild_id}/commands/{command_id}/permissions"),
            snowflake(application), snowflake(guild), snowflake(command);
            into=GuildApplicationCommandPermissions)

"""
    edit_application_command_permissions(api, application_id, guild_id, command_id; permissions) -> GuildApplicationCommandPermissions

Requires a Bearer token authorized with the
`applications.commands.permissions.update` scope.
[Docs](https://docs.discord.com/developers/interactions/application-commands#edit-application-command-permissions)
"""
edit_application_command_permissions(api::API, application::SnowflakeLike, guild::SnowflakeLike,
                                     command::SnowflakeLike; kwargs...) =
    request(api,
            Route(:PUT, "/applications/{application_id}/guilds/{guild_id}/commands/{command_id}/permissions"),
            snowflake(application), snowflake(guild), snowflake(command);
            body=kwargs, into=GuildApplicationCommandPermissions, auth=:bearer)
