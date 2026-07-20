# The pieces of the interaction model that message payloads embed; split out
# so message.jl can load first.
# https://docs.discord.com/developers/interactions/receiving-and-responding

export InteractionType, InteractionTypes, ResolvedData, MessageInteraction

@discord_enum InteractionType UInt8 begin
    PING = 1
    APPLICATION_COMMAND = 2
    MESSAGE_COMPONENT = 3
    APPLICATION_COMMAND_AUTOCOMPLETE = 4
    MODAL_SUBMIT = 5
end

"""
    ResolvedData

Full objects for the IDs an interaction references. Members are partial
(no `user`, `deaf`, or `mute`), channels carry only their core fields.
"""
@discord_object struct ResolvedData
    users::Optional{Dict{Snowflake,User}}
    members::Optional{Dict{Snowflake,GuildMember}}
    roles::Optional{Dict{Snowflake,Role}}
    channels::Optional{Dict{Snowflake,DiscordChannel}}
    messages::Optional{Dict{Snowflake,Any}}  # Message and ResolvedData are mutually recursive; these stay raw
    attachments::Optional{Dict{Snowflake,Attachment}}
end

"""
    MessageInteraction

The interaction a message was sent in response to. Deprecated by Discord in
favor of [`MessageInteractionMetadata`](@ref).
"""
@discord_object struct MessageInteraction
    id::Snowflake
    type::InteractionType
    name::String
    user::User
    member::Optional{GuildMember}
end
