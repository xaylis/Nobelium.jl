using Dates
using JSON3
using Nobelium: @discord_object, @discord_enum, @discord_flags, discord_datetime

@discord_enum Fruit UInt8 APPLE=1 BANANA=2 CHERRY=3

@discord_flags Toppings UInt8 :number begin
    sprinkles = 1 << 0
    fudge = 1 << 1
    cream = 1 << 2
end

@discord_object struct Bowl
    id::Snowflake
    fruit::Fruit
    label::Optional{String}
    note::OptionalNullable{String}
    lid_id::Nullable{Snowflake}
end

@discord_object struct Pantry
    id::Snowflake
    bowls::Vector{Bowl}
    favorite::OptionalNullable{Bowl}
    restocked_at::Optional{DateTime}
    toppings::Optional{Toppings}
end

@testset "JSON model" begin
    @testset "absent vs null" begin
        b = JSON3.read("""{"id":"1","fruit":1,"note":null,"lid_id":null}""", Bowl)
        @test b.label === missing      # absent
        @test b.note === nothing       # explicit null
        @test b.lid_id === nothing

        out = JSON3.write(b)
        @test !occursin("label", out)              # missing stays absent
        @test occursin("\"note\":null", out)       # nothing stays null
        @test occursin("\"id\":\"1\"", out)        # snowflakes are strings

        # absent OptionalNullable reads back as missing, not nothing
        b2 = JSON3.read("""{"id":"1","fruit":1,"lid_id":null}""", Bowl)
        @test b2.note === missing
        @test !occursin("note", JSON3.write(b2))
    end

    @testset "required fields" begin
        @test_throws ArgumentError JSON3.read("""{"fruit":1,"lid_id":null}""", Bowl)
        err = try
            JSON3.read("""{"fruit":1,"lid_id":null}""", Bowl)
        catch e
            e
        end
        @test occursin("Bowl", err.msg) && occursin("id", err.msg)
    end

    @testset "enums" begin
        @test Fruits.APPLE == 1
        @test JSON3.write(Fruits.BANANA) == "2"
        @test JSON3.read("3", Fruit) === Fruits.CHERRY
        # unknown values survive a round-trip
        mystery = JSON3.read("77", Fruit)
        @test mystery == 77
        @test JSON3.write(mystery) == "77"
        @test sprint(show, Fruits.APPLE) == "Fruits.APPLE"
        @test sprint(show, mystery) == "Fruit(77)"
    end

    @testset "flags" begin
        both = Topping.sprinkles | Topping.fudge
        @test Topping.sprinkles in both
        @test !(Topping.cream in both)
        @test both & Topping.fudge == Topping.fudge
        @test ~Topping.sprinkles == Topping.fudge | Topping.cream
        @test iszero(Topping.none)
        @test JSON3.write(both) == "3"
        @test JSON3.read("3", Toppings) == both
        @test sprint(show, both) == "Topping.sprinkles | Topping.fudge"
        @test sprint(show, Topping.none) == "Topping.none"
    end

    @testset "nesting and vectors" begin
        p = JSON3.read("""{
            "id": "10",
            "bowls": [
                {"id":"1","fruit":1,"lid_id":null},
                {"id":"2","fruit":2,"label":"snack","lid_id":"7"}
            ],
            "favorite": {"id":"2","fruit":2,"label":"snack","lid_id":"7"},
            "restocked_at": "2017-07-11T17:27:07.299000+00:00",
            "toppings": 5
        }""", Pantry)
        @test length(p.bowls) == 2
        @test p.bowls[2].lid_id == Snowflake(7)
        @test p.favorite == p.bowls[2]
        @test p.restocked_at == DateTime(2017, 7, 11, 17, 27, 7, 299)
        @test p.toppings == Topping.sprinkles | Topping.cream
        @test JSON3.read(JSON3.write(p), Pantry) == p
    end

    @testset "keyword construction" begin
        b = Bowl(id=2, fruit=Fruits.BANANA, label="snack", lid_id=7)
        @test b == JSON3.read("""{"id":"2","fruit":2,"label":"snack","lid_id":"7"}""", Bowl)
        @test Bowl(id=1, fruit=Fruits.APPLE, lid_id=nothing).note === missing
    end

    @testset "show stays compact" begin
        b = Bowl(id=1, fruit=Fruits.APPLE, lid_id=nothing)
        @test sprint(show, b) == "Bowl(id=Snowflake(1), fruit=Fruits.APPLE, lid_id=nothing)"
        p = Pantry(id=1, bowls=[b, b, b])
        @test occursin("[3 items]", sprint(show, p))
    end

    @testset "timestamps" begin
        @test discord_datetime("2021-08-29T00:00:00+00:00") == DateTime(2021, 8, 29)
        @test discord_datetime("2017-07-11T17:27:07.299000+00:00") ==
              DateTime(2017, 7, 11, 17, 27, 7, 299)
        @test discord_datetime("2017-07-11T17:27:07.5+00:00") ==
              DateTime(2017, 7, 11, 17, 27, 7, 500)
        @test_throws ArgumentError discord_datetime("not a date")
    end
end
