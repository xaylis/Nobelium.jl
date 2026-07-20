# https://docs.discord.com/developers/resources/lobby

export Lobby, LobbyMember, LobbyMemberFlags, LobbyMemberFlag

@discord_flags LobbyMemberFlags UInt8 :number begin
    can_link_lobby = 1 << 0
end

"""
    LobbyMember

A user's membership in a [`Lobby`](@ref), with arbitrary application-defined
`metadata`.
"""
@discord_object struct LobbyMember
    id::Snowflake
    metadata::OptionalNullable{Dict{String,String}}
    flags::Optional{LobbyMemberFlags}
end

"""
    Lobby

An ephemeral space, created via the Discord Social SDK, that a set of users
can join and chat in. `linked_channel` is set when a guild channel has been
linked for the lobby's messages to relay into.
"""
@discord_object struct Lobby
    id::Snowflake
    application_id::Snowflake
    metadata::OptionalNullable{Dict{String,String}}
    members::Vector{LobbyMember}
    linked_channel::Optional{DiscordChannel}
end
