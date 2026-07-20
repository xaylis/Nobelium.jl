using JSON3
using Dates

@testset "monetization" begin
    @testset "SKU round-trip" begin
        json = """{
            "id": "1088510058176307240",
            "type": 5,
            "application_id": "1088510058176307241",
            "name": "Bot Premium",
            "slug": "bot-premium",
            "flags": 128
        }"""
        sku = JSON3.read(json, SKU)
        @test sku.id == 1088510058176307240
        @test sku.type == SKUTypes.SUBSCRIPTION
        @test sku.name == "Bot Premium"
        @test sku.slug == "bot-premium"
        @test SKUFlag.guild_subscription in sku.flags
        @test JSON3.read(JSON3.write(sku), SKU) == sku
    end

    @testset "Entitlement round-trip" begin
        json = """{
            "id": "1019653849998299136",
            "sku_id": "1019475255913222144",
            "application_id": "1019475255913222145",
            "user_id": "771708247692214394",
            "type": 8,
            "deleted": false,
            "starts_at": "2022-09-14T17:00:18.704163+00:00",
            "ends_at": "2022-10-14T17:00:18.704163+00:00",
            "guild_id": "1015034326372454400",
            "consumed": false
        }"""
        ent = JSON3.read(json, Entitlement)
        @test ent.id == 1019653849998299136
        @test ent.type == EntitlementTypes.APPLICATION_SUBSCRIPTION
        @test ent.deleted === false
        @test ent.starts_at == DateTime(2022, 9, 14, 17, 0, 18, 704)
        @test ent.guild_id == 1015034326372454400
        @test ent.consumed === false
        @test JSON3.read(JSON3.write(ent), Entitlement) == ent
    end

    @testset "test Entitlement has no starts_at/ends_at" begin
        json = """{
            "id": "1019653849998299137",
            "sku_id": "1019475255913222144",
            "application_id": "1019475255913222145",
            "user_id": "771708247692214394",
            "type": 4,
            "deleted": false
        }"""
        ent = JSON3.read(json, Entitlement)
        @test ent.starts_at === missing
        @test ent.ends_at === missing
        @test ent.guild_id === missing
        @test ent.consumed === missing
        @test JSON3.read(JSON3.write(ent), Entitlement) == ent
    end

    @testset "Subscription round-trip" begin
        json = """{
            "id": "1019653849998299136",
            "user_id": "771708247692214394",
            "sku_ids": ["1019475255913222144"],
            "entitlement_ids": ["1019653849998299136"],
            "renewal_sku_ids": null,
            "current_period_start": "2022-09-14T17:00:18.704163+00:00",
            "current_period_end": "2022-10-14T17:00:18.704163+00:00",
            "status": 0,
            "canceled_at": null
        }"""
        sub = JSON3.read(json, Subscription)
        @test sub.id == 1019653849998299136
        @test sub.sku_ids == [1019475255913222144]
        @test sub.renewal_sku_ids === nothing
        @test sub.status == SubscriptionStatuses.ACTIVE
        @test sub.canceled_at === nothing
        @test sub.country === missing
        @test JSON3.read(JSON3.write(sub), Subscription) == sub
    end

    @testset "list_skus" begin
        sku_json = """{"id": "1", "type": 5, "application_id": "2", "name": "Premium", "slug": "premium", "flags": 4}"""
        fake = fakehttp(response(200; body="[$sku_json]"))
        skus = list_skus(fastapi(fake), 2)
        req = only(fake.requests)
        @test req.method == "GET"
        @test req.url == "https://discord.com/api/v10/applications/2/skus"
        @test skus isa Vector{SKU}
        @test only(skus).name == "Premium"
    end

    @testset "list_entitlements" begin
        ent_json = """{
            "id": "1", "sku_id": "2", "application_id": "3", "type": 1, "deleted": false
        }"""
        fake = fakehttp(response(200; body="[$ent_json]"))
        ents = list_entitlements(fastapi(fake), 3;
            user_id=771708247692214394, sku_ids="2", limit=10, exclude_ended=true)
        req = only(fake.requests)
        @test req.method == "GET"
        @test req.url == "https://discord.com/api/v10/applications/3/entitlements" *
            "?user_id=771708247692214394&sku_ids=2&limit=10&exclude_ended=true"
        @test ents isa Vector{Entitlement}
        @test only(ents).id == 1
    end

    @testset "get_entitlement" begin
        ent_json = """{
            "id": "1019653849998299136", "sku_id": "2", "application_id": "3",
            "type": 1, "deleted": false
        }"""
        fake = fakehttp(response(200; body=ent_json))
        ent = get_entitlement(fastapi(fake), 3, 1019653849998299136)
        req = only(fake.requests)
        @test req.method == "GET"
        @test req.url == "https://discord.com/api/v10/applications/3/entitlements/1019653849998299136"
        @test ent isa Entitlement
    end

    @testset "consume_entitlement" begin
        fake = fakehttp(response(204))
        @test consume_entitlement(fastapi(fake), 3, 1) === nothing
        req = only(fake.requests)
        @test req.method == "POST"
        @test req.url == "https://discord.com/api/v10/applications/3/entitlements/1/consume"
    end

    @testset "create_test_entitlement" begin
        ent_json = """{
            "id": "1", "sku_id": "2", "application_id": "3", "type": 4, "deleted": false
        }"""
        fake = fakehttp(response(200; body=ent_json))
        ent = create_test_entitlement(fastapi(fake), 3; sku_id="2", owner_id="5", owner_type=2)
        req = only(fake.requests)
        @test req.method == "POST"
        @test req.url == "https://discord.com/api/v10/applications/3/entitlements"
        sent = sent_json(fake)
        @test sent.sku_id == "2"
        @test sent.owner_id == "5"
        @test sent.owner_type == 2
        @test ent isa Entitlement
    end

    @testset "delete_test_entitlement" begin
        fake = fakehttp(response(204))
        @test delete_test_entitlement(fastapi(fake), 3, 1) === nothing
        req = only(fake.requests)
        @test req.method == "DELETE"
        @test req.url == "https://discord.com/api/v10/applications/3/entitlements/1"
    end

    @testset "list_sku_subscriptions" begin
        sub_json = """{
            "id": "1", "user_id": "2", "sku_ids": ["9"], "entitlement_ids": ["1"],
            "renewal_sku_ids": null, "current_period_start": "2022-09-14T17:00:18.704163+00:00",
            "current_period_end": "2022-10-14T17:00:18.704163+00:00", "status": 0,
            "canceled_at": null
        }"""
        fake = fakehttp(response(200; body="[$sub_json]"))
        subs = list_sku_subscriptions(fastapi(fake), 9; user_id=2, limit=25)
        req = only(fake.requests)
        @test req.method == "GET"
        @test req.url == "https://discord.com/api/v10/skus/9/subscriptions?user_id=2&limit=25"
        @test subs isa Vector{Subscription}
        @test only(subs).id == 1
    end

    @testset "get_sku_subscription" begin
        sub_json = """{
            "id": "1", "user_id": "2", "sku_ids": ["9"], "entitlement_ids": ["1"],
            "renewal_sku_ids": null, "current_period_start": "2022-09-14T17:00:18.704163+00:00",
            "current_period_end": "2022-10-14T17:00:18.704163+00:00", "status": 2,
            "canceled_at": "2022-09-20T17:00:18.704163+00:00"
        }"""
        fake = fakehttp(response(200; body=sub_json))
        sub = get_sku_subscription(fastapi(fake), 9, 1)
        req = only(fake.requests)
        @test req.method == "GET"
        @test req.url == "https://discord.com/api/v10/skus/9/subscriptions/1"
        @test sub isa Subscription
        @test sub.status == SubscriptionStatuses.ENDING
    end
