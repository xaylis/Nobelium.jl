# https://docs.discord.com/developers/events/gateway#get-gateway

export SessionStartLimit, GatewayBotInfo, get_gateway, get_gateway_bot

"""
    SessionStartLimit

How many gateway sessions the bot may start: `reset_after` is in milliseconds,
`max_concurrency` the number of `IDENTIFY`s allowed per 5-second window.
"""
@discord_object struct SessionStartLimit
    total::Int
    remaining::Int
    reset_after::Int
    max_concurrency::Int
end

@discord_object struct GatewayBotInfo
    url::String
    shards::Int
    session_start_limit::SessionStartLimit
end

"""
    get_gateway(api) -> JSON3.Object

The gateway WSS URL, as `{"url": ...}`. Requires no authentication.
[Docs](https://docs.discord.com/developers/events/gateway#get-gateway)
"""
get_gateway(api::API) =
    request(api, Route(:GET, "/gateway"); into=Any, auth=:none)

"""
    get_gateway_bot(api) -> GatewayBotInfo

The gateway URL plus the advised shard count and session start limit.
[Docs](https://docs.discord.com/developers/events/gateway#get-gateway-bot)
"""
get_gateway_bot(api::API) =
    request(api, Route(:GET, "/gateway/bot"); into=GatewayBotInfo)
