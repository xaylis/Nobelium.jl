# https://docs.discord.com/developers/resources/audit-log

export get_guild_audit_log

"""
    get_guild_audit_log(api, guild_id; user_id, action_type, before, after, limit) -> AuditLog

Requires the `VIEW_AUDIT_LOG` permission. Entries are newest-first unless `after` is
given, which flips the order to oldest-first.
[Docs](https://docs.discord.com/developers/resources/audit-log#get-guild-audit-log)
"""
get_guild_audit_log(api::API, guild::SnowflakeLike; kwargs...) =
    request(api, Route(:GET, "/guilds/{guild_id}/audit-logs"), snowflake(guild);
            query=kwargs, into=AuditLog)
