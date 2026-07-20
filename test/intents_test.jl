using JSON3

@testset "Intents" begin
    @test Intent.guilds.value == 1 << 0
    @test Intent.message_content.value == 1 << 15
    @test Intent.direct_message_polls.value == 1 << 25

    @test Intent.privileged ==
          Intent.guild_members | Intent.guild_presences | Intent.message_content
    @test iszero(Intent.default & Intent.privileged)
    @test Intent.default | Intent.privileged == Intent.all

    combined = Intent.guilds | Intent.guild_messages | Intent.message_content
    @test Intent.guilds in combined
    @test !(Intent.guild_members in combined)

    # intents go over the wire as numbers, not strings
    @test JSON3.write(combined) == string(combined.value)
    @test JSON3.read(JSON3.write(combined), Intents) == combined
end
