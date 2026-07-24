using JSON3

@testset "auto moderation" begin
    rule_json = read(joinpath(@__DIR__, "fixtures", "automod_rule.json"), String)

    @testset "AutoModerationRule round-trip" begin
        rule = JSON3.read(rule_json, AutoModerationRule)
        @test rule.id == 969707018069872670
        @test rule.name == "Keyword Filter 1"
        @test rule.event_type == AutoModerationEventTypes.MESSAGE_SEND
        @test rule.trigger_type == AutoModerationTriggerTypes.KEYWORD
        @test rule.trigger_metadata.keyword_filter == ["cat*", "*dog", "*ana*", "i like c++"]
        @test length(rule.trigger_metadata.regex_patterns) == 2
        @test rule.trigger_metadata.presets === missing
        @test rule.trigger_metadata.mention_total_limit === missing
        @test length(rule.actions) == 3
        @test rule.actions[1].type == AutoModerationActionTypes.BLOCK_MESSAGE
        @test startswith(rule.actions[1].metadata.custom_message, "Please keep")
        @test rule.actions[2].metadata.channel_id == 123456789123456789
        @test rule.actions[3].metadata.duration_seconds == 60
        @test rule.actions[3].metadata.channel_id === missing
        @test rule.enabled === true
        @test rule.exempt_roles == [323456789123456789, 423456789123456789]
        @test rule.exempt_channels == [523456789123456789]
        @test JSON3.read(JSON3.write(rule), AutoModerationRule) == rule
    end

    @testset "list_auto_moderation_rules_for_guild" begin
        fake = fakehttp(response(200; body="[$rule_json]"))
        rules = list_auto_moderation_rules_for_guild(fastapi(fake), 613425648685547541)
        req = only(fake.requests)
        @test req.method == "GET"
        @test req.url ==
            "https://discord.com/api/v10/guilds/613425648685547541/auto-moderation/rules"
        @test rules isa Vector{AutoModerationRule}
        @test only(rules).guild_id == 613425648685547541
    end

    @testset "create_auto_moderation_rule" begin
        fake = fakehttp(response(200; body=rule_json))
        rule = create_auto_moderation_rule(fastapi(fake), 613425648685547541;
            name="Keyword Filter 1", event_type=1, trigger_type=1,
            trigger_metadata=(keyword_filter=["cat*"],),
            actions=[AutoModerationAction(; type=AutoModerationActionTypes.BLOCK_MESSAGE)],
            reason="spam wave")
        req = only(fake.requests)
        @test req.method == "POST"
        @test endswith(req.url, "/guilds/613425648685547541/auto-moderation/rules")
        @test ("X-Audit-Log-Reason" => "spam%20wave") in req.headers
        sent = sent_json(fake)
        @test sent.name == "Keyword Filter 1"
        @test sent.trigger_type == 1
        @test sent.trigger_metadata.keyword_filter == ["cat*"]
        @test only(sent.actions).type == 1
        @test !haskey(only(sent.actions), :metadata)
        @test rule isa AutoModerationRule && rule.enabled === true
    end

    @testset "modify_auto_moderation_rule" begin
        fake = fakehttp(response(200; body=rule_json))
        rule = modify_auto_moderation_rule(fastapi(fake), 613425648685547541,
                                           969707018069872670; enabled=false, reason="pausing")
        req = only(fake.requests)
        @test req.method == "PATCH"
        @test endswith(req.url,
                       "/guilds/613425648685547541/auto-moderation/rules/969707018069872670")
        @test ("X-Audit-Log-Reason" => "pausing") in req.headers
        @test sent_json(fake).enabled === false
        @test rule isa AutoModerationRule
    end

    @testset "delete_auto_moderation_rule" begin
        fake = fakehttp(response(204))
        @test delete_auto_moderation_rule(fastapi(fake), 1, 2; reason="obsolete") === nothing
        req = only(fake.requests)
        @test req.method == "DELETE"
        @test req.url == "https://discord.com/api/v10/guilds/1/auto-moderation/rules/2"
        @test ("X-Audit-Log-Reason" => "obsolete") in req.headers
    end
end

@testset "audit log" begin
    log_json = read(joinpath(@__DIR__, "fixtures", "audit_log.json"), String)

    @testset "AuditLog round-trip" begin
        log = JSON3.read(log_json, AuditLog)
        @test isempty(log.application_commands)
        @test only(log.users).username == "mason"

        # Audit logs reference partial integrations: no enabled, among others.
        integration = only(log.integrations)
        @test integration.type == "twitch"
        @test integration.enabled === missing
        @test integration.account.name == "twitchusername"

        renamed, pruned = log.audit_log_entries
        @test renamed.action_type == AuditLogEvents.CHANNEL_UPDATE
        @test renamed.target_id == "84043391694213120"
        @test renamed.reason == "renaming for clarity"
        @test renamed.options === missing
        change = only(renamed.changes)
        @test change.key == "name"
        @test change.old_value == "general"
        @test change.new_value == "lounge"

        @test pruned.action_type == AuditLogEvents.MEMBER_PRUNE
        @test pruned.target_id === nothing
        @test pruned.changes === missing
        @test pruned.reason === missing
        @test pruned.options.delete_member_days == "7"
        @test pruned.options.members_removed == "3"
        @test pruned.options.channel_id === missing

        @test JSON3.read(JSON3.write(log), AuditLog) == log
    end

    @testset "get_guild_audit_log" begin
        fake = fakehttp(response(200; body=log_json))
        log = get_guild_audit_log(fastapi(fake), 197038439483310086;
                                  user_id=53908232506183680, action_type=11, limit=25)
        req = only(fake.requests)
        @test req.method == "GET"
        @test req.url == "https://discord.com/api/v10/guilds/197038439483310086/audit-logs" *
            "?user_id=53908232506183680&action_type=11&limit=25"
        @test log isa AuditLog
        @test length(log.audit_log_entries) == 2
    end
end