end

@testset "soundboard" begin
    @testset "SoundboardSound round-trip" begin
        json = """{
            "name": "Yay",
            "sound_id": "1106714396018884649",
            "volume": 1,
            "emoji_id": "989193655938064464",
            "emoji_name": null,
            "guild_id": "613425648685547541",
            "available": true
        }"""
        sound = JSON3.read(json, SoundboardSound)
        @test sound.name == "Yay"
        @test sound.sound_id == 1106714396018884649
        @test sound.volume == 1.0
        @test sound.emoji_id == 989193655938064464
        @test sound.emoji_name === nothing
        @test sound.guild_id == 613425648685547541
        @test sound.available === true
        @test sound.user === missing
        @test JSON3.read(JSON3.write(sound), SoundboardSound) == sound
    end

    @testset "default sound has no guild_id" begin
        json = """{
            "name": "quack",
            "sound_id": "1",
            "volume": 1.0,
            "emoji_id": null,
            "emoji_name": "🦆",
            "available": true
        }"""
        sound = JSON3.read(json, SoundboardSound)
        @test sound.emoji_id === nothing
        @test sound.emoji_name == "🦆"
        @test sound.guild_id === missing
        @test JSON3.read(JSON3.write(sound), SoundboardSound) == sound
    end

    @testset "send_soundboard_sound" begin
        fake = fakehttp(response(204))
        @test send_soundboard_sound(fastapi(fake), 1; sound_id=1106714396018884649,
                                    source_guild_id=613425648685547541) === nothing
        req = only(fake.requests)
        @test req.method == "POST"
        @test req.url == "https://discord.com/api/v10/channels/1/send-soundboard-sound"
        sent = sent_json(fake)
        @test sent.sound_id == "1106714396018884649"
        @test sent.source_guild_id == "613425648685547541"
    end

    @testset "list_default_soundboard_sounds" begin
        sound_json = """{
            "name": "quack", "sound_id": "1", "volume": 1.0,
            "emoji_id": null, "emoji_name": "🦆", "available": true
        }"""
        fake = fakehttp(response(200; body="[$sound_json]"))
        sounds = list_default_soundboard_sounds(fastapi(fake))
        req = only(fake.requests)
        @test req.method == "GET"
        @test req.url == "https://discord.com/api/v10/soundboard-default-sounds"
        @test sounds isa Vector{SoundboardSound}
    end

    @testset "list_guild_soundboard_sounds" begin
        sound_json = """{
            "name": "Yay", "sound_id": "1106714396018884649", "volume": 1,
            "emoji_id": null, "emoji_name": null, "guild_id": "613425648685547541",
            "available": true
        }"""
        fake = fakehttp(response(200; body="""{"items": [$sound_json]}"""))
        sounds = list_guild_soundboard_sounds(fastapi(fake), 613425648685547541)
        req = only(fake.requests)
        @test req.method == "GET"
        @test req.url == "https://discord.com/api/v10/guilds/613425648685547541/soundboard-sounds"
        @test sounds isa Vector{SoundboardSound}
    end

    @testset "get_guild_soundboard_sound" begin
        sound_json = """{
            "name": "Yay", "sound_id": "1106714396018884649", "volume": 1,
            "emoji_id": null, "emoji_name": null, "guild_id": "613425648685547541",
            "available": true
        }"""
        fake = fakehttp(response(200; body=sound_json))
        sound = get_guild_soundboard_sound(fastapi(fake), 613425648685547541, 1106714396018884649)
        req = only(fake.requests)
        @test req.method == "GET"
        @test req.url ==
            "https://discord.com/api/v10/guilds/613425648685547541/soundboard-sounds/1106714396018884649"
        @test sound isa SoundboardSound
    end

    @testset "create_guild_soundboard_sound" begin
        sound_json = """{
            "name": "Yay", "sound_id": "1106714396018884649", "volume": 1,
            "emoji_id": null, "emoji_name": null, "guild_id": "613425648685547541",
            "available": true
        }"""
        fake = fakehttp(response(200; body=sound_json))
        sound = create_guild_soundboard_sound(fastapi(fake), 613425648685547541;
            name="Yay", sound="data:audio/ogg;base64,AAAA", reason="new sound")
        req = only(fake.requests)
        @test req.method == "POST"
        @test req.url == "https://discord.com/api/v10/guilds/613425648685547541/soundboard-sounds"
        @test ("X-Audit-Log-Reason" => "new%20sound") in req.headers
        sent = sent_json(fake)
        @test sent.name == "Yay"
        @test sound isa SoundboardSound
    end

    @testset "modify_guild_soundboard_sound" begin
        sound_json = """{
            "name": "Yay!", "sound_id": "1106714396018884649", "volume": 0.5,
            "emoji_id": null, "emoji_name": null, "guild_id": "613425648685547541",
            "available": true
        }"""
        fake = fakehttp(response(200; body=sound_json))
        sound = modify_guild_soundboard_sound(fastapi(fake), 613425648685547541,
            1106714396018884649; volume=0.5, reason="quieter")
        req = only(fake.requests)
        @test req.method == "PATCH"
        @test req.url ==
            "https://discord.com/api/v10/guilds/613425648685547541/soundboard-sounds/1106714396018884649"
        @test ("X-Audit-Log-Reason" => "quieter") in req.headers
        @test sent_json(fake).volume == 0.5
        @test sound isa SoundboardSound
    end

    @testset "delete_guild_soundboard_sound" begin
        fake = fakehttp(response(204))
        @test delete_guild_soundboard_sound(fastapi(fake), 613425648685547541,
            1106714396018884649; reason="unused") === nothing
        req = only(fake.requests)
        @test req.method == "DELETE"
        @test req.url ==
            "https://discord.com/api/v10/guilds/613425648685547541/soundboard-sounds/1106714396018884649"
        @test ("X-Audit-Log-Reason" => "unused") in req.headers
    end
