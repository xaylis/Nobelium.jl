using JSON3
using StructTypes
using Dates
using Nobelium: EVENT_TYPES

@testset "gateway dispatch events" begin
    @testset "Ready" begin
        json = """
        {
            "v": 10,
            "user": {"id": "1", "username": "bot", "discriminator": "0000"},
            "guilds": [{"id": "2", "unavailable": true}, {"id": "3"}],
            "session_id": "sess123",
            "resume_gateway_url": "wss://gateway.discord.gg",
            "shard": [0, 1],
            "application": {"id": "9", "flags": 0}
        }
        """
        ready = StructTypes.construct(Ready, JSON3.read(json))
        @test ready isa Ready
        @test ready.v == 10
        @test ready.user.username == "bot"
        @test length(ready.guilds) == 2
        @test ready.guilds[1].id == Snowflake(2)
        @test ready.guilds[1].unavailable === true
        @test ready.guilds[2].unavailable === missing
        @test ready.session_id == "sess123"
        @test ready.resume_gateway_url == "wss://gateway.discord.gg"
        @test ready.shard == [0, 1]
        @test ready.application.id == Snowflake(9)
    end

    @testset "GuildCreate" begin
        json = """
        {
            "id": "100",
            "name": "Test Guild",
            "joined_at": "2017-07-11T17:27:07.299000+00:00",
            "large": false,
            "member_count": 2,
            "voice_states": [],
            "members": [
                {"user": {"id": "5", "username": "a", "discriminator": "0001"},
                 "roles": [], "joined_at": "2017-07-11T17:27:07.299000+00:00",
                 "deaf": false, "mute": false, "flags": 0}
            ],
            "channels": [
                {"id": "10", "type": 0, "name": "general"}
            ],
            "threads": [],
            "presences": []
        }
        """
        ev = StructTypes.construct(GuildCreate, JSON3.read(json))
        @test ev isa GuildCreate
        @test ev.guild isa Guild
        @test ev.guild.id == Snowflake(100)
        @test ev.guild.name == "Test Guild"
        @test ev.large === false
        @test ev.member_count == 2
        @test length(ev.members) == 1
        @test ev.members[1].user.username == "a"
        @test length(ev.channels) == 1
        @test ev.channels[1].name == "general"
        @test ev.unavailable === missing
        @test ev.stage_instances === missing
    end

    @testset "MessageCreate" begin
        json = """
        {
            "id": "200",
            "channel_id": "300",
            "guild_id": "400",
            "author": {"id": "5", "username": "author", "discriminator": "0001"},
            "content": "hello world",
            "timestamp": "2017-07-11T17:27:07.299000+00:00",
            "edited_timestamp": null,
            "tts": false,
            "mention_everyone": false,
            "mentions": [],
            "mention_roles": [],
            "attachments": [],
            "embeds": [],
            "pinned": false,
            "type": 0
        }
        """
        ev = StructTypes.construct(MessageCreate, JSON3.read(json))
        @test ev isa MessageCreate
        @test ev.message isa Message
        @test ev.message.id == Snowflake(200)
        @test ev.message.content == "hello world"
        @test ev.guild_id == Snowflake(400)
        @test ev.member === missing
    end

    @testset "MessageDelete" begin
        json = """{"id": "1", "channel_id": "2", "guild_id": "3"}"""
        ev = StructTypes.construct(MessageDelete, JSON3.read(json))
        @test ev isa MessageDelete
        @test ev.id == Snowflake(1)
        @test ev.channel_id == Snowflake(2)
        @test ev.guild_id == Snowflake(3)

        json2 = """{"id": "1", "channel_id": "2"}"""
        ev2 = StructTypes.construct(MessageDelete, JSON3.read(json2))
        @test ev2.guild_id === missing
    end

    @testset "TypingStart" begin
        json = """
        {
            "channel_id": "1",
            "guild_id": "2",
            "user_id": "3",
            "timestamp": 1500000000,
            "member": {"roles": [], "joined_at": "2017-07-11T17:27:07.299000+00:00",
                       "deaf": false, "mute": false, "flags": 0}
        }
        """
        ev = StructTypes.construct(TypingStart, JSON3.read(json))
        @test ev isa TypingStart
        @test ev.channel_id == Snowflake(1)
        @test ev.guild_id == Snowflake(2)
        @test ev.user_id == Snowflake(3)
        @test ev.timestamp == 1500000000
        @test ev.member isa GuildMember

        json2 = """{"channel_id": "1", "user_id": "3", "timestamp": 1500000000}"""
        ev2 = StructTypes.construct(TypingStart, JSON3.read(json2))
        @test ev2.guild_id === missing
        @test ev2.member === missing
    end

    @testset "MessageReactionAdd" begin
        json = """
        {
            "user_id": "1",
            "channel_id": "2",
            "message_id": "3",
            "guild_id": "4",
            "emoji": {"id": null, "name": "🔥"},
            "message_author_id": "5",
            "burst": false,
            "type": 0
        }
        """
        ev = StructTypes.construct(MessageReactionAdd, JSON3.read(json))
        @test ev isa MessageReactionAdd
        @test ev.user_id == Snowflake(1)
        @test ev.emoji.name == "🔥"
        @test ev.emoji.id === nothing
        @test ev.message_author_id == Snowflake(5)
        @test ev.burst === false
        @test ev.type == 0
        @test ev.member === missing
    end

    @testset "PresenceUpdate" begin
        json = """
        {
            "user": {"id": "1"},
            "guild_id": "2",
            "status": "online",
            "activities": [
                {"name": "Rocket League", "type": 0, "created_at": 1234567,
                 "timestamps": {"start": 1000}, "party": {"id": "p1", "size": [2, 4]},
                 "assets": {"large_image": "img", "large_text": "text"}}
            ],
            "client_status": {"desktop": "online"}
        }
        """
        ev = StructTypes.construct(PresenceUpdate, JSON3.read(json))
        @test ev isa PresenceUpdate
        @test ev.guild_id == Snowflake(2)
        @test ev.status == "online"
        @test length(ev.activities) == 1
        act = ev.activities[1]
        @test act.name == "Rocket League"
        @test act.type == ActivityTypes.GAME
        @test act.timestamps.start == 1000
        @test act.party.id == "p1"
        @test act.party.size == [2, 4]
        @test act.assets.large_image == "img"
        @test ev.client_status.desktop == "online"
        @test ev.client_status.mobile === missing

        # Discord guarantees no presence fields beyond user.id.
        bare = StructTypes.construct(PresenceUpdate, JSON3.read("""{"user": {"id": "1"}}"""))
        @test bare.status === missing
        @test bare.activities === missing
        @test bare.client_status === missing
    end

    @testset "GuildMembersChunk" begin
        json = """
        {
            "guild_id": "1",
            "members": [
                {"user": {"id": "2", "username": "u", "discriminator": "0001"},
                 "roles": [], "joined_at": "2017-07-11T17:27:07.299000+00:00",
                 "deaf": false, "mute": false, "flags": 0}
            ],
            "chunk_index": 0,
            "chunk_count": 1,
            "nonce": "abc"
        }
        """
        ev = StructTypes.construct(GuildMembersChunk, JSON3.read(json))
        @test ev isa GuildMembersChunk
        @test ev.guild_id == Snowflake(1)
        @test length(ev.members) == 1
        @test ev.chunk_index == 0
        @test ev.chunk_count == 1
        @test ev.nonce == "abc"
        @test ev.not_found === missing
        @test ev.presences === missing
    end

    @testset "InvalidSession" begin
        ev = StructTypes.construct(InvalidSession, JSON3.read("true"))
        @test ev isa InvalidSession
        @test ev.resumable === true
    end

    @testset "no-payload events" begin
        @test Resumed() isa Resumed
        @test Reconnect() isa Reconnect
    end

    @testset "EVENT_TYPES" begin
        @test EVENT_TYPES["READY"] === Ready
        @test EVENT_TYPES["GUILD_CREATE"] === GuildCreate
        @test EVENT_TYPES["MESSAGE_CREATE"] === MessageCreate
        @test EVENT_TYPES["MESSAGE_DELETE"] === MessageDelete
        @test EVENT_TYPES["TYPING_START"] === TypingStart
        @test EVENT_TYPES["MESSAGE_REACTION_ADD"] === MessageReactionAdd
        @test EVENT_TYPES["PRESENCE_UPDATE"] === PresenceUpdate
        @test EVENT_TYPES["GUILD_MEMBERS_CHUNK"] === GuildMembersChunk
        @test EVENT_TYPES["RESUMED"] === Resumed
        @test EVENT_TYPES["RECONNECT"] === Reconnect
        @test EVENT_TYPES["VOICE_STATE_UPDATE"] === VoiceStateUpdate
        @test EVENT_TYPES["WEBHOOKS_UPDATE"] === WebhooksUpdate
        @test length(EVENT_TYPES) >= 75
        @test all(v -> v <: AbstractEvent, values(EVENT_TYPES))
    end
end
