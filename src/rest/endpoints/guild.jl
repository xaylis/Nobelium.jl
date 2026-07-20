# https://docs.discord.com/developers/resources/guild

export create_guild, get_guild, get_guild_preview, modify_guild, delete_guild,
    get_guild_channels, create_guild_channel, modify_guild_channel_positions,
    list_active_guild_threads, get_guild_member, list_guild_members,
    search_guild_members, add_guild_member, modify_guild_member,
    modify_current_member, add_guild_member_role, remove_guild_member_role,
    remove_guild_member, get_guild_bans, get_guild_ban, create_guild_ban,
    remove_guild_ban, bulk_guild_ban, get_guild_roles, get_guild_role,
    create_guild_role, modify_guild_role_positions, modify_guild_role,
    modify_guild_mfa_level, delete_guild_role, get_guild_prune_count,
    begin_guild_prune, get_guild_voice_regions, get_guild_invites,
    get_guild_integrations, delete_guild_integration, get_guild_widget_settings,
    modify_guild_widget, get_guild_widget, get_guild_widget_image,
    get_guild_vanity_url, get_guild_welcome_screen, modify_guild_welcome_screen,
    get_guild_onboarding, modify_guild_onboarding

"""
    create_guild(api; name, icon, roles, channels, ...) -> Guild

Create a guild. Usable only by bots in fewer than 10 guilds.
[Docs](https://docs.discord.com/developers/resources/guild#create-guild)
"""
create_guild(api::API; kwargs...) =
    request(api, Route(:POST, "/guilds"); body=kwargs, into=Guild)

"""
    get_guild(api, guild_id; with_counts) -> Guild

[Docs](https://docs.discord.com/developers/resources/guild#get-guild)
"""
get_guild(api::API, guild::SnowflakeLike; kwargs...) =
    request(api, Route(:GET, "/guilds/{guild_id}"), snowflake(guild);
            query=kwargs, into=Guild)

"""
    get_guild_preview(api, guild_id) -> GuildPreview

[Docs](https://docs.discord.com/developers/resources/guild#get-guild-preview)
"""
get_guild_preview(api::API, guild::SnowflakeLike) =
    request(api, Route(:GET, "/guilds/{guild_id}/preview"), snowflake(guild);
            into=GuildPreview)

"""
    modify_guild(api, guild_id; name, icon, verification_level, ...) -> Guild

[Docs](https://docs.discord.com/developers/resources/guild#modify-guild)
"""
function modify_guild(api::API, guild::SnowflakeLike; reason=nothing, kwargs...)
    request(api, Route(:PATCH, "/guilds/{guild_id}"), snowflake(guild);
            body=kwargs, into=Guild, reason)
end

"""
    delete_guild(api, guild_id)

Delete a guild permanently. The bot must be the owner.
[Docs](https://docs.discord.com/developers/resources/guild#delete-guild)
"""
delete_guild(api::API, guild::SnowflakeLike) =
    request(api, Route(:DELETE, "/guilds/{guild_id}"), snowflake(guild))

"""
    get_guild_channels(api, guild_id) -> Vector{DiscordChannel}

All guild channels, excluding threads.
[Docs](https://docs.discord.com/developers/resources/guild#get-guild-channels)
"""
get_guild_channels(api::API, guild::SnowflakeLike) =
    request(api, Route(:GET, "/guilds/{guild_id}/channels"), snowflake(guild);
            into=Vector{DiscordChannel})

"""
    create_guild_channel(api, guild_id; name, type, topic, ...) -> DiscordChannel

[Docs](https://docs.discord.com/developers/resources/guild#create-guild-channel)
"""
function create_guild_channel(api::API, guild::SnowflakeLike; reason=nothing, kwargs...)
    request(api, Route(:POST, "/guilds/{guild_id}/channels"), snowflake(guild);
            body=kwargs, into=DiscordChannel, reason)
end

"""
    modify_guild_channel_positions(api, guild_id, positions)

Reorder channels; `positions` is a vector of `(; id, position, lock_permissions,
parent_id)`-shaped entries.
[Docs](https://docs.discord.com/developers/resources/guild#modify-guild-channel-positions)
"""
modify_guild_channel_positions(api::API, guild::SnowflakeLike, positions) =
    request(api, Route(:PATCH, "/guilds/{guild_id}/channels"), snowflake(guild);
            body=positions)

