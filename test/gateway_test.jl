using JSON3
using Nobelium: Shard, Opcode, handle_payload!

# The shard state machine is transport-agnostic; feed it payloads directly and
# capture what it sends back.
mutable struct FakeWS
    sent::Vector{Any}
    closed::Union{Int,Nothing}
end
FakeWS() = FakeWS([], nothing)
Nobelium.send_message(ws::FakeWS, s::AbstractString) = push!(ws.sent, JSON3.read(s))
Nobelium.close_ws(ws::FakeWS, code::Int) = (ws.closed = code)

function testshard()
    client = Client("test-token"; intents=Intent.guilds | Intent.guild_messages)
    shard = Shard(0, 1, client)
    shard.ws = FakeWS()
    shard.running = true
    client, shard
end

hello(interval_ms=45_000) = """{"op":10,"d":{"heartbeat_interval":$interval_ms}}"""
dispatch(t, d; s=1) = """{"op":0,"s":$s,"t":"$t","d":$d}"""

const READY_D = """{
    "v": 10,
    "user": {"id":"1","username":"bot","discriminator":"0","global_name":null,"avatar":null,"bot":true},
    "guilds": [{"id":"1392713127724060802","unavailable":true}],
    "session_id": "sess-1",
    "resume_gateway_url": "wss://resume.example",
    "shard": [0, 1],
    "application": {"id": "42", "flags": 0}
}"""

@testset "gateway shard" begin
    @testset "hello triggers identify" begin
        client, shard = testshard()
        handle_payload!(shard, hello(41_250))
        @test shard.heartbeat_interval ≈ 41.25
        ident = only(shard.ws.sent)
        @test ident.op == Opcode.identify
        @test ident.d.token == "test-token"
        @test ident.d.intents == (Intent.guilds | Intent.guild_messages).value
        @test ident.d.shard == [0, 1]
    end

    @testset "hello with a session resumes instead" begin
        client, shard = testshard()
        shard.session_id = "sess-1"
        shard.seq = 100
        handle_payload!(shard, hello())
        resume = only(shard.ws.sent)
        @test resume.op == Opcode.resume
        @test resume.d.session_id == "sess-1"
        @test resume.d.seq == 100
    end

    @testset "heartbeat request answered with seq" begin
        client, shard = testshard()
        shard.seq = 7
        handle_payload!(shard, """{"op":1,"d":null}""")
        beat = only(shard.ws.sent)
        @test beat.op == Opcode.heartbeat && beat.d == 7
    end

    @testset "heartbeat ack tracked" begin
        client, shard = testshard()
        shard.acked = false
        shard.last_beat = time() - 0.05
        handle_payload!(shard, """{"op":11}""")
        @test shard.acked
        @test 0 < shard.latency < 5
    end

    @testset "reconnect closes for resume" begin
        client, shard = testshard()
        handle_payload!(shard, """{"op":7,"d":null}""")
        @test shard.ws.closed == 4000
    end

    @testset "invalid session, resumable" begin
        client, shard = testshard()
        shard.session_id = "sess-1"
        shard.seq = 3
        handle_payload!(shard, """{"op":9,"d":true}""")
        @test only(shard.ws.sent).op == Opcode.resume
    end

    @testset "invalid session, not resumable" begin
        client, shard = testshard()
        shard.session_id = "sess-1"
        shard.seq = 3
        handle_payload!(shard, """{"op":9,"d":false}""")   # sleeps 1-5s by design
        @test shard.session_id === nothing
        ident = only(shard.ws.sent)
        @test ident.op == Opcode.identify
    end

    @testset "ready stores session state and dispatches" begin
        client, shard = testshard()
        got = Channel{Any}(1)
        on!((c, ev) -> put!(got, ev), client, Ready)
        handle_payload!(shard, dispatch("READY", READY_D))
        @test shard.session_id == "sess-1"
        @test shard.resume_url == "wss://resume.example"
        @test shard.seq == 1
        ev = take!(got)
        @test ev isa Ready
        @test ev.user.bot === true
        @test only(ev.guilds).id == Snowflake(1392713127724060802)
    end

    @testset "message create dispatches and caches" begin
        client, shard = testshard()
        got = Channel{Any}(1)
        on!((c, ev) -> put!(got, ev), client, MessageCreate)
        d = """{
            "id": "999", "channel_id": "10", "guild_id": "20",
            "author": {"id":"5","username":"u","discriminator":"0","global_name":null,"avatar":null},
            "content": "hi there", "timestamp": "2026-07-19T12:00:00.000000+00:00",
            "edited_timestamp": null, "tts": false, "mention_everyone": false,
            "mentions": [], "mention_roles": [], "attachments": [], "embeds": [],
            "pinned": false, "type": 0
        }"""
        handle_payload!(shard, dispatch("MESSAGE_CREATE", d; s=2))
        ev = take!(got)
        @test ev isa MessageCreate
        @test ev.message.content == "hi there"
        @test ev.guild_id == Snowflake(20)
        @test get(client.cache.messages, Snowflake(999), nothing) !== nothing
        @test get(client.cache.users, Snowflake(5), nothing) !== nothing
    end

    @testset "unknown events don't crash" begin
        client, shard = testshard()
        got = Channel{Any}(1)
        on!((c, ev) -> put!(got, ev), client, UnknownEvent)
        handle_payload!(shard, dispatch("SOME_FUTURE_THING", """{"x":1}"""))
        ev = take!(got)
        @test ev isa UnknownEvent
        @test ev.name == "SOME_FUTURE_THING"
        @test ev.data.x == 1
    end

    @testset "wait_for" begin
        client, shard = testshard()
        t = @async wait_for(client, MessageDelete; timeout=10) do c, ev
            ev.id == Snowflake(1)
        end
        sleep(0.1)
        handle_payload!(shard, dispatch("MESSAGE_DELETE", """{"id":"2","channel_id":"9"}"""))
        handle_payload!(shard, dispatch("MESSAGE_DELETE", """{"id":"1","channel_id":"9"}"""))
        ev = fetch(t)
        @test ev isa MessageDelete && ev.id == Snowflake(1)

        @test wait_for(client, MessageDelete; timeout=0.1) === nothing
    end

    @testset "off! removes handlers" begin
        client, shard = testshard()
        hits = Ref(0)
        f = on!((c, ev) -> (hits[] += 1), client, MessageDelete)
        handle_payload!(shard, dispatch("MESSAGE_DELETE", """{"id":"1","channel_id":"9"}"""))
        sleep(0.2)
        off!(client, MessageDelete, f)
        handle_payload!(shard, dispatch("MESSAGE_DELETE", """{"id":"2","channel_id":"9"}"""))
        sleep(0.2)
        @test hits[] == 1
    end
end

@testset "cache store" begin
    s = Nobelium.Store{Int,String}(3)
    s[1] = "a"; s[2] = "b"; s[3] = "c"
    @test get(s, 1, nothing) == "a"
    @test length(s) == 3
    s[4] = "d"                      # overflow: oldest entries evicted
    @test length(s) <= 3
    @test get(s, 4, nothing) == "d"
    delete!(s, 4)
    @test get(s, 4, nothing) === nothing
end
