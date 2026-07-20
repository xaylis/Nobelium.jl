using JSON3
using Dates

@testset "Component" begin
    @testset "action rows round-trip" begin
        fixture = read(joinpath(@__DIR__, "fixtures", "components_action_rows.json"), String)
        rows = JSON3.read(fixture, Vector{Component})
        @test length(rows) == 2
        @test all(r -> r isa ActionRow, rows)

        row1 = rows[1]
        @test row1.id == 1
        @test length(row1.components) == 2
        btn1, btn2 = row1.components
        @test btn1 isa Button
        @test btn1.style == ButtonStyles.PRIMARY
        @test btn1.label == "Click me"
        @test btn1.custom_id == "click_one"
        @test btn1.url === missing
        @test btn2 isa Button
        @test btn2.style == ButtonStyles.LINK
        @test btn2.url == "https://discord.com"
        @test btn2.custom_id === missing

        row2 = rows[2]
        select = only(row2.components)
        @test select isa StringSelect
        @test select.custom_id == "select_one"
        @test length(select.options) == 2
        @test select.options[1].value == "cat"
        @test select.options[1].default === true
        @test select.options[2].description == "Woof"
        @test select.placeholder == "Pick a pet"

        @test JSON3.read(JSON3.write(rows), Vector{Component}) == rows
    end

    @testset "select variants" begin
        for (T, type) in ((UserSelect, 5), (RoleSelect, 6), (MentionableSelect, 7))
            c = JSON3.read("""{
                "type": $type, "custom_id": "pick",
                "default_values": [{"id": "1", "type": "user"}],
                "min_values": 1, "max_values": 3
            }""", Component)
            @test c isa T
            @test c.custom_id == "pick"
            @test only(c.default_values).id == 1
            @test JSON3.read(JSON3.write(c), Component) == c
        end

        cs = JSON3.read("""{
            "type": 8, "custom_id": "chan",
            "channel_types": [0, 2],
            "default_values": []
        }""", Component)
        @test cs isa ChannelSelect
        @test cs.channel_types == [ChannelTypes.GUILD_TEXT, ChannelTypes.GUILD_VOICE]
        @test isempty(cs.default_values)
    end

    @testset "text input" begin
        ti = JSON3.read("""{
            "type": 4, "custom_id": "name", "style": 2,
            "label": "ignored-if-present", "required": true, "max_length": 4000
        }""", Component)
        @test ti isa TextInput
        @test ti.style == TextInputStyles.PARAGRAPH
        @test ti.required === true
        @test JSON3.read(JSON3.write(ti), Component) == ti
    end

    @testset "components-v2 container" begin
        fixture = read(joinpath(@__DIR__, "fixtures", "components_v2_container.json"), String)
        c = JSON3.read(fixture, Component)
        @test c isa Container
        @test c.accent_color == 5793266
        @test c.spoiler === false
        @test length(c.components) == 2

        section = c.components[1]
        @test section isa Section
        @test only(section.components) isa TextDisplayComponent
        @test section.accessory isa Thumbnail
        @test section.accessory.media.url == "https://example.com/thumb.png"

        @test c.components[2] isa Separator
        @test JSON3.read(JSON3.write(c), Component) == c
    end

    @testset "media gallery and file" begin
        mg = JSON3.read("""{
            "type": 12,
            "items": [
                {"media": {"url": "https://example.com/a.png"}, "spoiler": true},
                {"media": {"attachment_id": "9"}, "description": "b"}
            ]
        }""", Component)
        @test mg isa MediaGallery
        @test length(mg.items) == 2
        @test mg.items[1].spoiler === true
        @test mg.items[2].media.attachment_id == 9

        file = JSON3.read("""{"type": 13, "attachment_id": "42"}""", Component)
        @test file isa FileComponent
        @test file.attachment_id == 42
    end

    @testset "label wraps interactive component" begin
        label = JSON3.read("""{
            "type": 18, "label": "Your name", "description": "shown in the modal",
            "component": {"type": 4, "custom_id": "name", "style": 1}
        }""", Component)
        @test label isa Label
        @test label.label == "Your name"
        @test label.component isa TextInput
        @test JSON3.read(JSON3.write(label), Component) == label
    end

    @testset "newer input components" begin
        fu = JSON3.read("""{"type": 19, "custom_id": "upload", "required": true}""", Component)
        @test fu isa FileUpload
        @test fu.required === true

        rg = JSON3.read("""{
            "type": 21, "custom_id": "radios",
            "options": [{"label": "A", "value": "a"}]
        }""", Component)
        @test rg isa RadioGroup
        @test only(rg.options).value == "a"

        cg = JSON3.read("""{
            "type": 22, "custom_id": "checks",
            "options": [{"label": "A", "value": "a"}]
        }""", Component)
        @test cg isa CheckboxGroup

        cb = JSON3.read("""{"type": 23, "custom_id": "agree", "required": true}""", Component)
        @test cb isa Checkbox
        @test cb.required === true
    end

    @testset "unknown component survives" begin
        c = JSON3.read("""{"type": 99, "custom_id": "mystery", "foo": "bar"}""", Component)
        @test c isa UnknownComponent
        @test c.type == 99
        @test c.raw["foo"] == "bar"
    end
