using HTTP
using JSON3
using Nobelium: RateLimiter, Route, request

const FAKE_TOKEN = "RkFLRVRPS0VORkFLRVRPS0VO.GaBcDe.0123456789abcdefghijklmnopqrstuvwxyzAB"

@testset "request pipeline" begin
    @testset "headers and url" begin
        fake = fakehttp(response(200; body="{\"id\":\"1\"}"))
        api = fastapi(fake)
        result = request(api, Route(:GET, "/users/{user_id}"), 42; into=Any)
        @test result.id == "1"
        req = only(fake.requests)
        @test req.method == "GET"
        @test req.url == "https://discord.com/api/v10/users/42"
        @test ("Authorization" => "Bot test-token") in req.headers
        @test any(h -> h.first == "User-Agent" && startswith(h.second, "DiscordBot"), req.headers)
    end

    @testset "auth modes" begin
        for (auth, expected) in (:bearer => "Bearer test-token", :none => nothing)
            fake = fakehttp(response(204))
            request(fastapi(fake), Route(:GET, "/gateway"); auth)
            auths = [h.second for h in only(fake.requests).headers if h.first == "Authorization"]
            @test auths == (expected === nothing ? [] : [expected])
        end
        @test_throws ArgumentError request(fastapi(fakehttp()), Route(:GET, "/gateway"); auth=:wat)
    end

    @testset "body filtering" begin
        fake = fakehttp(response(200; body="{}"))
        request(fastapi(fake), Route(:POST, "/channels/{channel_id}/messages"), 1;
                body=(content="hi", topic=nothing, nick=missing))
        sent = JSON3.read(only(fake.requests).body)
        @test sent.content == "hi"
        @test sent.topic === nothing         # nothing => null
        @test !haskey(sent, :nick)           # missing => absent
        @test ("Content-Type" => "application/json") in only(fake.requests).headers
    end

    @testset "query params" begin
        fake = fakehttp(response(204))
        request(fastapi(fake), Route(:GET, "/guilds/{guild_id}/members"), 9;
                query=(limit=5, after=missing))
        @test endswith(only(fake.requests).url, "/guilds/9/members?limit=5")
    end

    @testset "audit log reason" begin
        fake = fakehttp(response(204))
        request(fastapi(fake), Route(:DELETE, "/channels/{channel_id}"), 1; reason="spam channel")
        @test ("X-Audit-Log-Reason" => "spam%20channel") in only(fake.requests).headers
    end

    @testset "multipart files" begin
        fake = fakehttp(response(200; body="{}"))
        request(fastapi(fake), Route(:POST, "/channels/{channel_id}/messages"), 1;
                body=(content="attached",), files=[DiscordFile("a.txt", "hello")])
        req = only(fake.requests)
        @test req.body isa HTTP.Form
        io = IOBuffer()
        write(io, req.body)
        raw = String(take!(io))
        @test occursin("payload_json", raw)
        @test occursin("files[0]", raw)
        @test occursin("a.txt", raw)
        @test occursin("hello", raw)
    end

    @testset "404 raises APIError" begin
        fake = fakehttp(response(404; body="""{"code": 10003, "message": "Unknown Channel"}"""))
        err = try
            request(fastapi(fake), Route(:GET, "/channels/{channel_id}"), 1; into=Any)
        catch e
            e
        end
        @test err isa APIError
        @test err.status == 404 && err.code == 10003
        @test occursin("Unknown Channel", sprint(showerror, err))
    end

    @testset "validation errors are flattened" begin
        fake = fakehttp(response(400; body="""{
            "code": 50035, "message": "Invalid Form Body",
            "errors": {"content": {"_errors": [{"code": "MAX", "message": "too long"}]}}
        }"""))
        err = try
            request(fastapi(fake), Route(:POST, "/channels/{channel_id}/messages"), 1)
        catch e
            e
        end
        @test ("content" => "too long") in err.errors
    end

    @testset "token never appears in errors" begin
        fake = fakehttp(response(401; body="""{"message": "401: Unauthorized $FAKE_TOKEN"}"""))
        err = try
            request(fastapi(fake; token=FAKE_TOKEN), Route(:GET, "/users/@me"))
        catch e
            e
        end
        @test !occursin(FAKE_TOKEN, sprint(showerror, err))
    end

    @testset "429 then success" begin
        fake = fakehttp(
            response(429; body="""{"retry_after": 1.5, "global": false}"""),
            response(200; body="{\"ok\":true}"))
        @test request(fastapi(fake), Route(:GET, "/gateway"); into=Any).ok === true
        @test length(fake.requests) == 2
    end

    @testset "429 global pauses the limiter" begin
        slept = Float64[]
        limiter = RateLimiter(sleeper=dt -> push!(slept, dt))
        fake = fakehttp(
            response(429; body="""{"retry_after": 2.0, "global": true}"""),
            response(204))
        api = API("t"; http=fake, limiter)
        request(api, Route(:GET, "/gateway"))
        @test 2.0 in slept
        @test limiter.pause_until > 0
    end

    @testset "persistent 429 gives up" begin
        fake = fakehttp((response(429; body="""{"retry_after": 0.1}""") for _ in 1:10)...)
        @test_throws RateLimitedError request(fastapi(fake), Route(:GET, "/gateway"))
    end

    @testset "5xx retries then succeeds" begin
        fake = fakehttp(response(502), response(502), response(200; body="{\"ok\":true}"))
        @test request(fastapi(fake), Route(:GET, "/gateway"); into=Any).ok === true
    end

    @testset "5xx exhausts retries" begin
        fake = fakehttp((response(502; body="Bad Gateway") for _ in 1:5)...)
        err = try
            request(fastapi(fake), Route(:GET, "/gateway"))
        catch e
            e
        end
        @test err isa APIError && err.status == 502
    end

    @testset "connection errors retry" begin
        fake = fakehttp(ErrorException("boom"), response(204))
        @test request(fastapi(fake), Route(:GET, "/gateway")) === nothing
        @test length(fake.requests) == 2
    end

    @testset "rate limit headers feed the limiter" begin
        limiter = RateLimiter(sleeper=_ -> nothing)
        fake = fakehttp(response(200; body="{}",
                                 headers=["X-RateLimit-Bucket" => "abc123",
                                          "X-RateLimit-Remaining" => "3",
                                          "X-RateLimit-Reset-After" => "2.5"]))
        api = API("t"; http=fake, limiter)
        request(api, Route(:GET, "/users/{user_id}"), 7; into=Any)
        @test limiter.routes["GET /users/{user_id}"] == "abc123"
        @test limiter.buckets["abc123"].remaining == 3
    end
end
