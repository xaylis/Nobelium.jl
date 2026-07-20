using JSON3
using Dates

@testset "Webhook" begin
    fixture = read(joinpath(@__DIR__, "fixtures", "webhook.json"), String)

    @testset "types" begin
        w = JSON3.read(fixture, Webhook)
        @test w.id == 223704706495545344
        @test w.type == WebhookTypes.INCOMING
        @test w.name == "test webhook"
        @test w.avatar === nothing
        @test w.application_id === nothing
        @test w.guild_id == 199737254929760256
        @test startswith(w.token, "3d89bb75")
        @test w.user.username == "test"
        @test w.source_guild === missing
        @test w.url === missing
        @test JSON3.read(JSON3.write(w), Webhook) == w

        app = JSON3.read("""{
            "type": 3,
            "id": "658822586720976555",
            "name": "Clyde",
            "avatar": "689161dc90ac261d00f1608694ac6bfd",
            "channel_id": null,
            "guild_id": null,
            "application_id": "658822586720976555"
        }""", Webhook)
        @test app.type == WebhookTypes.APPLICATION
        @test app.channel_id === nothing
        @test app.guild_id === nothing
        @test app.application_id == 658822586720976555
        @test app.user === missing
    end

    @testset "create_webhook" begin
        fake = fakehttp(response(200; body=fixture))
        w = create_webhook(fastapi(fake), 199737254929760256;
                           name="test webhook", reason="bridge setup")
        req = only(fake.requests)
        @test req.method == "POST"
        @test req.url == "https://discord.com/api/v10/channels/199737254929760256/webhooks"
        @test ("X-Audit-Log-Reason" => "bridge%20setup") in req.headers
        @test sent_json(fake).name == "test webhook"
        @test w isa Webhook
        @test w.channel_id == 199737254929760256
    end

    @testset "get_guild_webhooks" begin
        fake = fakehttp(response(200; body="[$fixture]"))
        ws = get_guild_webhooks(fastapi(fake), 199737254929760256)
        req = only(fake.requests)
        @test req.method == "GET"
        @test req.url == "https://discord.com/api/v10/guilds/199737254929760256/webhooks"
        @test ws isa Vector{Webhook}
        @test only(ws).id == 223704706495545344
    end

    @testset "get_webhook_with_token" begin
        fake = fakehttp(response(200; body=fixture))
        w = get_webhook_with_token(fastapi(fake), 223704706495545344, "sekrit")
        req = only(fake.requests)
        @test req.method == "GET"
        @test req.url == "https://discord.com/api/v10/webhooks/223704706495545344/sekrit"
        @test !any(h -> h.first == "Authorization", req.headers)
        @test w isa Webhook
    end

    @testset "modify_webhook_with_token" begin
        fake = fakehttp(response(200; body=fixture))
        w = modify_webhook_with_token(fastapi(fake), 223704706495545344, "sekrit";
                                      name="renamed")
        req = only(fake.requests)
        @test req.method == "PATCH"
        @test req.url == "https://discord.com/api/v10/webhooks/223704706495545344/sekrit"
        @test !any(h -> h.first == "Authorization", req.headers)
        @test sent_json(fake).name == "renamed"
        @test w isa Webhook
    end

    @testset "delete_webhook" begin
        fake = fakehttp(response(204))
        @test delete_webhook(fastapi(fake), 223704706495545344; reason="stale") === nothing
        req = only(fake.requests)
        @test req.method == "DELETE"
        @test req.url == "https://discord.com/api/v10/webhooks/223704706495545344"
        @test ("X-Audit-Log-Reason" => "stale") in req.headers
    end

    @testset "execute_webhook" begin
        fake = fakehttp(response(204))
        r = execute_webhook(fastapi(fake), 223704706495545344, "sekrit";
                            content="hello", wait=true, thread_id=42,
                            files=[DiscordFile("plot.png", UInt8[0x89, 0x50])])
        @test r === nothing
        req = only(fake.requests)
        @test req.method == "POST"
        @test req.url ==
            "https://discord.com/api/v10/webhooks/223704706495545344/sekrit?wait=true&thread_id=42"
        @test !any(h -> h.first == "Authorization", req.headers)
        @test req.body isa HTTP.Form
        io = IOBuffer()
        write(io, req.body)
        raw = String(take!(io))
        @test occursin("payload_json", raw)
        @test occursin("hello", raw)
        @test occursin("plot.png", raw)
    end

    @testset "execute_slack_compatible_webhook" begin
        fake = fakehttp(response(204))
        execute_slack_compatible_webhook(fastapi(fake), 223704706495545344, "sekrit";
                                         thread_id=42, text="from slack")
        req = only(fake.requests)
        @test req.method == "POST"
        @test req.url ==
            "https://discord.com/api/v10/webhooks/223704706495545344/sekrit/slack?thread_id=42"
        @test !any(h -> h.first == "Authorization", req.headers)
        @test sent_json(fake).text == "from slack"
    end

    @testset "webhook messages" begin
        fake = fakehttp(response(204))
        get_webhook_message(fastapi(fake), 1, "sekrit", 55; thread_id=7)
        @test only(fake.requests).method == "GET"
        @test only(fake.requests).url ==
            "https://discord.com/api/v10/webhooks/1/sekrit/messages/55?thread_id=7"
        @test !any(h -> h.first == "Authorization", only(fake.requests).headers)

        fake = fakehttp(response(204))
        edit_webhook_message(fastapi(fake), 1, "sekrit", 55; thread_id=7, content="edited")
        @test only(fake.requests).method == "PATCH"
        @test only(fake.requests).url ==
            "https://discord.com/api/v10/webhooks/1/sekrit/messages/55?thread_id=7"
        @test sent_json(fake).content == "edited"

        fake = fakehttp(response(204))
        @test delete_webhook_message(fastapi(fake), 1, "sekrit", 55; thread_id=7) === nothing
        @test only(fake.requests).method == "DELETE"
        @test only(fake.requests).url ==
            "https://discord.com/api/v10/webhooks/1/sekrit/messages/55?thread_id=7"
    end
