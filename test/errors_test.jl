using JSON3
using Nobelium: redact, flatten_errors

@testset "errors" begin
    @testset "token redaction" begin
        # same shape as a real bot token, same length, not a real one
        fake = "RkFLRVRPS0VORkFLRVRPS0VO.GaBcDe.0123456789abcdefghijklmnopqrstuvwxyzAB"
        @test !occursin(fake, redact("Authorization: Bot $fake failed"))
        @test occursin("<token>", redact(fake))
        @test occursin("<token>", redact("mfa.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"))
        # ordinary text is left alone
        @test redact("hello.world") == "hello.world"

        e = APIError(401, 0, "401: Unauthorized with $fake")
        @test !occursin(fake, sprint(showerror, e))
    end

    @testset "APIError display" begin
        e = APIError(400, 50035, "Invalid Form Body",
                     ["embeds.0.title" => "Must be 1024 or fewer in length."])
        msg = sprint(showerror, e)
        @test occursin("HTTP 400", msg)
        @test occursin("50035", msg)
        @test occursin("embeds.0.title", msg)
    end

    @testset "flatten_errors" begin
        tree = JSON3.read("""{
            "embeds": {"0": {"title": {"_errors": [{"code": "X", "message": "too long"}]}}},
            "content": {"_errors": [{"code": "Y", "message": "required"}]}
        }""")
        flat = Dict(flatten_errors(tree))
        @test flat["embeds.0.title"] == "too long"
        @test flat["content"] == "required"
    end

    @testset "GatewayClosedError" begin
        e = GatewayClosedError(4014, "Disallowed intent(s)", false)
        msg = sprint(showerror, e)
        @test occursin("4014", msg) && occursin("not resumable", msg)
    end
end
