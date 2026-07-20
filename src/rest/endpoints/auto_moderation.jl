# https://docs.discord.com/developers/resources/auto-moderation

export list_auto_moderation_rules_for_guild, get_auto_moderation_rule,
    create_auto_moderation_rule, modify_auto_moderation_rule, delete_auto_moderation_rule

"""
    list_auto_moderation_rules_for_guild(api, guild_id) -> Vector{AutoModerationRule}

Requires the `MANAGE_GUILD` permission.
[Docs](https://docs.discord.com/developers/resources/auto-moderation#list-auto-moderation-rules-for-guild)
"""
list_auto_moderation_rules_for_guild(api::API, guild::SnowflakeLike) =
    request(api, Route(:GET, "/guilds/{guild_id}/auto-moderation/rules"), snowflake(guild);
            into=Vector{AutoModerationRule})

"""
    get_auto_moderation_rule(api, guild_id, rule_id) -> AutoModerationRule

[Docs](https://docs.discord.com/developers/resources/auto-moderation#get-auto-moderation-rule)
"""
get_auto_moderation_rule(api::API, guild::SnowflakeLike, rule::SnowflakeLike) =
    request(api, Route(:GET, "/guilds/{guild_id}/auto-moderation/rules/{auto_moderation_rule_id}"),
            snowflake(guild), snowflake(rule); into=AutoModerationRule)

"""
    create_auto_moderation_rule(api, guild_id; name, event_type, trigger_type, actions,
                                trigger_metadata, enabled, exempt_roles, exempt_channels,
                                reason) -> AutoModerationRule

Whether `trigger_metadata` is required depends on `trigger_type`.
[Docs](https://docs.discord.com/developers/resources/auto-moderation#create-auto-moderation-rule)
"""
function create_auto_moderation_rule(api::API, guild::SnowflakeLike; reason=nothing, kwargs...)
    request(api, Route(:POST, "/guilds/{guild_id}/auto-moderation/rules"), snowflake(guild);
            body=kwargs, into=AutoModerationRule, reason)
end

"""
    modify_auto_moderation_rule(api, guild_id, rule_id; name, event_type, trigger_metadata,
                                actions, enabled, exempt_roles, exempt_channels,
                                reason) -> AutoModerationRule

`trigger_type` cannot be changed after creation.
[Docs](https://docs.discord.com/developers/resources/auto-moderation#modify-auto-moderation-rule)
"""
function modify_auto_moderation_rule(api::API, guild::SnowflakeLike, rule::SnowflakeLike;
                                     reason=nothing, kwargs...)
    request(api, Route(:PATCH, "/guilds/{guild_id}/auto-moderation/rules/{auto_moderation_rule_id}"),
            snowflake(guild), snowflake(rule); body=kwargs, into=AutoModerationRule, reason)
end

"""
    delete_auto_moderation_rule(api, guild_id, rule_id; reason)

[Docs](https://docs.discord.com/developers/resources/auto-moderation#delete-auto-moderation-rule)
"""
function delete_auto_moderation_rule(api::API, guild::SnowflakeLike, rule::SnowflakeLike;
                                     reason=nothing)
    request(api, Route(:DELETE, "/guilds/{guild_id}/auto-moderation/rules/{auto_moderation_rule_id}"),
            snowflake(guild), snowflake(rule); reason)
end
