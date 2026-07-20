# https://docs.discord.com/developers/resources/application
# https://docs.discord.com/developers/topics/teams
# https://docs.discord.com/developers/resources/application-role-connection-metadata

export Application, ApplicationFlags, ApplicationFlag, ApplicationIntegrationType,
    ApplicationIntegrationTypes, ApplicationEventWebhookStatusType,
    ApplicationEventWebhookStatusTypes, InstallParams,
    ApplicationIntegrationTypeConfiguration, ActivityInstance, ActivityLocation,
    Team, TeamMember, MembershipState, MembershipStates,
    ApplicationRoleConnectionMetadata, ApplicationRoleConnectionMetadataType,
    ApplicationRoleConnectionMetadataTypes

@discord_flags ApplicationFlags UInt64 :number begin
    application_auto_moderation_rule_create_badge = 1 << 6
    gateway_presence = 1 << 12
    gateway_presence_limited = 1 << 13
    gateway_guild_members = 1 << 14
    gateway_guild_members_limited = 1 << 15
    verification_pending_guild_limit = 1 << 16
    embedded = 1 << 17
    gateway_message_content = 1 << 18
    gateway_message_content_limited = 1 << 19
    application_command_badge = 1 << 23
end

@discord_enum ApplicationIntegrationType UInt8 begin
    GUILD_INSTALL = 0
    USER_INSTALL = 1
end

@discord_enum ApplicationEventWebhookStatusType UInt8 begin
    DISABLED = 1
    ENABLED = 2
    DISABLED_BY_DISCORD = 3
end

@discord_enum MembershipState UInt8 begin
    INVITED = 1
    ACCEPTED = 2
end

@discord_object struct InstallParams
    scopes::Vector{String}
    permissions::Permissions
end

@discord_object struct ApplicationIntegrationTypeConfiguration
    oauth2_install_params::Optional{InstallParams}
end

# The generic pipeline doesn't rebuild Dicts with object values; do the
# integration-types config by hand.
_reconstruct(::Type{Dict{String,ApplicationIntegrationTypeConfiguration}}, v) =
    Dict{String,ApplicationIntegrationTypeConfiguration}(
        string(k) => _reconstruct(ApplicationIntegrationTypeConfiguration, x) for (k, x) in pairs(v))

"""
    TeamMember

A member of a `Team`. `role` is `"admin"`, `"developer"`, or
`"read_only"`; the team owner is identified by `Team.owner_user_id` instead.
"""
@discord_object struct TeamMember
    membership_state::MembershipState
    team_id::Snowflake
    user::User
    role::String
end

@discord_object struct Team
    icon::Nullable{String}
    id::Snowflake
    members::Vector{TeamMember}
    name::String
    owner_user_id::Snowflake
end

"""
    Application

A Discord application. Many contexts (OAuth2, message metadata) carry partial
applications with most fields absent.
"""
@discord_object struct Application
    id::Snowflake
    name::Optional{String}
    icon::OptionalNullable{String}
    description::Optional{String}
    rpc_origins::Optional{Vector{String}}
    bot_public::Optional{Bool}
    bot_require_code_grant::Optional{Bool}
    bot::Optional{User}
    terms_of_service_url::Optional{String}
    privacy_policy_url::Optional{String}
    owner::Optional{User}
    verify_key::Optional{String}
    team::OptionalNullable{Team}
    guild_id::Optional{Snowflake}
    guild::Optional{Guild}
    primary_sku_id::Optional{Snowflake}
    slug::Optional{String}
    cover_image::Optional{String}
    flags::Optional{ApplicationFlags}
    approximate_guild_count::Optional{Int}
    approximate_user_install_count::Optional{Int}
    approximate_user_authorization_count::Optional{Int}
    redirect_uris::Optional{Vector{String}}
    interactions_endpoint_url::OptionalNullable{String}
    role_connections_verification_url::OptionalNullable{String}
    event_webhooks_url::OptionalNullable{String}
    event_webhooks_status::Optional{ApplicationEventWebhookStatusType}
    event_webhooks_types::Optional{Vector{String}}
    tags::Optional{Vector{String}}
    install_params::Optional{InstallParams}
    integration_types_config::Optional{Dict{String,ApplicationIntegrationTypeConfiguration}}
    custom_install_url::Optional{String}
end

"""
    ActivityLocation

Where an activity instance is running: `kind` is `"gc"` for a guild channel or
`"pc"` for a private channel.
"""
@discord_object struct ActivityLocation
    id::String
    kind::String
    channel_id::Snowflake
    guild_id::OptionalNullable{Snowflake}
end

@discord_object struct ActivityInstance
    application_id::Snowflake
    instance_id::String
    launch_id::Snowflake
    location::ActivityLocation
    users::Vector{Snowflake}
end

@discord_enum ApplicationRoleConnectionMetadataType UInt8 begin
    INTEGER_LESS_THAN_OR_EQUAL = 1
    INTEGER_GREATER_THAN_OR_EQUAL = 2
    INTEGER_EQUAL = 3
    INTEGER_NOT_EQUAL = 4
    DATETIME_LESS_THAN_OR_EQUAL = 5
    DATETIME_GREATER_THAN_OR_EQUAL = 6
    BOOLEAN_EQUAL = 7
    BOOLEAN_NOT_EQUAL = 8
end

"""
    ApplicationRoleConnectionMetadata

One metadata field an application exposes for role connections; `key` is what
users' [`ApplicationRoleConnection`](@ref) records are matched against.
"""
@discord_object struct ApplicationRoleConnectionMetadata
    type::ApplicationRoleConnectionMetadataType
    key::String
    name::String
    name_localizations::Optional{Dict{String,String}}
    description::String
    description_localizations::Optional{Dict{String,String}}
end