end

@testset "lobby" begin
    @testset "Lobby round-trip" begin
        json = """{
            "id": "96008815106887111",
            "application_id": "41771983429993937",
            "metadata": {"topic": "we need more redstone"},
            "members": [
                {"id": "41771983429993000", "metadata": null, "flags": 1}
            ]
        }"""
        lobby = JSON3.read(json, Lobby)
        @test lobby.id == 96008815106887111
        @test lobby.application_id == 41771983429993937
        @test lobby.metadata == Dict("topic" => "we need more redstone")
        member = only(lobby.members)
        @test member.id == 41771983429993000
        @test member.metadata === nothing
        @test LobbyMemberFlag.can_link_lobby in member.flags
        @test lobby.linked_channel === missing
        @test JSON3.read(JSON3.write(lobby), Lobby) == lobby
    end

    @testset "LobbyMember round-trip with absent fields" begin
        json = """{"id": "1"}"""
        member = JSON3.read(json, LobbyMember)
        @test member.id == 1
        @test member.metadata === missing
        @test member.flags === missing
        @test JSON3.read(JSON3.write(member), LobbyMember) == member
    end

    @testset "create_lobby" begin
        lobby_json = """{
            "id": "1", "application_id": "2", "metadata": null, "members": []
        }"""
        fake = fakehttp(response(200; body=lobby_json))
        lobby = create_lobby(fastapi(fake); metadata=Dict("topic" => "hi"), idle_timeout_seconds=300)
        req = only(fake.requests)
        @test req.method == "POST"
        @test req.url == "https://discord.com/api/v10/lobbies"
        @test any(h -> h.first == "Authorization" && h.second == "Bot test-token", req.headers)
        @test sent_json(fake).idle_timeout_seconds == 300
        @test lobby isa Lobby
    end

    @testset "create_or_join_lobby uses bearer auth" begin
        lobby_json = """{"id": "1", "application_id": "2", "metadata": null, "members": []}"""
        fake = fakehttp(response(200; body=lobby_json))
        lobby = create_or_join_lobby(fastapi(fake); secret="s3cr3t")
        req = only(fake.requests)
        @test req.method == "PUT"
        @test req.url == "https://discord.com/api/v10/lobbies"
        @test any(h -> h.first == "Authorization" && h.second == "Bearer test-token", req.headers)
        @test sent_json(fake).secret == "s3cr3t"
        @test lobby isa Lobby
    end

    @testset "get_lobby" begin
        lobby_json = """{"id": "1", "application_id": "2", "metadata": null, "members": []}"""
        fake = fakehttp(response(200; body=lobby_json))
        lobby = get_lobby(fastapi(fake), 1)
        req = only(fake.requests)
        @test req.method == "GET"
        @test req.url == "https://discord.com/api/v10/lobbies/1"
        @test lobby isa Lobby
    end

    @testset "modify_lobby" begin
        lobby_json = """{"id": "1", "application_id": "2", "metadata": null, "members": []}"""
        fake = fakehttp(response(200; body=lobby_json))
        lobby = modify_lobby(fastapi(fake), 1; idle_timeout_seconds=600)
        req = only(fake.requests)
        @test req.method == "PATCH"
        @test req.url == "https://discord.com/api/v10/lobbies/1"
        @test sent_json(fake).idle_timeout_seconds == 600
        @test lobby isa Lobby
    end

    @testset "delete_lobby" begin
        fake = fakehttp(response(204))
        @test delete_lobby(fastapi(fake), 1) === nothing
        req = only(fake.requests)
        @test req.method == "DELETE"
        @test req.url == "https://discord.com/api/v10/lobbies/1"
    end

    @testset "add_lobby_member" begin
        member_json = """{"id": "2", "metadata": null, "flags": 1}"""
        fake = fakehttp(response(200; body=member_json))
        member = add_lobby_member(fastapi(fake), 1, 2; flags=1)
        req = only(fake.requests)
        @test req.method == "PUT"
        @test req.url == "https://discord.com/api/v10/lobbies/1/members/2"
        @test sent_json(fake).flags == 1
        @test member isa LobbyMember
    end

    @testset "bulk_lobby_member_update" begin
        member_json = """[{"id": "2", "metadata": null, "flags": 0}]"""
        fake = fakehttp(response(200; body=member_json))
        members = bulk_lobby_member_update(fastapi(fake), 1,
            [(id="2", flags=0), (id="3", remove_member=true)])
        req = only(fake.requests)
        @test req.method == "POST"
        @test req.url == "https://discord.com/api/v10/lobbies/1/members/bulk"
        sent = sent_json(fake)
        @test length(sent) == 2
        @test sent[1].id == "2"
        @test sent[2].remove_member === true
        @test members isa Vector{LobbyMember}
    end

    @testset "remove_lobby_member" begin
        fake = fakehttp(response(204))
        @test remove_lobby_member(fastapi(fake), 1, 2) === nothing
        req = only(fake.requests)
        @test req.method == "DELETE"
        @test req.url == "https://discord.com/api/v10/lobbies/1/members/2"
    end

    @testset "leave_lobby uses bearer auth" begin
        fake = fakehttp(response(204))
        @test leave_lobby(fastapi(fake), 1) === nothing
        req = only(fake.requests)
        @test req.method == "DELETE"
        @test req.url == "https://discord.com/api/v10/lobbies/1/members/@me"
        @test any(h -> h.first == "Authorization" && h.second == "Bearer test-token", req.headers)
    end

    @testset "link_channel_to_lobby uses bearer auth" begin
        lobby_json = """{"id": "1", "application_id": "2", "metadata": null, "members": [],
            "linked_channel": {"id": "5", "type": 0}}"""
        fake = fakehttp(response(200; body=lobby_json))
        lobby = link_channel_to_lobby(fastapi(fake), 1; channel_id=5)
        req = only(fake.requests)
        @test req.method == "PATCH"
        @test req.url == "https://discord.com/api/v10/lobbies/1/channel-linking"
        @test any(h -> h.first == "Authorization" && h.second == "Bearer test-token", req.headers)
        @test sent_json(fake).channel_id == "5"
        @test lobby.linked_channel.id == 5
    end

    @testset "unlink_channel_from_lobby uses bearer auth" begin
        lobby_json = """{"id": "1", "application_id": "2", "metadata": null, "members": []}"""
        fake = fakehttp(response(200; body=lobby_json))
        lobby = unlink_channel_from_lobby(fastapi(fake), 1)
        req = only(fake.requests)
        @test req.method == "PATCH"
        @test req.url == "https://discord.com/api/v10/lobbies/1/channel-linking"
        @test any(h -> h.first == "Authorization" && h.second == "Bearer test-token", req.headers)
        @test lobby.linked_channel === missing
    end

    @testset "send_lobby_message uses bearer auth" begin
        fake = fakehttp(response(200; body="""{"id": "9", "content": "hi"}"""))
        msg = send_lobby_message(fastapi(fake), 1; content="hi")
        req = only(fake.requests)
        @test req.method == "POST"
        @test req.url == "https://discord.com/api/v10/lobbies/1/messages"
        @test any(h -> h.first == "Authorization" && h.second == "Bearer test-token", req.headers)
        @test sent_json(fake).content == "hi"
        @test msg.content == "hi"
    end

    @testset "get_lobby_messages uses bearer auth and query" begin
        fake = fakehttp(response(200; body="""[{"id": "9", "content": "hi"}]"""))
        msgs = get_lobby_messages(fastapi(fake), 1; limit=10)
        req = only(fake.requests)
        @test req.method == "GET"
        @test req.url == "https://discord.com/api/v10/lobbies/1/messages?limit=10"
        @test any(h -> h.first == "Authorization" && h.second == "Bearer test-token", req.headers)
        @test only(msgs).content == "hi"
    end

    @testset "update_lobby_message_moderation_metadata" begin
        fake = fakehttp(response(204))
        result = update_lobby_message_moderation_metadata(fastapi(fake), 1, 9,
            Dict("flag" => "spam"))
        @test result === nothing
        req = only(fake.requests)
        @test req.method == "PUT"
        @test req.url == "https://discord.com/api/v10/lobbies/1/messages/9/moderation-metadata"
        @test any(h -> h.first == "Authorization" && h.second == "Bot test-token", req.headers)
        @test sent_json(fake).flag == "spam"
    end

    @testset "create_lobby_channel_invite_for_self uses bearer auth" begin
        fake = fakehttp(response(200; body="""{"code": "abc123"}"""))
        invite = create_lobby_channel_invite_for_self(fastapi(fake), 1)
        req = only(fake.requests)
        @test req.method == "POST"
        @test req.url == "https://discord.com/api/v10/lobbies/1/members/@me/invites"
        @test any(h -> h.first == "Authorization" && h.second == "Bearer test-token", req.headers)
        @test invite.code == "abc123"
    end

    @testset "create_lobby_channel_invite_for_user uses bot auth" begin
        fake = fakehttp(response(200; body="""{"code": "abc123"}"""))
        invite = create_lobby_channel_invite_for_user(fastapi(fake), 1, 2)
        req = only(fake.requests)
        @test req.method == "POST"
        @test req.url == "https://discord.com/api/v10/lobbies/1/members/2/invites"
        @test any(h -> h.first == "Authorization" && h.second == "Bot test-token", req.headers)
        @test invite.code == "abc123"
    end
end
