# https://docs.discord.com/developers/resources/webhook

export create_webhook, get_channel_webhooks, get_guild_webhooks, get_webhook,
    get_webhook_with_token, modify_webhook, modify_webhook_with_token,
    delete_webhook, delete_webhook_with_token, execute_webhook,
    execute_slack_compatible_webhook, execute_github_compatible_webhook,
    get_webhook_message, edit_webhook_message, delete_webhook_message

"""
    create_webhook(api, channel_id; name, avatar, reason) -> Webhook

Requires the `MANAGE_WEBHOOKS` permission.
[Docs](https://docs.discord.com/developers/resources/webhook#create-webhook)
"""
function create_webhook(api::API, channel::SnowflakeLike; reason=nothing, kwargs...)
    request(api, Route(:POST, "/channels/{channel_id}/webhooks"), snowflake(channel);
            body=kwargs, into=Webhook, reason)
end

"""
    get_channel_webhooks(api, channel_id) -> Vector{Webhook}

[Docs](https://docs.discord.com/developers/resources/webhook#get-channel-webhooks)
"""
get_channel_webhooks(api::API, channel::SnowflakeLike) =
    request(api, Route(:GET, "/channels/{channel_id}/webhooks"), snowflake(channel);
            into=Vector{Webhook})

"""
    get_guild_webhooks(api, guild_id) -> Vector{Webhook}

[Docs](https://docs.discord.com/developers/resources/webhook#get-guild-webhooks)
"""
get_guild_webhooks(api::API, guild::SnowflakeLike) =
    request(api, Route(:GET, "/guilds/{guild_id}/webhooks"), snowflake(guild);
            into=Vector{Webhook})

"""
    get_webhook(api, webhook_id) -> Webhook

[Docs](https://docs.discord.com/developers/resources/webhook#get-webhook)
"""
get_webhook(api::API, webhook::SnowflakeLike) =
    request(api, Route(:GET, "/webhooks/{webhook_id}"), snowflake(webhook); into=Webhook)

"""
    get_webhook_with_token(api, webhook_id, token) -> Webhook

Like [`get_webhook`](@ref) but authenticated by the webhook token; the result
carries no `user` field.
[Docs](https://docs.discord.com/developers/resources/webhook#get-webhook-with-token)
"""
get_webhook_with_token(api::API, webhook::SnowflakeLike, token::AbstractString) =
    request(api, Route(:GET, "/webhooks/{webhook_id}/{webhook_token}"),
            snowflake(webhook), token; into=Webhook, auth=:none)

"""
    modify_webhook(api, webhook_id; name, avatar, channel_id, reason) -> Webhook

[Docs](https://docs.discord.com/developers/resources/webhook#modify-webhook)
"""
function modify_webhook(api::API, webhook::SnowflakeLike; reason=nothing, kwargs...)
    request(api, Route(:PATCH, "/webhooks/{webhook_id}"), snowflake(webhook);
            body=kwargs, into=Webhook, reason)
end

"""
    modify_webhook_with_token(api, webhook_id, token; name, avatar) -> Webhook

Like [`modify_webhook`](@ref) but authenticated by the webhook token;
`channel_id` is not accepted.
[Docs](https://docs.discord.com/developers/resources/webhook#modify-webhook-with-token)
"""
modify_webhook_with_token(api::API, webhook::SnowflakeLike, token::AbstractString; kwargs...) =
    request(api, Route(:PATCH, "/webhooks/{webhook_id}/{webhook_token}"),
            snowflake(webhook), token; body=kwargs, into=Webhook, auth=:none)

"""
    delete_webhook(api, webhook_id; reason)

[Docs](https://docs.discord.com/developers/resources/webhook#delete-webhook)
"""
function delete_webhook(api::API, webhook::SnowflakeLike; reason=nothing)
    request(api, Route(:DELETE, "/webhooks/{webhook_id}"), snowflake(webhook); reason)
end

"""
    delete_webhook_with_token(api, webhook_id, token)

[Docs](https://docs.discord.com/developers/resources/webhook#delete-webhook-with-token)
"""
delete_webhook_with_token(api::API, webhook::SnowflakeLike, token::AbstractString) =
    request(api, Route(:DELETE, "/webhooks/{webhook_id}/{webhook_token}"),
            snowflake(webhook), token; auth=:none)

