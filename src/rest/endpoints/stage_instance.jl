# https://docs.discord.com/developers/resources/stage-instance

export create_stage_instance, get_stage_instance, modify_stage_instance,
    delete_stage_instance

"""
    create_stage_instance(api; channel_id, topic, privacy_level, send_start_notification, guild_scheduled_event_id, reason) -> StageInstance

Start a Stage in a Stage channel.
[Docs](https://docs.discord.com/developers/resources/stage-instance#create-stage-instance)
"""
function create_stage_instance(api::API; reason=nothing, kwargs...)
    request(api, Route(:POST, "/stage-instances"); body=kwargs, into=StageInstance, reason)
end

"""
    get_stage_instance(api, channel_id) -> StageInstance

[Docs](https://docs.discord.com/developers/resources/stage-instance#get-stage-instance)
"""
get_stage_instance(api::API, channel::SnowflakeLike) =
    request(api, Route(:GET, "/stage-instances/{channel_id}"), snowflake(channel);
            into=StageInstance)

"""
    modify_stage_instance(api, channel_id; topic, privacy_level, reason) -> StageInstance

[Docs](https://docs.discord.com/developers/resources/stage-instance#modify-stage-instance)
"""
function modify_stage_instance(api::API, channel::SnowflakeLike; reason=nothing, kwargs...)
    request(api, Route(:PATCH, "/stage-instances/{channel_id}"), snowflake(channel);
            body=kwargs, into=StageInstance, reason)
end

"""
    delete_stage_instance(api, channel_id; reason)

[Docs](https://docs.discord.com/developers/resources/stage-instance#delete-stage-instance)
"""
function delete_stage_instance(api::API, channel::SnowflakeLike; reason=nothing)
    request(api, Route(:DELETE, "/stage-instances/{channel_id}"), snowflake(channel); reason)
end
