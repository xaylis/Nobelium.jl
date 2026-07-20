# https://docs.discord.com/developers/resources/guild#guild-member-object

export GuildMember, GuildMemberFlags, GuildMemberFlag

@discord_flags GuildMemberFlags UInt64 :number begin
    did_rejoin = 1 << 0
    completed_onboarding = 1 << 1
    bypasses_verification = 1 << 2
    started_onboarding = 1 << 3
    is_guest = 1 << 4
    started_home_actions = 1 << 5
    completed_home_actions = 1 << 6
    automod_quarantined_username = 1 << 7
    dm_settings_upsell_acknowledged = 1 << 9
    automod_quarantined_guild_tag = 1 << 10
end

"""
    GuildMember

A user's membership in a guild. `user` is absent in message create/update
events; `permissions` only appears inside interactions.
"""
@discord_object struct GuildMember
    user::Optional{User}
    nick::OptionalNullable{String}
    avatar::OptionalNullable{String}
    banner::OptionalNullable{String}
    roles::Vector{Snowflake}
    joined_at::Nullable{DateTime}
    premium_since::OptionalNullable{DateTime}
    deaf::Bool
    mute::Bool
    flags::GuildMemberFlags
    pending::Optional{Bool}
    permissions::Optional{Permissions}
    communication_disabled_until::OptionalNullable{DateTime}
    avatar_decoration_data::OptionalNullable{AvatarDecorationData}
    collectibles::OptionalNullable{Any}
end
