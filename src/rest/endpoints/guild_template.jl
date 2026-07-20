# https://docs.discord.com/developers/resources/guild-template

export get_guild_template, create_guild_from_guild_template, get_guild_templates,
    create_guild_template, sync_guild_template, modify_guild_template,
    delete_guild_template

"""
    get_guild_template(api, template_code) -> GuildTemplate

[Docs](https://docs.discord.com/developers/resources/guild-template#get-guild-template)
"""
get_guild_template(api::API, code::AbstractString) =
    request(api, Route(:GET, "/guilds/templates/{template_code}"), code; into=GuildTemplate)

"""
    create_guild_from_guild_template(api, template_code; name, icon) -> Guild

Create a guild from a template. Only usable by bots in fewer than 10 guilds.
[Docs](https://docs.discord.com/developers/resources/guild-template#create-guild-from-guild-template)
"""
create_guild_from_guild_template(api::API, code::AbstractString; kwargs...) =
    request(api, Route(:POST, "/guilds/templates/{template_code}"), code;
            body=kwargs, into=Guild)

"""
    get_guild_templates(api, guild_id) -> Vector{GuildTemplate}

[Docs](https://docs.discord.com/developers/resources/guild-template#get-guild-templates)
"""
get_guild_templates(api::API, guild::SnowflakeLike) =
    request(api, Route(:GET, "/guilds/{guild_id}/templates"), snowflake(guild);
            into=Vector{GuildTemplate})

"""
    create_guild_template(api, guild_id; name, description) -> GuildTemplate

[Docs](https://docs.discord.com/developers/resources/guild-template#create-guild-template)
"""
create_guild_template(api::API, guild::SnowflakeLike; kwargs...) =
    request(api, Route(:POST, "/guilds/{guild_id}/templates"), snowflake(guild);
            body=kwargs, into=GuildTemplate)

"""
    sync_guild_template(api, guild_id, template_code) -> GuildTemplate

Sync the template to the guild's current state.
[Docs](https://docs.discord.com/developers/resources/guild-template#sync-guild-template)
"""
sync_guild_template(api::API, guild::SnowflakeLike, code::AbstractString) =
    request(api, Route(:PUT, "/guilds/{guild_id}/templates/{template_code}"),
            snowflake(guild), code; into=GuildTemplate)

"""
    modify_guild_template(api, guild_id, template_code; name, description) -> GuildTemplate

[Docs](https://docs.discord.com/developers/resources/guild-template#modify-guild-template)
"""
modify_guild_template(api::API, guild::SnowflakeLike, code::AbstractString; kwargs...) =
    request(api, Route(:PATCH, "/guilds/{guild_id}/templates/{template_code}"),
            snowflake(guild), code; body=kwargs, into=GuildTemplate)

"""
    delete_guild_template(api, guild_id, template_code) -> GuildTemplate

Returns the deleted template.
[Docs](https://docs.discord.com/developers/resources/guild-template#delete-guild-template)
"""
delete_guild_template(api::API, guild::SnowflakeLike, code::AbstractString) =
    request(api, Route(:DELETE, "/guilds/{guild_id}/templates/{template_code}"),
            snowflake(guild), code; into=GuildTemplate)