end

@testset "Poll" begin
    @testset "types" begin
        fixture = """{
            "question": {"text": "Pick one"},
            "answers": [
                {"answer_id": 1, "poll_media": {"text": "Cats"}},
                {"answer_id": 2, "poll_media": {"text": "Dogs", "emoji": {"id": null, "name": "\\ud83d\\udc36"}}}
            ],
            "expiry": "2024-01-01T00:00:00+00:00",
            "allow_multiselect": false,
            "layout_type": 1,
            "results": {
                "is_finalized": true,
                "answer_counts": [
                    {"id": 1, "count": 3, "me_voted": false},
                    {"id": 2, "count": 5, "me_voted": true}
                ]
            }
        }"""
        p = JSON3.read(fixture, Poll)
        @test p.question.text == "Pick one"
        @test length(p.answers) == 2
        @test p.answers[1].answer_id == 1
        @test p.answers[2].poll_media.emoji.name == "🐶"
        @test p.expiry == DateTime(2024, 1, 1)
        @test p.allow_multiselect === false
        @test p.layout_type == PollLayoutTypes.DEFAULT
        @test p.results.is_finalized === true
        @test p.results.answer_counts[2].count == 5
        @test JSON3.read(JSON3.write(p), Poll) == p

        noresults = JSON3.read("""{
            "question": {"text": "?"}, "answers": [], "expiry": null,
            "allow_multiselect": false, "layout_type": 1
        }""", Poll)
        @test noresults.results === missing
        @test noresults.expiry === nothing
    end

    @testset "PollCreateRequest" begin
        req = PollCreateRequest(;
            question=PollMedia(; text="Best language?"),
            answers=[PollAnswer(; poll_media=PollMedia(; text="Julia")),
                     PollAnswer(; poll_media=PollMedia(; text="Other"))],
            duration=48,
            allow_multiselect=true)
        @test req.layout_type === missing
        @test JSON3.read(JSON3.write(req), PollCreateRequest) == req
        written = JSON3.read(JSON3.write(req))
        @test written.duration == 48
        @test !haskey(written, :layout_type)
    end
end

@testset "Poll endpoints" begin
    @testset "get_answer_voters" begin
        fake = fakehttp(response(200; body="""{
            "users": [{"id": "1", "username": "a", "discriminator": "0"}]
        }"""))
        result = get_answer_voters(fastapi(fake), 1, 2, 3; after=10, limit=50)
        req = only(fake.requests)
        @test req.method == "GET"
        @test req.url == "https://discord.com/api/v10/channels/1/polls/2/answers/3?after=10&limit=50"
        @test length(result.users) == 1
        @test result.users[1].username == "a"
    end

    @testset "end_poll" begin
        fake = fakehttp(response(200; body="""{
            "id": "5", "channel_id": "1", "content": "", "tts": false,
            "author": {"id": "9", "username": "bot", "discriminator": "0"},
            "timestamp": "2026-07-20T12:00:00+00:00", "edited_timestamp": null,
            "mention_everyone": false, "mentions": [], "mention_roles": [],
            "attachments": [], "embeds": [], "pinned": false, "type": 0
        }"""))
        msg = end_poll(fastapi(fake), 1, 5)
        req = only(fake.requests)
        @test req.method == "POST"
        @test req.url == "https://discord.com/api/v10/channels/1/polls/5/expire"
        @test msg isa Message
        @test msg.id == 5
    end
end
