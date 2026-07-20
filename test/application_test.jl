using JSON3
using Dates

const APPLICATION_JSON = read(joinpath(@__DIR__, "fixtures", "application.json"), String)

@testset "application" begin
    @testset "Application round-trip" begin
        app = JSON3.read(APPLICATION_JSON, Application)
        @test app.id == 172150183260323840
        @test app.icon === nothing
        @test app.bot === missing
        @test app.owner.global_name === nothing
        @test app.flags == ApplicationFlag.verification_pending_guild_limit
        @test app.approximate_guild_count == 42
        @test app.interactions_endpoint_url === nothing
        @test app.event_webhooks_status == ApplicationEventWebhookStatusTypes.DISABLED
        @test app.event_webhooks_url === missing
        @test app.install_params.permissions == Permission.administrator
        @test app.integration_types_config["0"].oauth2_install_params.scopes ==
              ["applications.commands", "bot"]
        @test app.integration_types_config["1"].oauth2_install_params === missing
        @test JSON3.read(JSON3.write(app), Application) == app
    end

    @testset "Team" begin
        team = JSON3.read(APPLICATION_JSON, Application).team
        @test team.owner_user_id == 511972282709709995
        member = only(team.members)
        @test member.membership_state == MembershipStates.ACCEPTED
        @test member.role == "admin"
        @test member.user.username == "Mr Owner"
        @test JSON3.read(JSON3.write(team), Team) == team
    end

    @testset "ActivityInstance" begin
        raw = """{
            "application_id": "891106492936884234",
            "instance_id": "i-1234567890-gc-853667115216657449-853667115216657452",
            "launch_id": "1272203991275637022",
            "location": {
                "id": "gc-853667115216657449-853667115216657452",
                "kind": "gc",
                "channel_id": "853667115216657452",
                "guild_id": "853667115216657449"
            },
            "users": ["853667115216657451"]
        }"""
        instance = JSON3.read(raw, ActivityInstance)
        @test instance.location.kind == "gc"
        @test instance.location.channel_id == 853667115216657452
        @test instance.users == [Snowflake(853667115216657451)]
        @test JSON3.read(JSON3.write(instance), ActivityInstance) == instance
    end

    @testset "ApplicationRoleConnectionMetadata" begin
        raw = """{"type": 2, "key": "cookies_eaten", "name": "Cookies Eaten",
                  "description": "Number of cookies eaten"}"""
        record = JSON3.read(raw, ApplicationRoleConnectionMetadata)
        @test record.type == ApplicationRoleConnectionMetadataTypes.INTEGER_GREATER_THAN_OR_EQUAL
        @test record.key == "cookies_eaten"
        @test record.name_localizations === missing
        @test JSON3.read(JSON3.write(record), ApplicationRoleConnectionMetadata) == record
    end

    @testset "get_current_application" begin
        fake = fakehttp(response(200; body=APPLICATION_JSON))
        app = get_current_application(fastapi(fake))
        req = only(fake.requests)
        @test req.method == "GET"
        @test req.url == "https://discord.com/api/v10/applications/@me"
        @test app isa Application
        @test app.name == "Baba O-Riley"
    end

    @testset "edit_current_application" begin
        fake = fakehttp(response(200; body=APPLICATION_JSON))
        edit_current_application(fastapi(fake); description="Now with cowbell", tags=["music"])
        req = only(fake.requests)
        @test req.method == "PATCH"
        @test req.url == "https://discord.com/api/v10/applications/@me"
        sent = sent_json(fake)
        @test sent.description == "Now with cowbell"
        @test sent.tags == ["music"]
    end

    @testset "get_application_activity_instance" begin
        fake = fakehttp(response(200; body="""{
            "application_id": "891106492936884234",
            "instance_id": "i-91",
            "launch_id": "1272203991275637022",
            "location": {"id": "pc-455", "kind": "pc", "channel_id": "455"},
            "users": []
        }"""))
        instance = get_application_activity_instance(fastapi(fake), 891106492936884234, "i-91")
        req = only(fake.requests)
        @test req.url ==
              "https://discord.com/api/v10/applications/891106492936884234/activity-instances/i-91"
        @test instance isa ActivityInstance
        @test instance.location.guild_id === missing
    end

    @testset "role connection metadata records" begin
        records_json = """[{"type": 3, "key": "level", "name": "Level",
                           "description": "Current level"}]"""
        fake = fakehttp(response(200; body=records_json))
        records = get_application_role_connection_metadata_records(fastapi(fake), 172150183260323840)
        @test only(fake.requests).url ==
              "https://discord.com/api/v10/applications/172150183260323840/role-connections/metadata"
        @test records isa Vector{ApplicationRoleConnectionMetadata}
        @test only(records).key == "level"

        fake = fakehttp(response(200; body=records_json))
        record = ApplicationRoleConnectionMetadata(
            type=ApplicationRoleConnectionMetadataTypes.INTEGER_EQUAL,
            key="level", name="Level", description="Current level")
        update_application_role_connection_metadata_records(fastapi(fake), 172150183260323840, [record])
        req = only(fake.requests)
        @test req.method == "PUT"
        sent = sent_json(fake)
        @test length(sent) == 1
        @test sent[1].key == "level"
        @test sent[1].type == 3
        @test !haskey(sent[1], :name_localizations)
    end
