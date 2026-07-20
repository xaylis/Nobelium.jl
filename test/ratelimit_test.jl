using Nobelium: RateLimiter, Route, acquire!, update!, pause_globally!, bucket_key, path

# A fake clock that only advances when something sleeps on it.
mutable struct FakeClock
    now::Float64
    slept::Vector{Float64}
end
FakeClock() = FakeClock(0.0, Float64[])
clockfn(c::FakeClock) = () -> c.now
sleepfn(c::FakeClock) = dt -> (push!(c.slept, dt); c.now += dt)

@testset "routes" begin
    r = Route(:GET, "/channels/{channel_id}/messages/{message_id}")
    @test path(r, 1, 2) == "/channels/1/messages/2"
    @test_throws ArgumentError path(r, 1)
    @test_throws ArgumentError path(r, 1, 2, 3)

    # emoji get percent-encoded
    re = Route(:PUT, "/channels/{channel_id}/messages/{message_id}/reactions/{emoji}/@me")
    @test path(re, 1, 2, "party:123") == "/channels/1/messages/2/reactions/party%3A123/@me"

    # message id is a minor param: same bucket either way. channel is major.
    @test bucket_key(r, 10, 1) == bucket_key(r, 10, 2)
    @test bucket_key(r, 10, 1) != bucket_key(r, 11, 1)
    @test bucket_key(Route(:GET, "/gateway/bot")) == bucket_key(Route(:GET, "/gateway/bot"))
end

@testset "rate limiter" begin
    @testset "bucket exhaustion waits for reset" begin
        c = FakeClock()
        rl = RateLimiter(clock=clockfn(c), sleeper=sleepfn(c))
        update!(rl, "k"; bucket="abc", remaining=1, reset_after=5.0)
        acquire!(rl, "k")            # uses the last slot
        acquire!(rl, "k")            # must wait out the reset
        @test sum(c.slept) ≈ 5.0
        @test c.now ≈ 5.0
    end

    @testset "routes sharing a Discord bucket share limits" begin
        c = FakeClock()
        rl = RateLimiter(clock=clockfn(c), sleeper=sleepfn(c))
        update!(rl, "route-a"; bucket="shared", remaining=0, reset_after=3.0)
        update!(rl, "route-b"; bucket="shared", remaining=0, reset_after=3.0)
        acquire!(rl, "route-b")
        @test c.now ≈ 3.0
    end

    @testset "separate major params don't interfere" begin
        c = FakeClock()
        rl = RateLimiter(clock=clockfn(c), sleeper=sleepfn(c))
        update!(rl, "chan-1"; remaining=0, reset_after=60.0)
        acquire!(rl, "chan-2")
        @test isempty(c.slept)
    end

    @testset "global window" begin
        c = FakeClock()
        rl = RateLimiter(clock=clockfn(c), sleeper=sleepfn(c), global_limit=3)
        for _ in 1:3
            acquire!(rl, "x")
        end
        @test isempty(c.slept)
        acquire!(rl, "x")            # fourth within the same second must wait
        @test c.now >= 1.0
    end

    @testset "global pause" begin
        c = FakeClock()
        rl = RateLimiter(clock=clockfn(c), sleeper=sleepfn(c))
        pause_globally!(rl, 7.5)
        acquire!(rl, "anything")
        @test c.now ≈ 7.5
    end
end
