# https://docs.discord.com/developers/resources/webhook

export Webhook, WebhookType, WebhookTypes

@discord_enum WebhookType UInt8 begin
    INCOMING = 1
    CHANNEL_FOLLOWER = 2
    APPLICATION = 3
end

"""
    Webhook

A low-effort way to post messages to a channel. `token` is only returned for
incoming webhooks, and `user` is absent when fetched with the webhook token.
"""
@discord_object struct Webhook
    id::Snowflake
    type::WebhookType
    guild_id::OptionalNullable{Snowflake}
    channel_id::Nullable{Snowflake}
    user::Optional{User}
    name::Nullable{String}
    avatar::Nullable{String}
    token::Optional{String}
    application_id::Nullable{Snowflake}
    source_guild::Optional{Guild}
    source_channel::Optional{DiscordChannel}
    url::Optional{String}
end
