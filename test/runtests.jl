using Nobelium
using Test

@testset "Nobelium" begin
    include("util.jl")
    include("snowflake_test.jl")
    include("json_test.jl")
    include("permissions_test.jl")
    include("intents_test.jl")
    include("errors_test.jl")
    include("formatting_test.jl")
    include("ratelimit_test.jl")
    include("rest_test.jl")
    include("expressions_test.jl")
    include("guild_test.jl")
    include("channel_test.jl")
    include("application_test.jl")
    include("guild_features_test.jl")
    include("components_test.jl")
    include("message_test.jl")
    include("webhook_invite_test.jl")
    include("moderation_test.jl")
    include("monetization_test.jl")
    include("interaction_rest_test.jl")
    include("events_test.jl")
    include("gateway_test.jl")
    include("voice_test.jl")
end
