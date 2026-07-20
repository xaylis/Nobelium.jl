using Dates
using JSON3

const GUILD_JSON = read(joinpath(@__DIR__, "fixtures", "guild.json"), String)

const MEMBER_JSON = """{
    "user": {
        "id": "80351110224678912",
        "username": "nelly",
        "discriminator": "0",
        "global_name": "Nelly",
        "avatar": "8342729096ea3675442027381ff50dfe"
    },
    "nick": "NOT API SUPPORT",
    "avatar": null,
    "roles": ["41771983423143936"],
    "joined_at": "2015-04-26T06:26:56.936000+00:00",
    "premium_since": null,
    "deaf": false,
    "mute": false,
    "flags": 6,
    "pending": false,
    "communication_disabled_until": null
}"""

const ONBOARDING_JSON = """{
    "guild_id": "960007075288915998",
    "prompts": [
        {
            "id": "1067461047608422473",
            "type": 0,
            "options": [
                {
                    "id": "1067461047608422476",
                    "channel_ids": ["962007075288916001"],
                    "role_ids": [],
                    "emoji": {"id": "1070002302032826408", "name": "chat", "animated": false},
                    "title": "Chat with Friends",
                    "description": ""
                },
                {
                    "id": "1070004843541954678",
                    "channel_ids": [],
                    "role_ids": ["962014491178082314"],
                    "title": "Get Gud",
                    "description": null
                }
            ],
            "title": "What do you want to do in this community?",
            "single_select": false,
            "required": true,
            "in_onboarding": true
        }
    ],
    "default_channel_ids": ["962007075288916001", "967513153225867295"],
    "enabled": true,
    "mode": 0
}"""