end

@testset "oauth2" begin
    @testset "get_current_bot_application_information" begin
        fake = fakehttp(response(200; body=APPLICATION_JSON))
        app = get_current_bot_application_information(fastapi(fake))
        req = only(fake.requests)
        @test req.url == "https://discord.com/api/v10/oauth2/applications/@me"
        @test ("Authorization" => "Bot test-token") in req.headers
        @test app isa Application
    end

    @testset "get_current_authorization_information" begin
        fake = fakehttp(response(200; body="""{
            "application": {
                "id": "159799960412356608",
                "name": "AIRHORN SOLUTIONS",
                "icon": "f03590d3eb764081d154a66340ea7d6d",
                "description": "",
                "bot_public": true,
                "bot_require_code_grant": false,
                "verify_key": "c8cde6a3c8c6e49d86af3191287b3ce2",
                "team": null
            },
            "scopes": ["guilds", "identify"],
            "expires": "2022-06-24T19:41:41.567000+00:00",
            "user": {
                "id": "268473310986240001",
                "username": "discord",
                "discriminator": "0001",
                "global_name": null,
                "avatar": "f749bb0cbeeb26ef21eca719337d20f1"
            }
        }"""))
        info = get_current_authorization_information(fastapi(fake))
        req = only(fake.requests)
        @test req.url == "https://discord.com/api/v10/oauth2/@me"
        @test ("Authorization" => "Bearer test-token") in req.headers
        @test info isa AuthorizationInfo
        @test info.scopes == ["guilds", "identify"]
        @test info.expires == DateTime(2022, 6, 24, 19, 41, 41, 567)
        @test info.user.username == "discord"
        @test info.application.team === nothing
        @test JSON3.read(JSON3.write(info), AuthorizationInfo) == info
    end
end

@testset "gateway metadata" begin
    const_gateway_bot = """{
        "url": "wss://gateway.discord.gg/",
        "shards": 9,
        "session_start_limit": {
            "total": 1000,
            "remaining": 999,
            "reset_after": 14400000,
            "max_concurrency": 1
        }
    }"""

    @testset "get_gateway" begin
        fake = fakehttp(response(200; body="""{"url": "wss://gateway.discord.gg/"}"""))
        result = get_gateway(fastapi(fake))
        req = only(fake.requests)
        @test req.url == "https://discord.com/api/v10/gateway"
        @test all(h -> h.first != "Authorization", req.headers)
        @test result.url == "wss://gateway.discord.gg/"
    end

    @testset "get_gateway_bot" begin
        fake = fakehttp(response(200; body=const_gateway_bot))
        info = get_gateway_bot(fastapi(fake))
        req = only(fake.requests)
        @test req.url == "https://discord.com/api/v10/gateway/bot"
        @test ("Authorization" => "Bot test-token") in req.headers
        @test info isa GatewayBotInfo
        @test info.shards == 9
        @test info.session_start_limit.remaining == 999
        @test info.session_start_limit.max_concurrency == 1
        @test JSON3.read(JSON3.write(info), GatewayBotInfo) == info
    end
end
