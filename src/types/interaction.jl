# https://docs.discord.com/developers/interactions/receiving-and-responding
# https://docs.discord.com/developers/interactions/application-commands

export Interaction, InteractionContextType,
    InteractionContextTypes, InteractionData, ApplicationCommandInteractionDataOption,
    InteractionCallbackType, InteractionCallbackTypes,
    InteractionCallbackResponse, InteractionCallback, InteractionCallbackActivityInstance,
    InteractionCallbackResource, ApplicationCommand, ApplicationCommandType,
    ApplicationCommandTypes, ApplicationCommandOption, ApplicationCommandOptionType,
    ApplicationCommandOptionTypes, ApplicationCommandOptionChoice,
    GuildApplicationCommandPermissions, ApplicationCommandPermissions,
    ApplicationCommandPermissionType, ApplicationCommandPermissionTypes,
    EntryPointCommandHandlerType, EntryPointCommandHandlerTypes

@discord_enum InteractionContextType UInt8 begin
    GUILD = 0
    BOT_DM = 1
    PRIVATE_CHANNEL = 2
end

@discord_enum ApplicationCommandType UInt8 begin
    CHAT_INPUT = 1
    USER = 2
    MESSAGE = 3
    PRIMARY_ENTRY_POINT = 4
end

@discord_enum ApplicationCommandOptionType UInt8 begin
    SUB_COMMAND = 1
    SUB_COMMAND_GROUP = 2
    STRING = 3
    INTEGER = 4
    BOOLEAN = 5
    USER = 6
    CHANNEL = 7
    ROLE = 8
    MENTIONABLE = 9
    NUMBER = 10
    ATTACHMENT = 11
end

@discord_enum ApplicationCommandPermissionType UInt8 begin
    ROLE = 1
    USER = 2
    CHANNEL = 3
end

@discord_enum EntryPointCommandHandlerType UInt8 begin
    APP_HANDLER = 1
    DISCORD_LAUNCH_ACTIVITY = 2
end

@discord_enum InteractionCallbackType UInt8 begin
    PONG = 1
    CHANNEL_MESSAGE_WITH_SOURCE = 4
    DEFERRED_CHANNEL_MESSAGE_WITH_SOURCE = 5
    DEFERRED_UPDATE_MESSAGE = 6
    UPDATE_MESSAGE = 7
    APPLICATION_COMMAND_AUTOCOMPLETE_RESULT = 8
    MODAL = 9
    PREMIUM_REQUIRED = 10
    LAUNCH_ACTIVITY = 12
end

@discord_object struct ApplicationCommandOptionChoice
    name::String
    name_localizations::OptionalNullable{Dict{String,String}}
    value::Union{String,Int,Float64,Bool}
end

@discord_object struct ApplicationCommandOption
    type::ApplicationCommandOptionType
    name::String
    name_localizations::OptionalNullable{Dict{String,String}}
    description::String
    description_localizations::OptionalNullable{Dict{String,String}}
    required::Optional{Bool}
    choices::Optional{Vector{ApplicationCommandOptionChoice}}
    options::Optional{Vector{ApplicationCommandOption}}
    channel_types::Optional{Vector{ChannelType}}
    min_value::Optional{Number}
    max_value::Optional{Number}
    min_length::Optional{Int}
    max_length::Optional{Int}
    autocomplete::Optional{Bool}
end

"""
    ApplicationCommand

A slash, user, message, or entry-point command an application has registered
globally or in a guild.
"""
@discord_object struct ApplicationCommand
    id::Snowflake
    type::Optional{ApplicationCommandType}
    application_id::Snowflake
    guild_id::Optional{Snowflake}
    name::String
    name_localizations::OptionalNullable{Dict{String,String}}
    description::String
    description_localizations::OptionalNullable{Dict{String,String}}
    options::Optional{Vector{ApplicationCommandOption}}
    default_member_permissions::Nullable{Permissions}
    dm_permission::Optional{Bool}
    default_permission::OptionalNullable{Bool}
    nsfw::Optional{Bool}
    integration_types::Optional{Vector{ApplicationIntegrationType}}
    contexts::OptionalNullable{Vector{InteractionContextType}}
    version::Snowflake
    handler::Optional{EntryPointCommandHandlerType}
end

@discord_object struct ApplicationCommandPermissions
    id::Snowflake
    type::ApplicationCommandPermissionType
    permission::Bool
end

@discord_object struct GuildApplicationCommandPermissions
    id::Snowflake
    application_id::Snowflake
    guild_id::Snowflake
    permissions::Vector{ApplicationCommandPermissions}
end

# Resolved maps arrive keyed by snowflake strings, and constructfrom can't
# build our CustomStruct values, so rebuild these dictionaries by hand.
_reconstruct(::Type{Dict{Snowflake,V}}, obj) where {V} =
    Dict{Snowflake,V}(Snowflake(String(k)) => _reconstruct(V, v) for (k, v) in pairs(obj))


@discord_object struct ApplicationCommandInteractionDataOption
    name::String
    type::ApplicationCommandOptionType
    value::Optional{Union{String,Int,Float64,Bool}}
    options::Optional{Vector{ApplicationCommandInteractionDataOption}}
    focused::Optional{Bool}
end

"""
    InteractionData

The `data` payload of an [`Interaction`](@ref). Discord documents a separate
shape per interaction type; this struct merges them, so which fields are set
depends on `Interaction.type`.
"""
@discord_object struct InteractionData
    # application command (and autocomplete)
    id::Optional{Snowflake}
    name::Optional{String}
    type::Optional{ApplicationCommandType}
    resolved::Optional{ResolvedData}
    options::Optional{Vector{ApplicationCommandInteractionDataOption}}
    guild_id::Optional{Snowflake}
    target_id::Optional{Snowflake}
    # message component (custom_id is shared with modal submit)
    custom_id::Optional{String}
    component_type::Optional{ComponentType}
    values::Optional{Vector{String}}
    # modal submit
    components::Optional{Vector{Component}}
end

"""
    Interaction

A user's invocation of an application command, message component, or modal.
`member` is set in guilds, `user` in DMs; `data` is absent only for pings.
"""
@discord_object struct Interaction
    id::Snowflake
    application_id::Snowflake
    type::InteractionType
    data::Optional{InteractionData}
    guild::Optional{Guild}
    guild_id::Optional{Snowflake}
    channel::Optional{DiscordChannel}
    channel_id::Optional{Snowflake}
    member::Optional{GuildMember}
    user::Optional{User}
    token::String
    version::Int
    message::Optional{Message}
    app_permissions::Permissions
    locale::Optional{String}
    guild_locale::Optional{String}
    entitlements::Vector{Entitlement}
    authorizing_integration_owners::Dict{String,Snowflake}
    context::Optional{InteractionContextType}
    attachment_size_limit::Int
end


@discord_object struct InteractionCallback
    id::Snowflake
    type::InteractionType
    activity_instance_id::Optional{String}
    response_message_id::Optional{Snowflake}
    response_message_loading::Optional{Bool}
    response_message_ephemeral::Optional{Bool}
end

@discord_object struct InteractionCallbackActivityInstance
    id::String
end

@discord_object struct InteractionCallbackResource
    type::InteractionCallbackType
    activity_instance::Optional{InteractionCallbackActivityInstance}
    message::Optional{Message}
end

"""
    InteractionCallbackResponse

What [`create_interaction_response`](@ref) returns when called with
`with_response=true`.
"""
@discord_object struct InteractionCallbackResponse
    interaction::InteractionCallback
    resource::Optional{InteractionCallbackResource}
end
