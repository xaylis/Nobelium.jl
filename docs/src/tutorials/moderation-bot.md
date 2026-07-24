# A moderation bot

A tour of the moderation surface: auto moderation rules, timeouts, audit-logged
actions, and the audit log itself.

```julia
using Nobelium, Dates

client = Client(ENV["DISCORD_TOKEN"];
                intents=Intent.default | Intent.message_content)
```

## Auto moderation rules

Let Discord do the filtering server-side:

```julia
on!(client, Ready) do c, ev
    for g in ev.guilds
        rules = list_auto_moderation_rules_for_guild(c.api, g.id)
        any(r -> r.name == "no invites", rules) && continue
        create_auto_moderation_rule(c.api, g.id;
            name="no invites",
            event_type=Int(AutoModerationEventTypes.MESSAGE_SEND.value),
            trigger_type=Int(AutoModerationTriggerTypes.KEYWORD.value),
            trigger_metadata=(regex_patterns=["discord\\.gg/\\w+"],),
            actions=[(type=Int(AutoModerationActionTypes.BLOCK_MESSAGE.value),)],
            enabled=true,
            reason="baseline moderation")
    end
end
```

When a rule fires you get an `AutoModerationActionExecution` event with the
matched content and the user involved.

## Timeouts and bans

Member mutations take `reason`, which lands in the audit log:

```julia
on!(client, MessageCreate) do c, ev
    m = ev.message
    (m.author.bot === true || ev.guild_id === missing) && return

    if occursin(r"free nitro"i, m.content)
        delete_message(c.api, m.channel_id, m.id; reason="scam phrase")
        modify_guild_member(c.api, ev.guild_id, m.author.id;
            communication_disabled_until=now(UTC) + Hour(1),
            reason="scam phrase — 1h timeout")
    end
end
```

Escalate with `create_guild_ban(api, guild, user; delete_message_seconds=86400,
reason=...)`, or `bulk_guild_ban` for raid cleanup.

## Watching the audit log

Every moderation action — yours, other bots', human mods' — streams in as
`GuildAuditLogEntryCreate`, and history is queryable:

```julia
on!(client, GuildAuditLogEntryCreate) do c, ev
    ev.entry.action_type == AuditLogEvents.MEMBER_BAN_ADD || return
    create_message(c.api, MOD_LOG_CHANNEL;
        content="🔨 ban: <@$(ev.entry.target_id)> by <@$(ev.entry.user_id))>")
end

log = get_guild_audit_log(client.api, guild_id;
                          action_type=Int(AuditLogEvents.MEMBER_KICK.value), limit=25)
```

## Permission checks

Before acting, check you can:

```julia
me = get_guild_member(client.api, guild_id, app_id)
perms = reduce(|, (r.permissions for r in get_guild_roles(client.api, guild_id)
                   if r.id in me.roles); init=Permission.none)
has_permission(perms, Permission.moderate_members) || return
```

`start!(client)` and your server minds itself.