"""
    list_active_guild_threads(api, guild_id) -> Any

All active threads in the guild, as `(; threads, members)`.
[Docs](https://docs.discord.com/developers/resources/guild#list-active-guild-threads)
"""
list_active_guild_threads(api::API, guild::SnowflakeLike) =
    request(api, Route(:GET, "/guilds/{guild_id}/threads/active"), snowflake(guild);
            into=Any)

"""
    get_guild_member(api, guild_id, user_id) -> GuildMember

[Docs](https://docs.discord.com/developers/resources/guild#get-guild-member)
"""
get_guild_member(api::API, guild::SnowflakeLike, user::SnowflakeLike) =
    request(api, Route(:GET, "/guilds/{guild_id}/members/{user_id}"),
            snowflake(guild), snowflake(user); into=GuildMember)

"""
    list_guild_members(api, guild_id; limit, after) -> Vector{GuildMember}

Requires the `GUILD_MEMBERS` privileged intent (1000 per page, paginate with
`after`).
[Docs](https://docs.discord.com/developers/resources/guild#list-guild-members)
"""
list_guild_members(api::API, guild::SnowflakeLike; kwargs...) =
    request(api, Route(:GET, "/guilds/{guild_id}/members"), snowflake(guild);
            query=kwargs, into=Vector{GuildMember})

"""
    search_guild_members(api, guild_id; query, limit) -> Vector{GuildMember}

Members whose username or nickname starts with `query`.
[Docs](https://docs.discord.com/developers/resources/guild#search-guild-members)
"""
search_guild_members(api::API, guild::SnowflakeLike; kwargs...) =
    request(api, Route(:GET, "/guilds/{guild_id}/members/search"), snowflake(guild);
            query=kwargs, into=Vector{GuildMember})

"""
    add_guild_member(api, guild_id, user_id; access_token, nick, roles, mute, deaf) -> GuildMember

Add a user via an OAuth2 access token with the `guilds.join` scope. Returns
`nothing` if the user was already a member.
[Docs](https://docs.discord.com/developers/resources/guild#add-guild-member)
"""
add_guild_member(api::API, guild::SnowflakeLike, user::SnowflakeLike; kwargs...) =
    request(api, Route(:PUT, "/guilds/{guild_id}/members/{user_id}"),
            snowflake(guild), snowflake(user); body=kwargs, into=GuildMember)

"""
    modify_guild_member(api, guild_id, user_id; nick, roles, mute, deaf, channel_id, communication_disabled_until, flags) -> GuildMember

[Docs](https://docs.discord.com/developers/resources/guild#modify-guild-member)
"""
function modify_guild_member(api::API, guild::SnowflakeLike, user::SnowflakeLike;
                             reason=nothing, kwargs...)
    request(api, Route(:PATCH, "/guilds/{guild_id}/members/{user_id}"),
            snowflake(guild), snowflake(user); body=kwargs, into=GuildMember, reason)
end

"""
    modify_current_member(api, guild_id; nick, banner, avatar, bio) -> GuildMember

[Docs](https://docs.discord.com/developers/resources/guild#modify-current-member)
"""
function modify_current_member(api::API, guild::SnowflakeLike; reason=nothing, kwargs...)
    request(api, Route(:PATCH, "/guilds/{guild_id}/members/@me"), snowflake(guild);
            body=kwargs, into=GuildMember, reason)
end

"""
    add_guild_member_role(api, guild_id, user_id, role_id)

[Docs](https://docs.discord.com/developers/resources/guild#add-guild-member-role)
"""
function add_guild_member_role(api::API, guild::SnowflakeLike, user::SnowflakeLike,
                               role::SnowflakeLike; reason=nothing)
    request(api, Route(:PUT, "/guilds/{guild_id}/members/{user_id}/roles/{role_id}"),
            snowflake(guild), snowflake(user), snowflake(role); reason)
end

"""
    remove_guild_member_role(api, guild_id, user_id, role_id)

[Docs](https://docs.discord.com/developers/resources/guild#remove-guild-member-role)
"""
function remove_guild_member_role(api::API, guild::SnowflakeLike, user::SnowflakeLike,
                                  role::SnowflakeLike; reason=nothing)
    request(api, Route(:DELETE, "/guilds/{guild_id}/members/{user_id}/roles/{role_id}"),
            snowflake(guild), snowflake(user), snowflake(role); reason)
