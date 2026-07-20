# https://docs.discord.com/developers/resources/guild-template

export GuildTemplate

"""
    GuildTemplate

A shareable snapshot of a guild that new guilds can be created from.
`serialized_source_guild` is a partial [`Guild`](@ref) with placeholder integer IDs.
"""
@discord_object struct GuildTemplate
    code::String
    name::String
    description::Nullable{String}
    usage_count::Int
    creator_id::Snowflake
    creator::User
    created_at::DateTime
    updated_at::DateTime
    source_guild_id::Snowflake
    serialized_source_guild::Guild
    is_dirty::Nullable{Bool}
end