end

@testset "Invite" begin
    fixture = read(joinpath(@__DIR__, "fixtures", "invite.json"), String)

    @testset "types" begin
        inv = JSON3.read(fixture, Invite)
        @test inv.type == InviteTypes.GUILD
        @test inv.code == "0vCdhLbwjZZTWZLD"
        @test inv.guild === missing
        @test inv.channel.name == "illuminati"
        @test inv.inviter.username == "speed"
        @test inv.target_type == InviteTargetTypes.STREAM
        @test inv.target_user.username == "bob"
        @test inv.approximate_member_count == 100
        @test inv.expires_at === nothing
        @test GuildInviteFlag.is_guest_invite in inv.flags
        @test inv.roles === missing
        @test inv.uses == 3
        @test inv.max_age == 86400
        @test inv.temporary === false
        @test inv.created_at == DateTime(2016, 3, 31, 19, 15, 39, 954)
        @test JSON3.read(JSON3.write(inv), Invite) == inv
    end

    @testset "InviteStageInstance" begin
        si = JSON3.read("""{
            "topic": "The debate is over: diet is better than regular",
            "participant_count": 200,
            "speaker_count": 5,
            "members": []
        }""", InviteStageInstance)
        @test si.participant_count == 200
        @test si.speaker_count == 5
        @test isempty(si.members)
        @test JSON3.read(JSON3.write(si), InviteStageInstance) == si
    end

    @testset "get_invite" begin
        fake = fakehttp(response(200; body=fixture))
        inv = get_invite(fastapi(fake), "0vCdhLbwjZZTWZLD"; with_counts=true)
        req = only(fake.requests)
        @test req.method == "GET"
        @test req.url == "https://discord.com/api/v10/invites/0vCdhLbwjZZTWZLD?with_counts=true"
        @test inv isa Invite
        @test inv.approximate_presence_count == 42
    end

    @testset "delete_invite" begin
        fake = fakehttp(response(200; body=fixture))
        inv = delete_invite(fastapi(fake), "0vCdhLbwjZZTWZLD"; reason="raid cleanup")
        req = only(fake.requests)
        @test req.method == "DELETE"
        @test req.url == "https://discord.com/api/v10/invites/0vCdhLbwjZZTWZLD"
        @test ("X-Audit-Log-Reason" => "raid%20cleanup") in req.headers
        @test inv isa Invite
        @test inv.code == "0vCdhLbwjZZTWZLD"
    end
end
