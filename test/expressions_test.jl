using HTTP
using JSON3

@testset "roles" begin
    role_json = """
    {
        "id": "41771983423143936",
        "name": "WE DEM BOYZZ!!!!!!",
        "color": 3447003,
        "colors": {
            "primary_color": 3447003,
            "secondary_color": null,
            "tertiary_color": null
        },
        "hoist": true,
        "icon": "cf3ced8600b777c9486c6d8d84fb4327",
        "unicode_emoji": null,
        "position": 1,
        "permissions": "66321471",
        "managed": false,
        "mentionable": false,
        "flags": 0
    }
    """

    @testset "round-trip" begin
        r = JSON3.read(role_json, Role)
        @test r.id == Snowflake(41771983423143936)
        @test r.name == "WE DEM BOYZZ!!!!!!"
        @test r.colors.primary_color == 3447003
        @test r.colors.secondary_color === nothing
        @test r.icon == "cf3ced8600b777c9486c6d8d84fb4327"
        @test r.unicode_emoji === nothing
        @test r.permissions == Permissions(66321471)
        @test Permission.kick_members in r.permissions
        @test r.tags === missing
        @test iszero(r.flags)
        @test JSON3.read(JSON3.write(r), Role) == r
    end

    @testset "tags" begin
        t = JSON3.read("""{"integration_id": "10", "premium_subscriber": null}""", RoleTags)
        @test t.integration_id == Snowflake(10)
        @test t.premium_subscriber === nothing    # tag applies
        @test t.available_for_purchase === missing  # tag doesn't
        @test JSON3.read(JSON3.write(t), RoleTags) == t
    end

    @testset "flags and mention" begin
        @test RoleFlag.in_prompt == RoleFlags(1)
        r = JSON3.read(role_json, Role)
        @test mention(r) == "<@&41771983423143936>"
    end
end

@testset "emoji" begin
    emoji_json = """
    {
        "id": "41771983429993937",
        "name": "LUL",
        "roles": ["41771983429993000", "41771983429993111"],
        "user": {
            "username": "Luigi",
            "discriminator": "0002",
            "id": "96008815106887111",
            "avatar": "5500909a3274e1812beb4e8de6631111",
            "global_name": null,
            "public_flags": 131328
        },
        "require_colons": true,
        "managed": false,
        "animated": false
    }
    """

    @testset "round-trip" begin
        e = JSON3.read(emoji_json, Emoji)
        @test e.id == Snowflake(41771983429993937)
        @test e.name == "LUL"
        @test e.roles == [Snowflake(41771983429993000), Snowflake(41771983429993111)]
        @test e.user.username == "Luigi"
        @test e.require_colons === true
        @test e.animated === false
        @test e.available === missing
        @test JSON3.read(JSON3.write(e), Emoji) == e
    end

    @testset "standard emoji" begin
        e = JSON3.read("""{"id": null, "name": "🔥"}""", Emoji)
        @test e.id === nothing
        @test e.name == "🔥"
        @test e.roles === missing
        @test JSON3.read(JSON3.write(e), Emoji) == e
    end

    @testset "guild endpoints" begin
        fake = fakehttp(response(200; body="[$emoji_json]"))
        emojis = list_guild_emojis(fastapi(fake), 41771983423143936)
        req = only(fake.requests)
        @test req.method == "GET"
        @test req.url == "https://discord.com/api/v10/guilds/41771983423143936/emojis"
        @test emojis isa Vector{Emoji}
        @test only(emojis).name == "LUL"

        fake = fakehttp(response(201; body=emoji_json))
        e = create_guild_emoji(fastapi(fake), 41771983423143936;
                               name="LUL", image="data:image/png;base64,aWFtYQ==",
                               reason="more LUL")
        req = only(fake.requests)
        @test req.method == "POST"
        @test ("X-Audit-Log-Reason" => "more%20LUL") in req.headers
        sent = sent_json(fake)
        @test sent.name == "LUL"
        @test sent.image == "data:image/png;base64,aWFtYQ=="
        @test e isa Emoji && e.id == Snowflake(41771983429993937)

        fake = fakehttp(response(204))
        @test delete_guild_emoji(fastapi(fake), 1, 2; reason="rip") === nothing
        req = only(fake.requests)
        @test req.method == "DELETE"
        @test req.url == "https://discord.com/api/v10/guilds/1/emojis/2"
        @test ("X-Audit-Log-Reason" => "rip") in req.headers
    end

    @testset "application endpoints" begin
        fake = fakehttp(response(200; body="""{"items": [$emoji_json]}"""))
        result = list_application_emojis(fastapi(fake), 1071)
        @test only(fake.requests).url ==
              "https://discord.com/api/v10/applications/1071/emojis"
        @test length(result.items) == 1

        fake = fakehttp(response(200; body=emoji_json))
        e = modify_application_emoji(fastapi(fake), 1071, 41771983429993937; name="LUL")
        req = only(fake.requests)
        @test req.method == "PATCH"
        @test req.url ==
              "https://discord.com/api/v10/applications/1071/emojis/41771983429993937"
        @test sent_json(fake).name == "LUL"
        @test e isa Emoji
    end
