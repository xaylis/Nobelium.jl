"""
    Nobelium

A Discord API wrapper for Julia covering the full REST API, gateway, and voice.

The two entry points most bots need are [`Client`](@ref) for connecting to the
gateway and the REST functions (`create_message`, `get_guild`, ...) which can be
used either through a `Client` or a standalone [`API`](@ref).
"""
module Nobelium

using Dates
using Logging
using Random
using Sockets

using HTTP
using JSON3
using StructTypes
using URIs

include("snowflake.jl")
include("json.jl")
include("errors.jl")
include("permissions.jl")
include("intents.jl")
include("formatting.jl")
include("rest/routes.jl")
include("rest/ratelimit.jl")
include("rest/api.jl")

include("types/user.jl")
include("types/role.jl")
include("types/emoji.jl")
include("types/sticker.jl")
include("types/member.jl")
include("types/channel.jl")
include("types/guild.jl")
include("types/onboarding.jl")
include("types/voice.jl")
include("types/stage_instance.jl")
include("types/guild_scheduled_event.jl")
include("types/guild_template.jl")
include("types/application.jl")
include("types/webhook.jl")
include("types/invite.jl")
include("types/embed.jl")
include("types/component.jl")
include("types/poll.jl")
include("types/automod.jl")
include("types/monetization.jl")
include("types/soundboard.jl")
include("types/lobby.jl")
include("types/attachment.jl")
include("types/interaction_core.jl")
include("types/message.jl")
include("types/interaction.jl")
include("types/audit_log.jl")
include("types/presence.jl")

include("rest/endpoints/user.jl")
include("rest/endpoints/emoji.jl")
include("rest/endpoints/sticker.jl")
include("rest/endpoints/guild.jl")
include("rest/endpoints/channel.jl")
include("rest/endpoints/voice_rest.jl")
include("rest/endpoints/stage_instance.jl")
include("rest/endpoints/guild_scheduled_event.jl")
include("rest/endpoints/guild_template.jl")
include("rest/endpoints/application.jl")
include("rest/endpoints/oauth2.jl")
include("rest/endpoints/gateway_meta.jl")
include("rest/endpoints/webhook.jl")
include("rest/endpoints/invite.jl")
include("rest/endpoints/poll.jl")
include("rest/endpoints/message.jl")
include("rest/endpoints/auto_moderation.jl")
include("rest/endpoints/audit_log.jl")
include("rest/endpoints/monetization.jl")
include("rest/endpoints/soundboard.jl")
include("rest/endpoints/lobby.jl")
include("rest/endpoints/application_command.jl")
include("rest/endpoints/interaction.jl")

include("gateway/dispatch.jl")
include("gateway/events_base.jl")
include("gateway/events.jl")
include("gateway/shard.jl")

include("cache.jl")
include("client.jl")

include("interactions/commands.jl")
include("interactions/components.jl")
include("interactions/responses.jl")

include("voice/crypto.jl")
include("voice/audio.jl")
include("voice/voice.jl")

include("precompile.jl")

export API, DiscordFile
export Snowflake, snowflake, timestamp
export Optional, Nullable, OptionalNullable, DiscordObject
export NobeliumError, APIError, RateLimitedError, GatewayClosedError
export Permissions, Permission, has_permission
export Intents, Intent
export mention_user, mention_channel, mention_role, mention_command, emoji_tag,
    discord_timestamp, inline_code, code_block, escape_markdown

end # module
