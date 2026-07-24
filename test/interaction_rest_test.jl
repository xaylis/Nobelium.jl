using JSON3
using Dates

const SLASH_COMMAND_INTERACTION = """{
    "id": "986268025268285440",
    "application_id": "290926792926887945",
    "type": 2,
    "token": "unique_interaction_token",
    "version": 1,
    "app_permissions": "2147483647",
    "locale": "en-US",
    "guild_locale": "en-US",
    "guild_id": "290926798626357999",
    "channel_id": "645027906669510667",
    "entitlements": [],
    "authorizing_integration_owners": {"0": "290926798626357999"},
    "attachment_size_limit": 8388608,
    "member": {
        "user": {
            "id": "53908232506183680",
            "username": "Mason",
            "discriminator": "1337",
            "avatar": "a_d5efa99b3eeaa7dd43acca82f5692432"
        },
        "roles": [],
        "premium_since": null,
        "permissions": "2147483647",
        "pending": false,
        "nick": null,
        "mute": false,
        "joined_at": "2017-03-13T19:19:14.040000+00:00",
        "flags": 0,
        "deaf": false
    },
    "data": {
        "id": "775799577604522024",
        "name": "sum",
        "type": 1,
        "options": [
            {"name": "a", "type": 4, "value": 2},
            {"name": "b", "type": 4, "value": 3}
        ],
        "resolved": {
            "users": {
                "53908232506183680": {
                    "id": "53908232506183680",
                    "username": "Mason",
                    "discriminator": "1337",
                    "avatar": "a_d5efa99b3eeaa7dd43acca82f5692432"
                }
            },
            "members": {
                "53908232506183680": {
                    "roles": ["290926798626357999"],
                    "premium_since": null,
                    "permissions": "2147483647",
                    "pending": false,
                    "nick": null,
                    "joined_at": "2017-03-13T19:19:14.040000+00:00",
                    "flags": 0
                }
            }
        }
    }
}"""

const CALLBACK_RESPONSE = """{
    "interaction": {
        "id": "986268025268285440",
        "type": 2,
        "response_message_id": "986268025268285999",
        "response_message_loading": false,
        "response_message_ephemeral": false
    },
    "resource": {
        "type": 4,
        "message": {
            "id": "986268025268285999",
            "channel_id": "645027906669510667",
            "author": {
                "id": "290926792926887945",
                "username": "sum-bot",
                "discriminator": "0000",
                "avatar": null
            },
            "content": "5",
            "timestamp": "2021-04-12T23:40:39.855793+00:00",
            "edited_timestamp": null,
            "tts": false,
            "mention_everyone": false,
            "mentions": [],
            "mention_roles": [],
            "attachments": [],
            "embeds": [],
            "pinned": false,
            "type": 20,
            "flags": 0
        }
    }
}"""

