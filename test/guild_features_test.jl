using JSON3
using Dates

@testset "voice" begin
    @testset "VoiceState round-trip" begin
        json = """{
            "channel_id": "157733188964188161",
            "user_id": "80351110224678912",
            "session_id": "90326bd25d71d39b9ef95b299e3872ff",
            "deaf": false,
            "mute": false,
            "self_deaf": false,
            "self_mute": true,
            "self_video": false,
            "suppress": false,
            "request_to_speak_timestamp": "2021-03-31T18:45:31.297561+00:00"
        }"""
        vs = JSON3.read(json, VoiceState)
        @test vs.guild_id === missing
        @test vs.channel_id == 157733188964188161
        @test vs.self_mute && !vs.self_deaf
        @test vs.self_stream === missing
        @test vs.request_to_speak_timestamp == DateTime(2021, 3, 31, 18, 45, 31, 297)
        @test JSON3.read(JSON3.write(vs), VoiceState) == vs
    end

    @testset "VoiceRegion round-trip" begin
        json = """{"id": "us-west", "name": "US West", "optimal": true, "deprecated": false, "custom": false}"""
        region = JSON3.read(json, VoiceRegion)
        @test region.id == "us-west"
        @test region.optimal
        @test JSON3.read(JSON3.write(region), VoiceRegion) == region
    end

    @testset "list_voice_regions" begin
        fake = fakehttp(response(200; body="""[{"id": "us-west", "name": "US West", "optimal": true, "deprecated": false, "custom": false}]"""))
        regions = list_voice_regions(fastapi(fake))
        req = only(fake.requests)
        @test req.method == "GET"
        @test req.url == "https://discord.com/api/v10/voice/regions"
        @test regions isa Vector{VoiceRegion}
        @test only(regions).name == "US West"
    end

    @testset "modify_current_user_voice_state" begin
        fake = fakehttp(response(204))
        result = modify_current_user_voice_state(fastapi(fake), 197038439483310086;
                                                 suppress=false, request_to_speak_timestamp=nothing)
        @test result === nothing
        req = only(fake.requests)
        @test req.method == "PATCH"
        @test req.url == "https://discord.com/api/v10/guilds/197038439483310086/voice-states/@me"
        sent = sent_json(fake)
        @test sent.suppress === false
        @test sent.request_to_speak_timestamp === nothing
    end

    @testset "modify_user_voice_state" begin
        fake = fakehttp(response(204))
        modify_user_voice_state(fastapi(fake), 197038439483310086, 80351110224678912;
                                channel_id="157733188964188161", suppress=true)
        req = only(fake.requests)
        @test req.method == "PATCH"
        @test req.url == "https://discord.com/api/v10/guilds/197038439483310086/voice-states/80351110224678912"
        @test sent_json(fake).channel_id == "157733188964188161"
    end
end

@testset "stage instance" begin
    stage_json = """{
        "id": "840647391636226060",
        "guild_id": "197038439483310086",
        "channel_id": "733488538393510049",
        "topic": "Testing Testing, 123",
        "privacy_level": 1,
        "discoverable_disabled": false,
        "guild_scheduled_event_id": "947656305244532806"
    }"""

    @testset "StageInstance round-trip" begin
        stage = JSON3.read(stage_json, StageInstance)
        @test stage.id == 840647391636226060
        @test stage.topic == "Testing Testing, 123"
        @test stage.privacy_level == StageInstancePrivacyLevels.PUBLIC
        @test stage.guild_scheduled_event_id == 947656305244532806
        @test JSON3.read(JSON3.write(stage), StageInstance) == stage
    end

    @testset "create_stage_instance" begin
        fake = fakehttp(response(200; body=stage_json))
        stage = create_stage_instance(fastapi(fake); channel_id="733488538393510049",
                                      topic="Testing Testing, 123", reason="mic check")
        req = only(fake.requests)
        @test req.method == "POST"
        @test req.url == "https://discord.com/api/v10/stage-instances"
        @test ("X-Audit-Log-Reason" => "mic%20check") in req.headers
        sent = sent_json(fake)
        @test sent.channel_id == "733488538393510049"
        @test sent.topic == "Testing Testing, 123"
        @test stage isa StageInstance
        @test stage.channel_id == 733488538393510049
    end

    @testset "delete_stage_instance" begin
        fake = fakehttp(response(204))
        @test delete_stage_instance(fastapi(fake), 733488538393510049; reason="show over") === nothing
        req = only(fake.requests)
        @test req.method == "DELETE"
        @test req.url == "https://discord.com/api/v10/stage-instances/733488538393510049"
        @test ("X-Audit-Log-Reason" => "show%20over") in req.headers
    end
