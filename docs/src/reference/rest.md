# REST endpoints

Every Discord REST endpoint, one function each, grouped by resource. All take
an `API` (or `client.api`) first.

```@autodocs
Modules = [Nobelium]
Pages = ["rest/endpoints/user.jl", "rest/endpoints/emoji.jl", "rest/endpoints/sticker.jl",
         "rest/endpoints/guild.jl", "rest/endpoints/channel.jl", "rest/endpoints/message.jl",
         "rest/endpoints/poll.jl", "rest/endpoints/voice_rest.jl",
         "rest/endpoints/stage_instance.jl", "rest/endpoints/guild_scheduled_event.jl",
         "rest/endpoints/guild_template.jl", "rest/endpoints/application.jl",
         "rest/endpoints/oauth2.jl", "rest/endpoints/gateway_meta.jl",
         "rest/endpoints/webhook.jl", "rest/endpoints/invite.jl",
         "rest/endpoints/auto_moderation.jl", "rest/endpoints/audit_log.jl",
         "rest/endpoints/monetization.jl", "rest/endpoints/soundboard.jl",
         "rest/endpoints/lobby.jl", "rest/endpoints/application_command.jl",
         "rest/endpoints/interaction.jl", "interactions/commands.jl",
         "interactions/components.jl", "interactions/responses.jl"]
```
