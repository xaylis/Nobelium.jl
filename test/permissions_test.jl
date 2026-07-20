using JSON3
using Random: MersenneTwister

@testset "Permissions" begin
    mod = Permission.kick_members | Permission.ban_members | Permission.moderate_members

    @test has_permission(mod, Permission.kick_members)
    @test !has_permission(mod, Permission.manage_guild)
    @test has_permission(mod, Permission.kick_members | Permission.ban_members)
    @test !has_permission(mod, Permission.kick_members | Permission.manage_guild)

    # administrator implies everything
    @test has_permission(Permission.administrator, Permission.manage_guild)
    @test has_permission(Permission.administrator, Permission.all)

    # spot-check bit positions against the documented table
    @test Permission.create_instant_invite.value == 1 << 0
    @test Permission.moderate_members.value == UInt64(1) << 40
    @test Permission.bypass_slowmode.value == UInt64(1) << 52

    @testset "string wire format" begin
        @test JSON3.write(mod) == "\"$(mod.value)\""
        @test JSON3.read("\"104324673\"", Permissions).value == 104324673
        rng = MersenneTwister(4)
        for _ in 1:50
            p = Permissions(rand(rng, UInt64) & Permission.all.value)
            @test JSON3.read(JSON3.write(p), Permissions) == p
        end
    end
end
