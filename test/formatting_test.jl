using Dates

@testset "formatting" begin
    @test mention_user(80351110224678912) == "<@80351110224678912>"
    @test mention_channel("103735883630395392") == "<#103735883630395392>"
    @test mention_role(Snowflake(165511591545143296)) == "<@&165511591545143296>"
    @test mention_command("airhorn", 816437322781949972) == "</airhorn:816437322781949972>"
    @test emoji_tag("party", 1234) == "<:party:1234>"
    @test emoji_tag("wave", 1234; animated=true) == "<a:wave:1234>"

    t = DateTime(2021, 7, 1, 12, 0, 0)
    @test discord_timestamp(t) == "<t:1625140800:f>"
    @test discord_timestamp(t; style=:R) == "<t:1625140800:R>"
    @test_throws ArgumentError discord_timestamp(t; style=:x)

    @test inline_code("x = 1") == "`x = 1`"
    @test code_block("x = 1"; language="julia") == "```julia\nx = 1\n```"
    @test escape_markdown("*hi* _there_") == "\\*hi\\* \\_there\\_"
end