end

"""
    remove_guild_member(api, guild_id, user_id)

Kick a member from the guild.
[Docs](https://docs.discord.com/developers/resources/guild#remove-guild-member)
"""
function remove_guild_member(api::API, guild::SnowflakeLike, user::SnowflakeLike;
                             reason=nothing)
    request(api, Route(:DELETE, "/guilds/{guild_id}/members/{user_id}"),
            snowflake(guild), snowflake(user); reason)
end

"""
    get_guild_bans(api, guild_id; limit, before, after) -> Vector{Ban}

[Docs](https://docs.discord.com/developers/resources/guild#get-guild-bans)
"""
get_guild_bans(api::API, guild::SnowflakeLike; kwargs...) =
    request(api, Route(:GET, "/guilds/{guild_id}/bans"), snowflake(guild);
            query=kwargs, into=Vector{Ban})

"""
    get_guild_ban(api, guild_id, user_id) -> Ban

404 if the user is not banned.
[Docs](https://docs.discord.com/developers/resources/guild#get-guild-ban)
"""
get_guild_ban(api::API, guild::SnowflakeLike, user::SnowflakeLike) =
    request(api, Route(:GET, "/guilds/{guild_id}/bans/{user_id}"),
            snowflake(guild), snowflake(user); into=Ban)

"""
    create_guild_ban(api, guild_id, user_id; delete_message_seconds)

[Docs](https://docs.discord.com/developers/resources/guild#create-guild-ban)
"""
function create_guild_ban(api::API, guild::SnowflakeLike, user::SnowflakeLike;
                          reason=nothing, kwargs...)
    request(api, Route(:PUT, "/guilds/{guild_id}/bans/{user_id}"),
            snowflake(guild), snowflake(user); body=kwargs, reason)
end

"""
    remove_guild_ban(api, guild_id, user_id)

[Docs](https://docs.discord.com/developers/resources/guild#remove-guild-ban)
"""
function remove_guild_ban(api::API, guild::SnowflakeLike, user::SnowflakeLike;
                          reason=nothing)
    request(api, Route(:DELETE, "/guilds/{guild_id}/bans/{user_id}"),
            snowflake(guild), snowflake(user); reason)
end

"""
    bulk_guild_ban(api, guild_id; user_ids, delete_message_seconds) -> Any

Ban up to 200 users at once; returns `(; banned_users, failed_users)`. Fails
with a 500000 error if no users could be banned.
[Docs](https://docs.discord.com/developers/resources/guild#bulk-guild-ban)
"""
function bulk_guild_ban(api::API, guild::SnowflakeLike; reason=nothing, kwargs...)
    request(api, Route(:POST, "/guilds/{guild_id}/bulk-ban"), snowflake(guild);
            body=kwargs, into=Any, reason)
end

"""
    get_guild_roles(api, guild_id) -> Vector{Role}

[Docs](https://docs.discord.com/developers/resources/guild#get-guild-roles)
"""
get_guild_roles(api::API, guild::SnowflakeLike) =
    request(api, Route(:GET, "/guilds/{guild_id}/roles"), snowflake(guild);
            into=Vector{Role})

"""
    get_guild_role(api, guild_id, role_id) -> Role

[Docs](https://docs.discord.com/developers/resources/guild#get-guild-role)
"""
get_guild_role(api::API, guild::SnowflakeLike, role::SnowflakeLike) =
    request(api, Route(:GET, "/guilds/{guild_id}/roles/{role_id}"),
            snowflake(guild), snowflake(role); into=Role)

"""
    create_guild_role(api, guild_id; name, permissions, color, hoist, icon, unicode_emoji, mentionable) -> Role

[Docs](https://docs.discord.com/developers/resources/guild#create-guild-role)
"""
function create_guild_role(api::API, guild::SnowflakeLike; reason=nothing, kwargs...)
    request(api, Route(:POST, "/guilds/{guild_id}/roles"), snowflake(guild);
            body=kwargs, into=Role, reason)
end

"""
    modify_guild_role_positions(api, guild_id, positions) -> Vector{Role}

Reorder roles; `positions` is a vector of `(; id, position)`-shaped entries.
[Docs](https://docs.discord.com/developers/resources/guild#modify-guild-role-positions)
"""
function modify_guild_role_positions(api::API, guild::SnowflakeLike, positions;
                                     reason=nothing)
    request(api, Route(:PATCH, "/guilds/{guild_id}/roles"), snowflake(guild);
            body=positions, into=Vector{Role}, reason)
