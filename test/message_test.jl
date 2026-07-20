using Dates
using HTTP
using JSON3

const MESSAGE_JSON = read(joinpath(@__DIR__, "fixtures", "message.json"), String)

@testset "message" begin
    @testset "Message round-trip" begin
        m = JSON3.read(MESSAGE_JSON, Message)
        @test m.id == Snowflake(334385199974967042)
        @test m.author.username == "Mason"
        @test m.content == "Big news! In this <#278325129692446722> channel!"
        @test m.timestamp == DateTime(2017, 7, 11, 17, 27, 7, 299)
        @test m.edited_timestamp === nothing
        @test m.tts === false
        @test m.mention_roles == [Snowflake(41771983423143937)]
        @test only(m.mention_channels).name == "big-news"
        @test m.type === MessageTypes.REPLY
        @test m.flags == MessageFlags(0)
        @test m.nonce === missing
        @test m.webhook_id === missing
        @test m.thread === missing
        @test m.poll === missing
        @test m.components === missing

        att = only(m.attachments)
        @test att.id == Snowflake(334385199974967043)
        @test att.filename == "cat.png"
        @test att.height == 200
        @test att.flags == AttachmentFlag.is_spoiler
        @test att.duration_secs === missing

        emb = only(m.embeds)
        @test emb.title == "Hello, Embed!"
        @test emb.color == 15258703

        rxn = only(m.reactions)
        @test rxn.count == 1
        @test rxn.count_details.normal == 1
        @test rxn.emoji.id === nothing
        @test rxn.emoji.name == "🔥"

        @test m.message_reference.type === MessageReferenceTypes.DEFAULT
        @test m.message_reference.message_id == Snowflake(306588351130107906)
        @test m.referenced_message.content == "Supa Hot"
        @test m.referenced_message.mention_channels === missing

        meta = m.interaction_metadata
        @test meta.id == Snowflake(935943245803966475)
        @test meta.type === InteractionTypes.APPLICATION_COMMAND
        @test meta.user.username == "Mason"
        @test meta.authorizing_integration_owners["0"] == Snowflake(278325129692446720)
        @test meta.target_user === missing
        @test meta.interacted_message_id === missing

        @test only(m.sticker_items).name == "Wave"
        @test m.role_subscription_data.tier_name == "Sparkling Supporter"
        @test m.role_subscription_data.is_renewal === false
        @test m.call.participants == [Snowflake(53908099506183680)]
        @test m.call.ended_timestamp == DateTime(2021, 4, 12, 23, 40, 39, 855)

        @test JSON3.read(JSON3.write(m), Message) == m
    end

    @testset "MessageSnapshot round-trip" begin
        raw = """{"message": {
            "type": 0, "content": "forwarded!", "embeds": [], "attachments": [],
            "timestamp": "2017-07-11T17:27:07.299000+00:00", "edited_timestamp": null,
            "flags": 0, "mentions": [], "mention_roles": []
        }}"""
        snap = JSON3.read(raw, MessageSnapshot)
        @test snap.message.content == "forwarded!"
        @test snap.message.type === MessageTypes.DEFAULT
        @test snap.message.components === missing
        @test JSON3.read(JSON3.write(snap), MessageSnapshot) == snap
    end

    @testset "MessagePin round-trip" begin
        raw = """{"pinned_at": "2021-04-12T23:40:39.855793+00:00", "message": $MESSAGE_JSON}"""
        pin = JSON3.read(raw, MessagePin)
        @test pin.pinned_at == DateTime(2021, 4, 12, 23, 40, 39, 855)
        @test pin.message.id == Snowflake(334385199974967042)
        @test JSON3.read(JSON3.write(pin), MessagePin) == pin
    end

    @testset "SharedClientTheme round-trip" begin
        raw = """{"colors": ["5865F2", "7258F2"], "gradient_angle": 0, "base_mix": 58, "base_theme": 1}"""
        theme = JSON3.read(raw, SharedClientTheme)
        @test theme.colors == ["5865F2", "7258F2"]
        @test theme.base_theme === BaseThemes.DARK
        @test JSON3.read(JSON3.write(theme), SharedClientTheme) == theme
    end

    @testset "AllowedMentions defaults" begin
        raw = """{"parse": ["users", "roles"], "replied_user": true}"""
        am = JSON3.read(raw, AllowedMentions)
        @test am.parse == ["users", "roles"]
        @test am.roles === missing
        @test am.replied_user === true
        @test JSON3.read(JSON3.write(am), AllowedMentions) == am
    end

    @testset "MessageFlags" begin
        @test MessageFlag.ephemeral in (MessageFlag.ephemeral | MessageFlag.loading)
        @test MessageFlag.is_components_v2.value == 1 << 15
    end

    @testset "get_channel_messages" begin
        fake = fakehttp(response(200; body="[$MESSAGE_JSON]"))
        api = fastapi(fake)
        result = get_channel_messages(api, 290926798999357250; limit=5, before=42)
        req = only(fake.requests)
        @test req.method == "GET"
        @test req.url == "https://discord.com/api/v10/channels/290926798999357250/messages?limit=5&before=42"
        @test result isa Vector{Message}
        @test only(result).id == Snowflake(334385199974967042)
    end

    @testset "get_channel_message" begin
        fake = fakehttp(response(200; body=MESSAGE_JSON))
        result = get_channel_message(fastapi(fake), 290926798999357250, 334385199974967042)
        req = only(fake.requests)
        @test req.method == "GET"
        @test req.url == "https://discord.com/api/v10/channels/290926798999357250/messages/334385199974967042"
        @test result isa Message
    end

    @testset "create_message" begin
        fake = fakehttp(response(200; body=MESSAGE_JSON))
        result = create_message(fastapi(fake), 290926798999357250; content="Supa Hot", tts=false)
        req = only(fake.requests)
        @test req.method == "POST"
        @test req.url == "https://discord.com/api/v10/channels/290926798999357250/messages"
        @test sent_json(fake).content == "Supa Hot"
        @test result isa Message
    end

    @testset "create_message with files" begin
        fake = fakehttp(response(200; body=MESSAGE_JSON))
        create_message(fastapi(fake), 1; content="attached", files=[DiscordFile("a.txt", "hi")])
        @test only(fake.requests).body isa HTTP.Form
    end

    @testset "crosspost_message" begin
        fake = fakehttp(response(200; body=MESSAGE_JSON))
        result = crosspost_message(fastapi(fake), 290926798999357250, 334385199974967042)
        req = only(fake.requests)
        @test req.method == "POST"
        @test req.url == "https://discord.com/api/v10/channels/290926798999357250/messages/334385199974967042/crosspost"
        @test result isa Message
    end

    @testset "create_reaction" begin
        fake = fakehttp(response(204))
        create_reaction(fastapi(fake), 1, 2, "🔥")
        req = only(fake.requests)
        @test req.method == "PUT"
        @test req.url == "https://discord.com/api/v10/channels/1/messages/2/reactions/%F0%9F%94%A5/@me"
    end

    @testset "create_reaction custom emoji" begin
        fake = fakehttp(response(204))
        create_reaction(fastapi(fake), 1, 2, "name:123")
        @test endswith(only(fake.requests).url, "/reactions/name%3A123/@me")
    end

    @testset "delete_own_reaction" begin
        fake = fakehttp(response(204))
        delete_own_reaction(fastapi(fake), 1, 2, "🔥")
        req = only(fake.requests)
        @test req.method == "DELETE"
        @test endswith(req.url, "/reactions/%F0%9F%94%A5/@me")
    end

    @testset "delete_user_reaction" begin
        fake = fakehttp(response(204))
        delete_user_reaction(fastapi(fake), 1, 2, "🔥", 3)
        req = only(fake.requests)
        @test req.method == "DELETE"
        @test req.url == "https://discord.com/api/v10/channels/1/messages/2/reactions/%F0%9F%94%A5/3"
    end

    @testset "get_reactions" begin
        fake = fakehttp(response(200; body="""[{"id":"1","username":"a","discriminator":"0001","avatar":null}]"""))
        result = get_reactions(fastapi(fake), 1, 2, "🔥"; type=1, limit=10)
        req = only(fake.requests)
        @test req.method == "GET"
        @test occursin("type=1", req.url) && occursin("limit=10", req.url)
        @test result isa Vector{User}
    end

    @testset "delete_all_reactions" begin
        fake = fakehttp(response(204))
        delete_all_reactions(fastapi(fake), 1, 2)
        req = only(fake.requests)
        @test req.method == "DELETE"
        @test req.url == "https://discord.com/api/v10/channels/1/messages/2/reactions"
    end

    @testset "delete_all_reactions_for_emoji" begin
        fake = fakehttp(response(204))
        delete_all_reactions_for_emoji(fastapi(fake), 1, 2, "🔥")
        req = only(fake.requests)
        @test req.method == "DELETE"
        @test endswith(req.url, "/reactions/%F0%9F%94%A5")
    end

    @testset "edit_message" begin
        fake = fakehttp(response(200; body=MESSAGE_JSON))
        result = edit_message(fastapi(fake), 1, 2; content="edited")
        req = only(fake.requests)
        @test req.method == "PATCH"
        @test req.url == "https://discord.com/api/v10/channels/1/messages/2"
        @test sent_json(fake).content == "edited"
        @test result isa Message
    end

    @testset "edit_message with files" begin
        fake = fakehttp(response(200; body=MESSAGE_JSON))
        edit_message(fastapi(fake), 1, 2; files=[DiscordFile("b.txt", "hi")])
        @test only(fake.requests).body isa HTTP.Form
    end

    @testset "delete_message with reason" begin
        fake = fakehttp(response(204))
        delete_message(fastapi(fake), 1, 2; reason="spam")
        req = only(fake.requests)
        @test req.method == "DELETE"
        @test req.url == "https://discord.com/api/v10/channels/1/messages/2"
        @test ("X-Audit-Log-Reason" => "spam") in req.headers
    end

    @testset "bulk_delete_messages" begin
        fake = fakehttp(response(204))
        bulk_delete_messages(fastapi(fake), 1; messages=[2, 3], reason="cleanup")
        req = only(fake.requests)
        @test req.method == "POST"
        @test req.url == "https://discord.com/api/v10/channels/1/messages/bulk-delete"
        @test sent_json(fake).messages == [2, 3]
        @test ("X-Audit-Log-Reason" => "cleanup") in req.headers
    end

    @testset "get_channel_pins" begin
        fake = fakehttp(response(200; body="""{"items":[],"has_more":false}"""))
        result = get_channel_pins(fastapi(fake), 1; limit=10)
        req = only(fake.requests)
        @test req.method == "GET"
        @test req.url == "https://discord.com/api/v10/channels/1/messages/pins?limit=10"
        @test result.has_more === false
    end

    @testset "pin_message with reason" begin
        fake = fakehttp(response(204))
        pin_message(fastapi(fake), 1, 2; reason="important")
        req = only(fake.requests)
        @test req.method == "PUT"
        @test req.url == "https://discord.com/api/v10/channels/1/messages/pins/2"
        @test ("X-Audit-Log-Reason" => "important") in req.headers
    end

    @testset "unpin_message" begin
        fake = fakehttp(response(204))
        unpin_message(fastapi(fake), 1, 2)
        req = only(fake.requests)
        @test req.method == "DELETE"
        @test req.url == "https://discord.com/api/v10/channels/1/messages/pins/2"
    end
end