@testset "interaction REST" begin
    @testset "partial guild in interaction" begin
        i = JSON3.read("""{
            "id": "1", "application_id": "2", "type": 2, "token": "t", "version": 1,
            "app_permissions": "0", "entitlements": [],
            "authorizing_integration_owners": {}, "attachment_size_limit": 8388608,
            "guild": {"id": "1392713127724060802", "locale": "en-US", "features": []}
        }""", Interaction)
        @test i.guild.id == Snowflake(1392713127724060802)
        @test i.guild.name === missing
    end

    @testset "Interaction round-trip" begin
        i = JSON3.read(SLASH_COMMAND_INTERACTION, Interaction)
        @test i.id == 986268025268285440
        @test i.application_id == 290926792926887945
        @test i.type == InteractionTypes.APPLICATION_COMMAND
        @test i.token == "unique_interaction_token"
        @test i.version == 1
        @test i.guild_id == 290926798626357999
        @test i.channel === missing
        @test i.member.nick === nothing
        @test i.member.user.username == "Mason"
        @test i.user === missing
        @test i.entitlements == []
        @test i.authorizing_integration_owners["0"] == 290926798626357999

        d = i.data
        @test d.name == "sum"
        @test d.type == ApplicationCommandTypes.CHAT_INPUT
        opts = d.options
        @test length(opts) == 2
        @test opts[1].name == "a" && opts[1].value == 2
        @test opts[2].name == "b" && opts[2].value == 3
        @test d.resolved.users[Snowflake(53908232506183680)].username == "Mason"
        # Resolved members are partial: no user, deaf, or mute.
        member = d.resolved.members[Snowflake(53908232506183680)]
        @test member.user === missing
        @test member.deaf === missing && member.mute === missing
        @test member.roles == [Snowflake(290926798626357999)]

        @test JSON3.read(JSON3.write(i), Interaction) == i
    end

    @testset "InteractionCallbackResponse round-trip" begin
        r = JSON3.read(CALLBACK_RESPONSE, InteractionCallbackResponse)
        @test r.interaction.id == 986268025268285440
        @test r.interaction.response_message_ephemeral === false
        @test r.resource.type == InteractionCallbackTypes.CHANNEL_MESSAGE_WITH_SOURCE
        @test r.resource.message.content == "5"
        @test JSON3.read(JSON3.write(r), InteractionCallbackResponse) == r
    end

    @testset "create_interaction_response" begin
        fake = fakehttp(response(204))
        r = create_interaction_response(fastapi(fake), 986268025268285440, "tok";
                                        type=4, data=(; content="pong"))
        @test r === nothing
        req = only(fake.requests)
        @test req.method == "POST"
        @test req.url ==
            "https://discord.com/api/v10/interactions/986268025268285440/tok/callback"
        @test !any(h -> h.first == "Authorization", req.headers)
        sent = sent_json(fake)
        @test sent.type == 4
        @test sent.data.content == "pong"
    end

    @testset "create_interaction_response with_response" begin
        fake = fakehttp(response(200; body=CALLBACK_RESPONSE))
        r = create_interaction_response(fastapi(fake), 986268025268285440, "tok";
                                        type=4, data=(; content="pong"), with_response=true)
        req = only(fake.requests)
        @test req.url ==
            "https://discord.com/api/v10/interactions/986268025268285440/tok/callback?with_response=true"
        @test r isa InteractionCallbackResponse
        @test r.resource.message.content == "5"
    end

    @testset "create_followup_message" begin
        fixture = read(joinpath(@__DIR__, "fixtures", "message.json"), String)
        fake = fakehttp(response(200; body=fixture))
        m = create_followup_message(fastapi(fake), 290926792926887945, "tok"; content="hi there")
        req = only(fake.requests)
        @test req.method == "POST"
        @test req.url == "https://discord.com/api/v10/webhooks/290926792926887945/tok"
        @test !any(h -> h.first == "Authorization", req.headers)
        @test sent_json(fake).content == "hi there"
        @test m isa Message
        @test m.id == 334385199974967042
    end

    @testset "edit_original_interaction_response" begin
        fixture = read(joinpath(@__DIR__, "fixtures", "message.json"), String)
        fake = fakehttp(response(200; body=fixture))
        m = edit_original_interaction_response(fastapi(fake), 290926792926887945, "tok";
                                               content="edited")
        req = only(fake.requests)
        @test req.method == "PATCH"
        @test req.url ==
            "https://discord.com/api/v10/webhooks/290926792926887945/tok/messages/@original"
        @test sent_json(fake).content == "edited"
        @test m isa Message
    end

    @testset "get/delete original interaction response" begin
        fixture = read(joinpath(@__DIR__, "fixtures", "message.json"), String)
        fake = fakehttp(response(200; body=fixture))
        m = get_original_interaction_response(fastapi(fake), 290926792926887945, "tok")
        req = only(fake.requests)
        @test req.method == "GET"
        @test req.url ==
            "https://discord.com/api/v10/webhooks/290926792926887945/tok/messages/@original"
        @test m isa Message

        fake = fakehttp(response(204))
        @test delete_original_interaction_response(fastapi(fake), 290926792926887945, "tok") ===
            nothing
        req = only(fake.requests)
        @test req.method == "DELETE"
        @test req.url ==
            "https://discord.com/api/v10/webhooks/290926792926887945/tok/messages/@original"
    end

    @testset "followup message get/edit/delete" begin
        fixture = read(joinpath(@__DIR__, "fixtures", "message.json"), String)

        fake = fakehttp(response(200; body=fixture))
        m = get_followup_message(fastapi(fake), 290926792926887945, "tok", 334385199974967042)
        @test only(fake.requests).url ==
            "https://discord.com/api/v10/webhooks/290926792926887945/tok/messages/334385199974967042"
        @test m isa Message

        fake = fakehttp(response(200; body=fixture))
        m = edit_followup_message(fastapi(fake), 290926792926887945, "tok", 334385199974967042;
                                  content="edited followup")
        req = only(fake.requests)
        @test req.method == "PATCH"
        @test sent_json(fake).content == "edited followup"
        @test m isa Message

        fake = fakehttp(response(204))
        @test delete_followup_message(fastapi(fake), 290926792926887945, "tok",
                                      334385199974967042) === nothing
        @test only(fake.requests).method == "DELETE"
    end
end

@testset "interaction response helpers" begin
    mkinteraction() = Interaction(;
        id=986268025268285440, application_id=290926792926887945,
        type=InteractionTypes.APPLICATION_COMMAND, token="tok", version=1,
        app_permissions=Permissions(0), entitlements=[],
        authorizing_integration_owners=Dict{String,Snowflake}(),
        attachment_size_limit=8388608)

    @testset "respond" begin
        fake = fakehttp(response(204))
        respond(fastapi(fake), mkinteraction(); content="pong!")
        req = only(fake.requests)
        @test req.method == "POST"
        @test req.url ==
            "https://discord.com/api/v10/interactions/986268025268285440/tok/callback"
        sent = sent_json(fake)
        @test sent.type == Int(InteractionCallbackTypes.CHANNEL_MESSAGE_WITH_SOURCE.value)
        @test sent.data.content == "pong!"
    end

    @testset "respond ephemeral sets flags" begin
        fake = fakehttp(response(204))
        respond(fastapi(fake), mkinteraction(); content="shh", ephemeral=true)
        sent = sent_json(fake)
        @test sent.data.flags == 64
    end

    @testset "defer ephemeral sets flags" begin
        fake = fakehttp(response(204))
        defer(fastapi(fake), mkinteraction(); ephemeral=true)
        sent = sent_json(fake)
        @test sent.type == Int(InteractionCallbackTypes.DEFERRED_CHANNEL_MESSAGE_WITH_SOURCE.value)
        @test sent.data.flags == 64
    end

    @testset "followup ephemeral sets flags" begin
        fixture = read(joinpath(@__DIR__, "fixtures", "message.json"), String)
        fake = fakehttp(response(200; body=fixture))
        m = followup(fastapi(fake), mkinteraction(); content="extra", ephemeral=true)
        req = only(fake.requests)
        @test req.method == "POST"
        @test req.url == "https://discord.com/api/v10/webhooks/290926792926887945/tok"
        sent = sent_json(fake)
        @test sent.content == "extra"
        @test sent.flags == 64
        @test m isa Message
    end
end