end

"""
    modify_guild_role(api, guild_id, role_id; name, permissions, color, ...) -> Role

[Docs](https://docs.discord.com/developers/resources/guild#modify-guild-role)
"""
function modify_guild_role(api::API, guild::SnowflakeLike, role::SnowflakeLike;
                           reason=nothing, kwargs...)
    request(api, Route(:PATCH, "/guilds/{guild_id}/roles/{role_id}"),
            snowflake(guild), snowflake(role); body=kwargs, into=Role, reason)
end

"""
    modify_guild_mfa_level(api, guild_id; level) -> Any

Set the guild's MFA requirement for moderation; the bot must be the owner.
Returns the updated level.
[Docs](https://docs.discord.com/developers/resources/guild#modify-guild-mfa-level)
"""
function modify_guild_mfa_level(api::API, guild::SnowflakeLike; reason=nothing, kwargs...)
    request(api, Route(:POST, "/guilds/{guild_id}/mfa"), snowflake(guild);
            body=kwargs, into=Any, reason)
end

"""
    delete_guild_role(api, guild_id, role_id)

[Docs](https://docs.discord.com/developers/resources/guild#delete-guild-role)
"""
function delete_guild_role(api::API, guild::SnowflakeLike, role::SnowflakeLike;
                           reason=nothing)
    request(api, Route(:DELETE, "/guilds/{guild_id}/roles/{role_id}"),
            snowflake(guild), snowflake(role); reason)
end

"""
    get_guild_prune_count(api, guild_id; days, include_roles) -> Any

The number of members a prune would remove, as `(; pruned)`. `include_roles`
is a comma-delimited list of role ids.
[Docs](https://docs.discord.com/developers/resources/guild#get-guild-prune-count)
"""
get_guild_prune_count(api::API, guild::SnowflakeLike; kwargs...) =
    request(api, Route(:GET, "/guilds/{guild_id}/prune"), snowflake(guild);
            query=kwargs, into=Any)

"""
    begin_guild_prune(api, guild_id; days, compute_prune_count, include_roles) -> Any

Returns `(; pruned)`, null when `compute_prune_count` is false.
[Docs](https://docs.discord.com/developers/resources/guild#begin-guild-prune)
"""
function begin_guild_prune(api::API, guild::SnowflakeLike; reason=nothing, kwargs...)
    request(api, Route(:POST, "/guilds/{guild_id}/prune"), snowflake(guild);
            body=kwargs, into=Any, reason)
end

"""
    get_guild_voice_regions(api, guild_id) -> Vector{VoiceRegion}

[Docs](https://docs.discord.com/developers/resources/guild#get-guild-voice-regions)
"""
get_guild_voice_regions(api::API, guild::SnowflakeLike) =
    request(api, Route(:GET, "/guilds/{guild_id}/regions"), snowflake(guild);
            into=Vector{VoiceRegion})

"""
    get_guild_invites(api, guild_id) -> Vector{Invite}

[Docs](https://docs.discord.com/developers/resources/guild#get-guild-invites)
"""
get_guild_invites(api::API, guild::SnowflakeLike) =
    request(api, Route(:GET, "/guilds/{guild_id}/invites"), snowflake(guild);
            into=Vector{Invite})

"""
    get_guild_integrations(api, guild_id) -> Vector{Integration}

At most 50 integrations; hitting the cap truncates the list arbitrarily.
[Docs](https://docs.discord.com/developers/resources/guild#get-guild-integrations)
"""
get_guild_integrations(api::API, guild::SnowflakeLike) =
    request(api, Route(:GET, "/guilds/{guild_id}/integrations"), snowflake(guild);
            into=Vector{Integration})

"""
    delete_guild_integration(api, guild_id, integration_id)

Also deletes any associated webhooks and kicks the associated bot.
[Docs](https://docs.discord.com/developers/resources/guild#delete-guild-integration)
"""
function delete_guild_integration(api::API, guild::SnowflakeLike,
                                  integration::SnowflakeLike; reason=nothing)
    request(api, Route(:DELETE, "/guilds/{guild_id}/integrations/{integration_id}"),
            snowflake(guild), snowflake(integration); reason)