end

@testset "guild scheduled event" begin
    event_json = read(joinpath(@__DIR__, "fixtures", "guild_scheduled_event.json"), String)

    @testset "GuildScheduledEvent round-trip" begin
        event = JSON3.read(event_json, GuildScheduledEvent)
        @test event.name == "Community Yoga"
        @test event.channel_id === nothing
        @test event.creator_id == 80351110224678912
        @test event.scheduled_start_time == DateTime(2026, 8, 7, 18)
        @test event.privacy_level == GuildScheduledEventPrivacyLevels.GUILD_ONLY
        @test event.status == GuildScheduledEventStatuss.SCHEDULED
        @test event.entity_type == GuildScheduledEventEntityTypes.EXTERNAL
        @test event.entity_metadata.location == "Griffith Park"
        @test event.creator.username == "nelly"
        @test event.user_count == 23
        @test event.image === nothing
        rule = event.recurrence_rule
        @test rule.var"end" === nothing
        @test rule.frequency == RecurrenceRuleFrequencys.MONTHLY
        @test rule.by_weekday === nothing
        @test rule.by_n_weekday == [RecurrenceRuleNWeekday(1, RecurrenceRuleWeekdays.FRIDAY)]
        @test JSON3.read(JSON3.write(event), GuildScheduledEvent) == event
    end

    @testset "GuildScheduledEventUser round-trip" begin
        json = """{
            "guild_scheduled_event_id": "1059954443799498922",
            "user": {
                "id": "80351110224678912",
                "username": "nelly",
                "discriminator": "0",
                "global_name": "Nelly",
                "avatar": "8342729096ea3675442027381ff50dfe"
            }
        }"""
        subscriber = JSON3.read(json, GuildScheduledEventUser)
        @test subscriber.guild_scheduled_event_id == 1059954443799498922
        @test subscriber.user.username == "nelly"
        @test subscriber.member === missing
        @test JSON3.read(JSON3.write(subscriber), GuildScheduledEventUser) == subscriber
    end

    @testset "list_scheduled_events_for_guild" begin
        fake = fakehttp(response(200; body="[$event_json]"))
        events = list_scheduled_events_for_guild(fastapi(fake), 197038439483310086;
                                                 with_user_count=true)
        req = only(fake.requests)
        @test req.method == "GET"
        @test req.url == "https://discord.com/api/v10/guilds/197038439483310086/scheduled-events?with_user_count=true"
        @test events isa Vector{GuildScheduledEvent}
        @test only(events).name == "Community Yoga"
    end

    @testset "create_guild_scheduled_event" begin
        fake = fakehttp(response(200; body=event_json))
        event = create_guild_scheduled_event(fastapi(fake), 197038439483310086;
                                             name="Community Yoga", privacy_level=2,
                                             scheduled_start_time="2026-08-07T18:00:00+00:00",
                                             entity_type=3,
                                             entity_metadata=(location="Griffith Park",),
                                             reason="namaste")
        req = only(fake.requests)
        @test req.method == "POST"
        @test req.url == "https://discord.com/api/v10/guilds/197038439483310086/scheduled-events"
        @test ("X-Audit-Log-Reason" => "namaste") in req.headers
        sent = sent_json(fake)
        @test sent.name == "Community Yoga"
        @test sent.entity_type == 3
        @test sent.entity_metadata.location == "Griffith Park"
        @test event isa GuildScheduledEvent
        @test event.entity_type == GuildScheduledEventEntityTypes.EXTERNAL
    end

    @testset "get_guild_scheduled_event_users" begin
        user_json = """[{
            "guild_scheduled_event_id": "1059954443799498922",
            "user": {
                "id": "80351110224678912",
                "username": "nelly",
                "discriminator": "0",
                "global_name": "Nelly",
                "avatar": "8342729096ea3675442027381ff50dfe"
            }
        }]"""
        fake = fakehttp(response(200; body=user_json))
        users = get_guild_scheduled_event_users(fastapi(fake), 197038439483310086,
                                                1059954443799498922; limit=50, with_member=false)
        req = only(fake.requests)
        @test req.url == "https://discord.com/api/v10/guilds/197038439483310086/scheduled-events/1059954443799498922/users?limit=50&with_member=false"
        @test users isa Vector{GuildScheduledEventUser}
        @test only(users).user.id == 80351110224678912
    end

    @testset "delete_guild_scheduled_event" begin
        fake = fakehttp(response(204))
        @test delete_guild_scheduled_event(fastapi(fake), 197038439483310086,
                                           1059954443799498922; reason="rained out") === nothing
        req = only(fake.requests)
        @test req.method == "DELETE"
        @test req.url == "https://discord.com/api/v10/guilds/197038439483310086/scheduled-events/1059954443799498922"
        @test ("X-Audit-Log-Reason" => "rained%20out") in req.headers
    end