end

@testset "stickers" begin
    sticker_json = """
    {
        "id": "749054660769218631",
        "name": "Wave",
        "tags": "wumpus, hello, sup, hi, oi",
        "type": 1,
        "format_type": 3,
        "description": "Wumpus waves hello",
        "pack_id": "847199849233514549",
        "sort_value": 12
    }
    """
    pack_json = """
    {
        "id": "847199849233514549",
        "stickers": [$sticker_json],
        "name": "Wumpus Beyond",
        "sku_id": "847199849233514547",
        "cover_sticker_id": "749053689419006003",
        "description": "Say hello to Wumpus!",
        "banner_asset_id": "761773777976819732"
    }
    """

    @testset "round-trip" begin
        s = JSON3.read(sticker_json, Sticker)
        @test s.id == Snowflake(749054660769218631)
        @test s.type === StickerTypes.STANDARD
        @test s.format_type === StickerFormatTypes.LOTTIE
        @test s.pack_id == Snowflake(847199849233514549)
        @test s.available === missing
        @test JSON3.read(JSON3.write(s), Sticker) == s

        p = JSON3.read(pack_json, StickerPack)
        @test p.name == "Wumpus Beyond"
        @test only(p.stickers) == s
        @test JSON3.read(JSON3.write(p), StickerPack) == p

        item = JSON3.read("""{"id": "1", "name": "Wave", "format_type": 4}""", StickerItem)
        @test item.format_type === StickerFormatTypes.GIF
        @test JSON3.read(JSON3.write(item), StickerItem) == item
    end

    @testset "pack endpoints" begin
        fake = fakehttp(response(200; body="""{"sticker_packs": [$pack_json]}"""))
        result = list_sticker_packs(fastapi(fake))
        @test only(fake.requests).url == "https://discord.com/api/v10/sticker-packs"
        @test length(result.sticker_packs) == 1

        fake = fakehttp(response(200; body=pack_json))
        p = get_sticker_pack(fastapi(fake), 847199849233514549)
        @test only(fake.requests).url ==
              "https://discord.com/api/v10/sticker-packs/847199849233514549"
        @test p isa StickerPack && p.sku_id == Snowflake(847199849233514547)
    end

    @testset "guild endpoints" begin
        fake = fakehttp(response(200; body=sticker_json))
        s = get_sticker(fastapi(fake), 749054660769218631)
        @test only(fake.requests).url ==
              "https://discord.com/api/v10/stickers/749054660769218631"
        @test s isa Sticker && s.name == "Wave"

        fake = fakehttp(response(201; body=sticker_json))
        s = create_guild_sticker(fastapi(fake), 9, DiscordFile("wave.png", "fakepng");
                                 name="Wave", description="Wumpus waves hello",
                                 tags="wave", reason="fresh sticker")
        req = only(fake.requests)
        @test req.method == "POST"
        @test req.url == "https://discord.com/api/v10/guilds/9/stickers"
        @test ("X-Audit-Log-Reason" => "fresh%20sticker") in req.headers
        @test req.body isa HTTP.Form
        io = IOBuffer()
        write(io, req.body)
        raw = String(take!(io))
        @test occursin("name=\"file\"", raw) && occursin("wave.png", raw)
        @test occursin("name=\"tags\"", raw) && occursin("wave", raw)
        @test s isa Sticker

        fake = fakehttp(response(200; body=sticker_json))
        modify_guild_sticker(fastapi(fake), 9, 749054660769218631;
                             description=nothing, reason="tidy")
        req = only(fake.requests)
        @test req.method == "PATCH"
        @test req.url ==
              "https://discord.com/api/v10/guilds/9/stickers/749054660769218631"
        @test sent_json(fake).description === nothing
        @test ("X-Audit-Log-Reason" => "tidy") in req.headers

        fake = fakehttp(response(204))
        @test delete_guild_sticker(fastapi(fake), 9, 749054660769218631) === nothing
        @test only(fake.requests).method == "DELETE"
    end
end