"""
    execute_webhook(api, webhook_id, token; content, embeds, files, wait, thread_id, ...) -> Message

Post a message through the webhook. At least one of `content`, `embeds`,
`components`, `files`, or `poll` is required. Returns the created
[`Message`](@ref) only when `wait=true`; otherwise `nothing`.
[Docs](https://docs.discord.com/developers/resources/webhook#execute-webhook)
"""
function execute_webhook(api::API, webhook::SnowflakeLike, token::AbstractString;
                         wait=missing, thread_id=missing, with_components=missing,
                         files=nothing, kwargs...)
    request(api, Route(:POST, "/webhooks/{webhook_id}/{webhook_token}"),
            snowflake(webhook), token;
            body=kwargs, query=(; wait, thread_id, with_components), files,
            into=Message, auth=:none)
end

"""
    execute_slack_compatible_webhook(api, webhook_id, token; wait, thread_id, kwargs...)

Post a Slack-format payload (`text`, `attachments`, ...) through the webhook.

These compatibility endpoints answer in Slack's own dialect, not JSON: with
`wait=true` the body is the bare string `"ok"`, and otherwise there is no body
at all. The raw body is returned as a `String` (or `nothing` for an empty one).
[Docs](https://docs.discord.com/developers/resources/webhook#execute-slackcompatible-webhook)
"""
function execute_slack_compatible_webhook(api::API, webhook::SnowflakeLike, token::AbstractString;
                                          wait=missing, thread_id=missing, kwargs...)
    request(api, Route(:POST, "/webhooks/{webhook_id}/{webhook_token}/slack"),
            snowflake(webhook), token;
            body=kwargs, query=(; wait, thread_id), into=String, auth=:none)
end

"""
    execute_github_compatible_webhook(api, webhook_id, token; wait, thread_id, kwargs...)

Post a GitHub-format webhook event payload through the webhook.

Like the Slack endpoint above, the response is not JSON - it is empty on
success, so this returns `nothing`.
[Docs](https://docs.discord.com/developers/resources/webhook#execute-githubcompatible-webhook)
"""
function execute_github_compatible_webhook(api::API, webhook::SnowflakeLike, token::AbstractString;
                                           wait=missing, thread_id=missing, kwargs...)
    request(api, Route(:POST, "/webhooks/{webhook_id}/{webhook_token}/github"),
            snowflake(webhook), token;
            body=kwargs, query=(; wait, thread_id), into=String, auth=:none)
end

"""
    get_webhook_message(api, webhook_id, token, message_id; thread_id) -> Message

[Docs](https://docs.discord.com/developers/resources/webhook#get-webhook-message)
"""
function get_webhook_message(api::API, webhook::SnowflakeLike, token::AbstractString,
                             message::SnowflakeLike; thread_id=missing)
    request(api, Route(:GET, "/webhooks/{webhook_id}/{webhook_token}/messages/{message_id}"),
            snowflake(webhook), token, snowflake(message);
            query=(; thread_id), into=Message, auth=:none)
end

"""
    edit_webhook_message(api, webhook_id, token, message_id; content, embeds, files, thread_id, ...) -> Message

[Docs](https://docs.discord.com/developers/resources/webhook#edit-webhook-message)
"""
function edit_webhook_message(api::API, webhook::SnowflakeLike, token::AbstractString,
                              message::SnowflakeLike; thread_id=missing,
                              with_components=missing, files=nothing, kwargs...)
    request(api, Route(:PATCH, "/webhooks/{webhook_id}/{webhook_token}/messages/{message_id}"),
            snowflake(webhook), token, snowflake(message);
            body=kwargs, query=(; thread_id, with_components), files,
            into=Message, auth=:none)
end

"""
    delete_webhook_message(api, webhook_id, token, message_id; thread_id)

[Docs](https://docs.discord.com/developers/resources/webhook#delete-webhook-message)
"""
function delete_webhook_message(api::API, webhook::SnowflakeLike, token::AbstractString,
                                message::SnowflakeLike; thread_id=missing)
    request(api, Route(:DELETE, "/webhooks/{webhook_id}/{webhook_token}/messages/{message_id}"),
            snowflake(webhook), token, snowflake(message); query=(; thread_id), auth=:none)
end
