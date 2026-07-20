# https://docs.discord.com/developers/resources/guild-scheduled-event

export list_scheduled_events_for_guild, create_guild_scheduled_event,
    get_guild_scheduled_event, modify_guild_scheduled_event,
    delete_guild_scheduled_event, get_guild_scheduled_event_users

"""
    list_scheduled_events_for_guild(api, guild_id; with_user_count) -> Vector{GuildScheduledEvent}

[Docs](https://docs.discord.com/developers/resources/guild-scheduled-event#list-scheduled-events-for-guild)
"""
list_scheduled_events_for_guild(api::API, guild::SnowflakeLike; kwargs...) =
    request(api, Route(:GET, "/guilds/{guild_id}/scheduled-events"), snowflake(guild);
            query=kwargs, into=Vector{GuildScheduledEvent})

"""
    create_guild_scheduled_event(api, guild_id; name, privacy_level, scheduled_start_time, entity_type, ..., reason) -> GuildScheduledEvent

A guild can have at most 100 events with SCHEDULED or ACTIVE status.
[Docs](https://docs.discord.com/developers/resources/guild-scheduled-event#create-guild-scheduled-event)
"""
function create_guild_scheduled_event(api::API, guild::SnowflakeLike; reason=nothing, kwargs...)
    request(api, Route(:POST, "/guilds/{guild_id}/scheduled-events"), snowflake(guild);
            body=kwargs, into=GuildScheduledEvent, reason)
end

"""
    get_guild_scheduled_event(api, guild_id, event_id; with_user_count) -> GuildScheduledEvent

[Docs](https://docs.discord.com/developers/resources/guild-scheduled-event#get-guild-scheduled-event)
"""
get_guild_scheduled_event(api::API, guild::SnowflakeLike, event::SnowflakeLike; kwargs...) =
    request(api, Route(:GET, "/guilds/{guild_id}/scheduled-events/{guild_scheduled_event_id}"),
            snowflake(guild), snowflake(event); query=kwargs, into=GuildScheduledEvent)

"""
    modify_guild_scheduled_event(api, guild_id, event_id; status, name, ..., reason) -> GuildScheduledEvent

Also how events are started (`status=2`) and ended (`status=3`).
[Docs](https://docs.discord.com/developers/resources/guild-scheduled-event#modify-guild-scheduled-event)
"""
function modify_guild_scheduled_event(api::API, guild::SnowflakeLike, event::SnowflakeLike;
                                      reason=nothing, kwargs...)
    request(api, Route(:PATCH, "/guilds/{guild_id}/scheduled-events/{guild_scheduled_event_id}"),
            snowflake(guild), snowflake(event); body=kwargs, into=GuildScheduledEvent, reason)
end

"""
    delete_guild_scheduled_event(api, guild_id, event_id; reason)

[Docs](https://docs.discord.com/developers/resources/guild-scheduled-event#delete-guild-scheduled-event)
"""
function delete_guild_scheduled_event(api::API, guild::SnowflakeLike, event::SnowflakeLike;
                                      reason=nothing)
    request(api, Route(:DELETE, "/guilds/{guild_id}/scheduled-events/{guild_scheduled_event_id}"),
            snowflake(guild), snowflake(event); reason)
end

"""
    get_guild_scheduled_event_users(api, guild_id, event_id; limit, with_member, before, after) -> Vector{GuildScheduledEventUser}

Subscribers sorted ascending by user id, 100 per page.
[Docs](https://docs.discord.com/developers/resources/guild-scheduled-event#get-guild-scheduled-event-users)
"""
get_guild_scheduled_event_users(api::API, guild::SnowflakeLike, event::SnowflakeLike; kwargs...) =
    request(api, Route(:GET, "/guilds/{guild_id}/scheduled-events/{guild_scheduled_event_id}/users"),
            snowflake(guild), snowflake(event); query=kwargs, into=Vector{GuildScheduledEventUser})