end

@testset "guild template" begin
    template_json = read(joinpath(@__DIR__, "fixtures", "guild_template.json"), String)

    @testset "GuildTemplate round-trip" begin
        template = JSON3.read(template_json, GuildTemplate)
        @test template.code == "hgM48av5Q69A"
        @test template.name == "Friends & Family"
        @test template.description === nothing
        @test template.usage_count == 49605
        @test template.creator.username == "hoges"
        @test template.created_at == DateTime(2020, 4, 2, 21, 10, 38)
        # The serialized guild is partial: no id, placeholder ids elsewhere.
        source = template.serialized_source_guild
        @test !haskey(source, "id")
        @test source["name"] == "Friends & Family"
        @test only(source["roles"])["name"] == "@everyone"
        @test only(source["channels"])["id"] == 1
        @test template.is_dirty === nothing
        @test JSON3.read(JSON3.write(template), GuildTemplate) == template
    end

    @testset "get_guild_template" begin
        fake = fakehttp(response(200; body=template_json))
        template = get_guild_template(fastapi(fake), "hgM48av5Q69A")
        req = only(fake.requests)
        @test req.method == "GET"
        @test req.url == "https://discord.com/api/v10/guilds/templates/hgM48av5Q69A"
        @test template isa GuildTemplate
        @test template.code == "hgM48av5Q69A"
    end

    @testset "create_guild_from_guild_template" begin
        # The endpoint returns a real guild — ids and full role/channel
        # objects — unlike the template's serialized copy.
        source = Dict(pairs(JSON3.read(template_json).serialized_source_guild))
        source[:id] = "678070694164299796"
        delete!(source, :roles)
        delete!(source, :channels)
        fake = fakehttp(response(200; body=JSON3.write(source)))
        guild = create_guild_from_guild_template(fastapi(fake), "hgM48av5Q69A"; name="Fam 2.0")
        req = only(fake.requests)
        @test req.method == "POST"
        @test req.url == "https://discord.com/api/v10/guilds/templates/hgM48av5Q69A"
        @test sent_json(fake).name == "Fam 2.0"
        @test guild isa Guild
        @test guild.name == "Friends & Family"
    end

    @testset "create_guild_template" begin
        fake = fakehttp(response(200; body=template_json))
        template = create_guild_template(fastapi(fake), 678070694164299796;
                                         name="Friends & Family")
        req = only(fake.requests)
        @test req.method == "POST"
        @test req.url == "https://discord.com/api/v10/guilds/678070694164299796/templates"
        @test sent_json(fake).name == "Friends & Family"
        @test template isa GuildTemplate
    end

    @testset "sync_guild_template" begin
        fake = fakehttp(response(200; body=template_json))
        template = sync_guild_template(fastapi(fake), 678070694164299796, "hgM48av5Q69A")
        req = only(fake.requests)
        @test req.method == "PUT"
        @test req.url == "https://discord.com/api/v10/guilds/678070694164299796/templates/hgM48av5Q69A"
        @test template.source_guild_id == 678070694164299796
    end
end
