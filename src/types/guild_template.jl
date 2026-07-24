# https://docs.discord.com/developers/resources/guild-template

export GuildTemplate

"""
    GuildTemplate

A shareable snapshot of a guild that new guilds can be created from.
`serialized_source_guild` has no `id` and its roles and channels carry
placeholder integer IDs and a subset of their usual fields, so it is left
untyped rather than parsed as a [`Guild`](@ref).
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
    serialized_source_guild::Any
    is_dirty::Nullable{Bool}
end