@testset "Guild resource" begin
    @testset "Guild round-trip" begin
        g = JSON3.read(GUILD_JSON, Guild)
        @test g.id == Snowflake(197038439483310086)
        @test g.name == "Discord Testers"
        @test g.owner === missing
        @test g.icon_hash === nothing
        @test g.afk_channel_id === nothing
        @test g.afk_timeout == 300
        @test g.verification_level === VerificationLevels.HIGH
        @test g.default_message_notifications === DefaultMessageNotificationLevels.ONLY_MENTIONS
        @test g.explicit_content_filter === ExplicitContentFilterLevels.ALL_MEMBERS
        @test g.mfa_level === MFALevels.ELEVATED
        @test g.nsfw_level === NSFWLevels.DEFAULT
        @test g.premium_tier === PremiumTiers.TIER_3
        @test g.system_channel_flags ==
              SystemChannelFlag.suppress_join_notifications |
              SystemChannelFlag.suppress_premium_subscriptions
        @test "COMMUNITY" in g.features
        @test only(g.roles).name == "WE DEM BOYZZ!!!!!!"
        @test only(g.emojis).name == "LUL"
        @test g.max_presences === nothing
        @test g.welcome_screen.welcome_channels[1].emoji_id === nothing
        @test g.welcome_screen.welcome_channels[2].emoji_id == Snowflake(596548880329588786)
        @test g.incidents_data.invites_disabled_until == DateTime(2024, 5, 24, 21)
        @test g.incidents_data.dms_disabled_until === nothing
        @test g.incidents_data.raid_detected_at === missing
        @test JSON3.read(JSON3.write(g), Guild) == g
    end

    @testset "GuildMember round-trip" begin
        m = JSON3.read(MEMBER_JSON, GuildMember)
        @test m.user.username == "nelly"
        @test m.nick == "NOT API SUPPORT"
        @test m.avatar === nothing
        @test m.banner === missing
        @test m.roles == [Snowflake(41771983423143936)]
        @test m.joined_at == DateTime(2015, 4, 26, 6, 26, 56, 936)
        @test m.premium_since === nothing
        @test m.flags ==
              GuildMemberFlag.completed_onboarding | GuildMemberFlag.bypasses_verification
        @test m.permissions === missing
        @test JSON3.read(JSON3.write(m), GuildMember) == m
    end

    @testset "Integration round-trip" begin
        i = JSON3.read("""{
            "id": "33590653072239123",
            "name": "A Name",
            "type": "twitch",
            "enabled": true,
            "syncing": false,
            "role_id": "433022223891644416",
            "enable_emoticons": true,
            "expire_behavior": 1,
            "expire_grace_period": 1,
            "account": {"id": "1234567", "name": "twitchusername"},
            "synced_at": "2021-08-29T17:23:15.443000+00:00",
            "subscriber_count": 42,
            "revoked": false
        }""", Integration)
        @test i.type == "twitch"
        @test i.expire_behavior === IntegrationExpireBehaviors.KICK
        @test i.account.name == "twitchusername"
        @test i.synced_at == DateTime(2021, 8, 29, 17, 23, 15, 443)
        @test i.application === missing
        @test JSON3.read(JSON3.write(i), Integration) == i
    end

    @testset "GuildOnboarding round-trip" begin
        o = JSON3.read(ONBOARDING_JSON, GuildOnboarding)
        @test o.guild_id == Snowflake(960007075288915998)
        @test o.mode === OnboardingModes.ONBOARDING_DEFAULT
        p = only(o.prompts)
        @test p.type === PromptTypes.MULTIPLE_CHOICE
        @test !p.single_select && p.required && p.in_onboarding
        @test p.options[1].emoji.name == "chat"
        @test p.options[2].emoji === missing
        @test p.options[2].description === nothing
        @test JSON3.read(JSON3.write(o), GuildOnboarding) == o
    end

    @testset "get_guild" begin
        fake = fakehttp(response(200; body=GUILD_JSON))
        g = get_guild(fastapi(fake), 197038439483310086; with_counts=true)
        req = only(fake.requests)
        @test req.method == "GET"
        @test endswith(req.url, "/guilds/197038439483310086?with_counts=true")
        @test g isa Guild
        @test g.approximate_member_count == 951
    end

    @testset "create_guild" begin
        fake = fakehttp(response(201; body=GUILD_JSON))
        g = create_guild(fastapi(fake); name="Discord Testers")
        req = only(fake.requests)
        @test req.method == "POST"
        @test endswith(req.url, "/guilds")
        @test sent_json(fake).name == "Discord Testers"
        @test g isa Guild
    end

    @testset "modify_guild" begin
        fake = fakehttp(response(200; body=GUILD_JSON))
        modify_guild(fastapi(fake), 197038439483310086;
                     name="Renamed", description=nothing, reason="rebrand")
        req = only(fake.requests)
        @test req.method == "PATCH"
        @test endswith(req.url, "/guilds/197038439483310086")
        @test ("X-Audit-Log-Reason" => "rebrand") in req.headers
        sent = sent_json(fake)
        @test sent.name == "Renamed"
        @test sent.description === nothing
    end

    @testset "delete_guild" begin
        fake = fakehttp(response(204))
        @test delete_guild(fastapi(fake), 5) === nothing
        @test only(fake.requests).method == "DELETE"
        @test endswith(only(fake.requests).url, "/guilds/5")
    end

    @testset "modify_guild_channel_positions" begin
        fake = fakehttp(response(204))
        modify_guild_channel_positions(fastapi(fake), 5,
                                       [(id=10, position=2), (id=11, position=1)])
        req = only(fake.requests)
        @test req.method == "PATCH"
        @test endswith(req.url, "/guilds/5/channels")
        sent = sent_json(fake)
        @test length(sent) == 2 && sent[1].position == 2
    end

    @testset "list_guild_members" begin
        fake = fakehttp(response(200; body="[$MEMBER_JSON]"))
        members = list_guild_members(fastapi(fake), 5; limit=100, after=80351110224678912)
        @test endswith(only(fake.requests).url,
                       "/guilds/5/members?limit=100&after=80351110224678912")
        @test members isa Vector{GuildMember}
        @test only(members).nick == "NOT API SUPPORT"
    end

    @testset "search_guild_members" begin
        fake = fakehttp(response(200; body="[$MEMBER_JSON]"))
        search_guild_members(fastapi(fake), 5; query="nel", limit=3)
        @test endswith(only(fake.requests).url, "/guilds/5/members/search?query=nel&limit=3")
    end

    @testset "add_guild_member" begin
        fake = fakehttp(response(201; body=MEMBER_JSON))
        m = add_guild_member(fastapi(fake), 5, 80351110224678912; access_token="abc")
        req = only(fake.requests)
        @test req.method == "PUT"
        @test endswith(req.url, "/guilds/5/members/80351110224678912")
        @test sent_json(fake).access_token == "abc"
        @test m isa GuildMember
    end

    @testset "modify_guild_member" begin
        fake = fakehttp(response(200; body=MEMBER_JSON))
        modify_guild_member(fastapi(fake), 5, 7; nick="dj", reason="requested")
        req = only(fake.requests)
        @test req.method == "PATCH"
        @test endswith(req.url, "/guilds/5/members/7")
        @test ("X-Audit-Log-Reason" => "requested") in req.headers
        @test sent_json(fake).nick == "dj"
    end

    @testset "add_guild_member_role" begin
        fake = fakehttp(response(204))
        @test add_guild_member_role(fastapi(fake), 5, 7, 9; reason="promotion") === nothing
        req = only(fake.requests)
        @test req.method == "PUT"
        @test endswith(req.url, "/guilds/5/members/7/roles/9")
        @test ("X-Audit-Log-Reason" => "promotion") in req.headers
    end

    @testset "remove_guild_member" begin
        fake = fakehttp(response(204))
        remove_guild_member(fastapi(fake), 5, 7; reason="rule 1")
        req = only(fake.requests)
        @test req.method == "DELETE"
        @test endswith(req.url, "/guilds/5/members/7")
        @test ("X-Audit-Log-Reason" => "rule%201") in req.headers
    end

    @testset "get_guild_bans" begin
        ban = """{"reason": "mentioning b1nzy", "user": {"id": "53908099506183680",
                  "username": "mason", "discriminator": "0", "global_name": null,
                  "avatar": null}}"""
        fake = fakehttp(response(200; body="[$ban]"))
        bans = get_guild_bans(fastapi(fake), 5; limit=5, after=100)
        @test endswith(only(fake.requests).url, "/guilds/5/bans?limit=5&after=100")
        @test bans isa Vector{Ban}
        @test only(bans).reason == "mentioning b1nzy"
        @test only(bans).user.username == "mason"
    end

    @testset "create_guild_ban" begin
        fake = fakehttp(response(204))
        create_guild_ban(fastapi(fake), 5, 7; delete_message_seconds=3600, reason="spam")
        req = only(fake.requests)
        @test req.method == "PUT"
        @test endswith(req.url, "/guilds/5/bans/7")
        @test ("X-Audit-Log-Reason" => "spam") in req.headers
        @test sent_json(fake).delete_message_seconds == 3600
    end

    @testset "bulk_guild_ban" begin
        fake = fakehttp(response(200;
            body="""{"banned_users": ["1", "2"], "failed_users": []}"""))
        result = bulk_guild_ban(fastapi(fake), 5; user_ids=["1", "2"], reason="raid")
        req = only(fake.requests)
        @test req.method == "POST"
        @test endswith(req.url, "/guilds/5/bulk-ban")
        @test ("X-Audit-Log-Reason" => "raid") in req.headers
        @test result.banned_users == ["1", "2"]
        @test isempty(result.failed_users)
    end

    @testset "get_guild_roles" begin
        role = JSON3.write(JSON3.read(GUILD_JSON).roles)
        fake = fakehttp(response(200; body=role))
        roles = get_guild_roles(fastapi(fake), 5)
        @test endswith(only(fake.requests).url, "/guilds/5/roles")
        @test roles isa Vector{Role}
        @test only(roles).hoist
    end

    @testset "modify_guild_role_positions" begin
        fake = fakehttp(response(200; body=JSON3.write(JSON3.read(GUILD_JSON).roles)))
        roles = modify_guild_role_positions(fastapi(fake), 5, [(id=9, position=3)];
                                            reason="reorder")
        req = only(fake.requests)
        @test req.method == "PATCH"
        @test endswith(req.url, "/guilds/5/roles")
        @test ("X-Audit-Log-Reason" => "reorder") in req.headers
        @test sent_json(fake)[1].id == 9
        @test roles isa Vector{Role}
    end

    @testset "modify_guild_mfa_level" begin
        fake = fakehttp(response(200; body="1"))
        @test modify_guild_mfa_level(fastapi(fake), 5; level=1, reason="lockdown") == 1
        req = only(fake.requests)
        @test req.method == "POST"
        @test endswith(req.url, "/guilds/5/mfa")
        @test sent_json(fake).level == 1
    end

    @testset "prune" begin
        fake = fakehttp(response(200; body="""{"pruned": 12}"""))
        count = get_guild_prune_count(fastapi(fake), 5; days=7)
        @test endswith(only(fake.requests).url, "/guilds/5/prune?days=7")
        @test count.pruned == 12

        fake = fakehttp(response(200; body="""{"pruned": 9}"""))
        result = begin_guild_prune(fastapi(fake), 5; days=30, compute_prune_count=true,
                                   reason="spring cleaning")
        req = only(fake.requests)
        @test req.method == "POST"
        @test endswith(req.url, "/guilds/5/prune")
        @test ("X-Audit-Log-Reason" => "spring%20cleaning") in req.headers
        @test sent_json(fake).days == 30
        @test result.pruned == 9
    end

    @testset "widget" begin
        fake = fakehttp(response(200; body="""{"enabled": true, "channel_id": null}"""))
        settings = get_guild_widget_settings(fastapi(fake), 5)
        @test endswith(only(fake.requests).url, "/guilds/5/widget")
        @test settings isa GuildWidgetSettings
        @test settings.enabled && settings.channel_id === nothing

        fake = fakehttp(response(200; body="""{"enabled": false, "channel_id": null}"""))
        modify_guild_widget(fastapi(fake), 5; enabled=false, reason="privacy")
        req = only(fake.requests)
        @test req.method == "PATCH"
        @test ("X-Audit-Log-Reason" => "privacy") in req.headers
        @test sent_json(fake).enabled == false

        fake = fakehttp(response(200; body="""{
            "id": "290926798626999250", "name": "Test Server", "instant_invite": null,
            "channels": [], "members": [], "presence_count": 20
        }"""))
        widget = get_guild_widget(fastapi(fake), 290926798626999250)
        @test endswith(only(fake.requests).url, "/guilds/290926798626999250/widget.json")
        @test widget isa GuildWidget
        @test widget.presence_count == 20
    end

    @testset "get_guild_widget_image" begin
        fake = fakehttp(response(200; body="\x89PNG"))
        png = get_guild_widget_image(fastapi(fake), 5; style="banner1")
        req = only(fake.requests)
        @test req.method == "GET"
        @test endswith(req.url, "/guilds/5/widget.png?style=banner1")
        @test !any(h -> h.first == "Authorization", req.headers)
        @test png == Vector{UInt8}(codeunits("\x89PNG"))
    end

    @testset "get_guild_vanity_url" begin
        fake = fakehttp(response(200; body="""{"code": "abc", "uses": 12}"""))
        vanity = get_guild_vanity_url(fastapi(fake), 5)
        @test endswith(only(fake.requests).url, "/guilds/5/vanity-url")
        @test vanity.code == "abc" && vanity.uses == 12
    end

    @testset "welcome screen" begin
        body = JSON3.write(JSON3.read(GUILD_JSON).welcome_screen)
        fake = fakehttp(response(200; body))
        ws = get_guild_welcome_screen(fastapi(fake), 5)
        @test endswith(only(fake.requests).url, "/guilds/5/welcome-screen")
        @test ws isa WelcomeScreen
        @test length(ws.welcome_channels) == 2

        fake = fakehttp(response(200; body))
        modify_guild_welcome_screen(fastapi(fake), 5; enabled=true, reason="opening up")
        req = only(fake.requests)
        @test req.method == "PATCH"
        @test ("X-Audit-Log-Reason" => "opening%20up") in req.headers
        @test sent_json(fake).enabled == true
    end

    @testset "onboarding" begin
        fake = fakehttp(response(200; body=ONBOARDING_JSON))
        o = get_guild_onboarding(fastapi(fake), 960007075288915998)
        @test endswith(only(fake.requests).url, "/guilds/960007075288915998/onboarding")
        @test o isa GuildOnboarding

        fake = fakehttp(response(200; body=ONBOARDING_JSON))
        modify_guild_onboarding(fastapi(fake), 960007075288915998;
                                enabled=false, mode=OnboardingModes.ONBOARDING_ADVANCED,
                                reason="revamp")
        req = only(fake.requests)
        @test req.method == "PUT"
        @test ("X-Audit-Log-Reason" => "revamp") in req.headers
        sent = sent_json(fake)
        @test sent.enabled == false && sent.mode == 1
    end
end