end

"""
    get_guild_widget_settings(api, guild_id) -> GuildWidgetSettings

[Docs](https://docs.discord.com/developers/resources/guild#get-guild-widget-settings)
"""
get_guild_widget_settings(api::API, guild::SnowflakeLike) =
    request(api, Route(:GET, "/guilds/{guild_id}/widget"), snowflake(guild);
            into=GuildWidgetSettings)

"""
    modify_guild_widget(api, guild_id; enabled, channel_id) -> GuildWidgetSettings

[Docs](https://docs.discord.com/developers/resources/guild#modify-guild-widget)
"""
function modify_guild_widget(api::API, guild::SnowflakeLike; reason=nothing, kwargs...)
    request(api, Route(:PATCH, "/guilds/{guild_id}/widget"), snowflake(guild);
            body=kwargs, into=GuildWidgetSettings, reason)
end

"""
    get_guild_widget(api, guild_id) -> GuildWidget

[Docs](https://docs.discord.com/developers/resources/guild#get-guild-widget)
"""
get_guild_widget(api::API, guild::SnowflakeLike) =
    request(api, Route(:GET, "/guilds/{guild_id}/widget.json"), snowflake(guild);
            into=GuildWidget)

"""
    get_guild_vanity_url(api, guild_id) -> Any

The guild's vanity invite as `(; code, uses)`; requires the `MANAGE_GUILD`
permission.
[Docs](https://docs.discord.com/developers/resources/guild#get-guild-vanity-url)
"""
get_guild_vanity_url(api::API, guild::SnowflakeLike) =
    request(api, Route(:GET, "/guilds/{guild_id}/vanity-url"), snowflake(guild);
            into=Any)

"""
    get_guild_widget_image(api, guild_id; style) -> Vector{UInt8}

The guild's widget as a PNG. `style` is one of `shield` (default) or
`banner1`–`banner4`. This endpoint requires no authentication.
[Docs](https://docs.discord.com/developers/resources/guild#get-guild-widget-image)
"""
function get_guild_widget_image(api::API, guild::SnowflakeLike; style=missing)
    url = api.base_url * path(Route(:GET, "/guilds/{guild_id}/widget.png"), snowflake(guild)) *
          _query_string((; style))
    resp = api.http("GET", url, ["User-Agent" => api.user_agent], UInt8[])
    resp.status < 400 || throw(_api_error(resp.status, String(resp.body)))
    Vector{UInt8}(resp.body)
end

"""
    get_guild_welcome_screen(api, guild_id) -> WelcomeScreen

[Docs](https://docs.discord.com/developers/resources/guild#get-guild-welcome-screen)
"""
get_guild_welcome_screen(api::API, guild::SnowflakeLike) =
    request(api, Route(:GET, "/guilds/{guild_id}/welcome-screen"), snowflake(guild);
            into=WelcomeScreen)

"""
    modify_guild_welcome_screen(api, guild_id; enabled, welcome_channels, description) -> WelcomeScreen

[Docs](https://docs.discord.com/developers/resources/guild#modify-guild-welcome-screen)
"""
function modify_guild_welcome_screen(api::API, guild::SnowflakeLike;
                                     reason=nothing, kwargs...)
    request(api, Route(:PATCH, "/guilds/{guild_id}/welcome-screen"), snowflake(guild);
            body=kwargs, into=WelcomeScreen, reason)
end

"""
    get_guild_onboarding(api, guild_id) -> GuildOnboarding

[Docs](https://docs.discord.com/developers/resources/guild#get-guild-onboarding)
"""
get_guild_onboarding(api::API, guild::SnowflakeLike) =
    request(api, Route(:GET, "/guilds/{guild_id}/onboarding"), snowflake(guild);
            into=GuildOnboarding)

"""
    modify_guild_onboarding(api, guild_id; prompts, default_channel_ids, enabled, mode) -> GuildOnboarding

[Docs](https://docs.discord.com/developers/resources/guild#modify-guild-onboarding)
"""
function modify_guild_onboarding(api::API, guild::SnowflakeLike; reason=nothing, kwargs...)
    request(api, Route(:PUT, "/guilds/{guild_id}/onboarding"), snowflake(guild);
            body=kwargs, into=GuildOnboarding, reason)
end
