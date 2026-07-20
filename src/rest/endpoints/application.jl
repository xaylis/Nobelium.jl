# https://docs.discord.com/developers/resources/application
# https://docs.discord.com/developers/resources/application-role-connection-metadata

export get_current_application, edit_current_application,
    get_application_activity_instance, get_application_role_connection_metadata_records,
    update_application_role_connection_metadata_records

"""
    get_current_application(api) -> Application

[Docs](https://docs.discord.com/developers/resources/application#get-current-application)
"""
get_current_application(api::API) =
    request(api, Route(:GET, "/applications/@me"); into=Application)

"""
    edit_current_application(api; description, icon, tags, install_params, flags, ...) -> Application

Update the bot's own application. Only bot tokens may set `flags`, and only
the gateway-limited bits.
[Docs](https://docs.discord.com/developers/resources/application#edit-current-application)
"""
edit_current_application(api::API; kwargs...) =
    request(api, Route(:PATCH, "/applications/@me"); body=kwargs, into=Application)

"""
    get_application_activity_instance(api, application_id, instance_id) -> ActivityInstance

[Docs](https://docs.discord.com/developers/resources/application#get-application-activity-instance)
"""
get_application_activity_instance(api::API, application::SnowflakeLike, instance_id::AbstractString) =
    request(api, Route(:GET, "/applications/{application_id}/activity-instances/{instance_id}"),
            snowflake(application), instance_id; into=ActivityInstance)

"""
    get_application_role_connection_metadata_records(api, application_id) -> Vector{ApplicationRoleConnectionMetadata}

[Docs](https://docs.discord.com/developers/resources/application-role-connection-metadata#get-application-role-connection-metadata-records)
"""
get_application_role_connection_metadata_records(api::API, application::SnowflakeLike) =
    request(api, Route(:GET, "/applications/{application_id}/role-connections/metadata"),
            snowflake(application); into=Vector{ApplicationRoleConnectionMetadata})

"""
    update_application_role_connection_metadata_records(api, application_id, records) -> Vector{ApplicationRoleConnectionMetadata}

Replace the application's metadata records (at most 5) with `records`, a vector
of [`ApplicationRoleConnectionMetadata`](@ref).
[Docs](https://docs.discord.com/developers/resources/application-role-connection-metadata#update-application-role-connection-metadata-records)
"""
update_application_role_connection_metadata_records(api::API, application::SnowflakeLike,
                                                    records::Vector{ApplicationRoleConnectionMetadata}) =
    request(api, Route(:PUT, "/applications/{application_id}/role-connections/metadata"),
            snowflake(application); body=records, into=Vector{ApplicationRoleConnectionMetadata})
