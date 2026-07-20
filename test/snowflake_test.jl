using Dates
using JSON3
using Random: MersenneTwister

@testset "Snowflake" begin
    # the example ID from Discord's own docs
    id = Snowflake(175928847299117063)
    @test timestamp(id) == DateTime(2016, 4, 30, 11, 18, 25, 796)

    @test Snowflake("175928847299117063") == id
    @test snowflake(175928847299117063) == id
    @test snowflake(id) === id
    @test string(id) == "175928847299117063"
    @test UInt64(id) == 175928847299117063

    @test Snowflake(1) < Snowflake(2)
    @test Snowflake(42) == 42
    @test length(Set([Snowflake(1), Snowflake(1), Snowflake(2)])) == 2

    @testset "time cursor" begin
        t = DateTime(2024, 6, 1)
        cursor = Snowflake(t)
        @test timestamp(cursor) == t
        @test cursor < Snowflake(t + Second(1))
    end

    @testset "JSON" begin
        @test JSON3.write(id) == "\"175928847299117063\""
        @test JSON3.read("\"175928847299117063\"", Snowflake) == id
        # a few payloads carry snowflakes as bare numbers; the field-level
        # deserializer accepts them
        @test Nobelium._reconstruct(Snowflake, 175928847299117063) == id
    end

    @testset "value round-trip" begin
        rng = MersenneTwister(2015)
        for _ in 1:100
            v = rand(rng, UInt64) >> rand(rng, 0:20)
            @test Snowflake(string(v)).value == v
            @test JSON3.read(JSON3.write(Snowflake(v)), Snowflake).value == v
        end
    end
end
