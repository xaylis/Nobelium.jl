# https://docs.discord.com/developers/resources/invite

export Invite, InviteStageInstance, InviteType, InviteTypes,
    InviteTargetType, InviteTargetTypes, GuildInviteFlags, GuildInviteFlag

@discord_enum InviteType UInt8 begin
    GUILD = 0
    GROUP_DM = 1
    FRIEND = 2
end

@discord_enum InviteTargetType UInt8 begin
    STREAM = 1
    EMBEDDED_APPLICATION = 2
end

@discord_flags GuildInviteFlags UInt32 :number begin
    is_guest_invite = 1 << 0
end

"""
    InviteStageInstance

Stage details on an invite to a Stage channel. Deprecated by Discord.
"""
@discord_object struct InviteStageInstance
    members::Vector{GuildMember}
    participant_count::Int
    speaker_count::Int
    topic::String
end

"""
    Invite

An invite to a guild or group DM channel. The metadata fields (`uses`,
`max_uses`, `max_age`, `temporary`, `created_at`) are only present on invites
fetched from a guild or channel's invite list.
"""
@discord_object struct Invite
    type::InviteType
    code::String
    guild::Optional{Guild}
    channel::Nullable{DiscordChannel}
    inviter::Optional{User}
    target_type::Optional{InviteTargetType}
    target_user::Optional{User}
    target_application::Optional{Application}
    approximate_presence_count::Optional{Int}
    approximate_member_count::Optional{Int}
    expires_at::OptionalNullable{DateTime}
    guild_scheduled_event::Optional{GuildScheduledEvent}
    flags::Optional{GuildInviteFlags}
    roles::Optional{Vector{Role}}
    uses::Optional{Int}
    max_uses::Optional{Int}
    max_age::Optional{Int}
    temporary::Optional{Bool}
    created_at::Optional{DateTime}
end
