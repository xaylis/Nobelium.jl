using Dates
using HTTP
using JSON3

const TEXT_CHANNEL_JSON = """
{
    "id": "41771983423143937",
    "guild_id": "41771983423143936",
    "name": "general",
    "type": 0,
    "position": 6,
    "permission_overwrites": [
        {"id": "41771983423143936", "type": 0, "allow": "1024", "deny": "2048"}
    ],
    "rate_limit_per_user": 2,
    "nsfw": true,
    "topic": "24/7 chat about how to gank Mike #2",
    "last_message_id": "155117677105512449",
    "parent_id": "399942396007890945",
    "default_auto_archive_duration": 60
}
"""

const THREAD_JSON = """
{
    "id": "41771983423143937",
    "guild_id": "41771983423143936",
    "parent_id": "41771983423143937",
    "owner_id": "41771983423143936",
    "name": "don't buy dogecoin",
    "type": 11,
    "last_message_id": "155117677105512449",
    "message_count": 1,
    "member_count": 5,
    "rate_limit_per_user": 2,
    "flags": 2,
    "thread_metadata": {
        "archived": false,
        "auto_archive_duration": 1440,
        "archive_timestamp": "2021-04-12T23:40:39.855793+00:00",
        "locked": false
    },
    "total_message_sent": 1
}
"""

const THREAD_MEMBER_JSON = """
{"id": "41771983423143937", "user_id": "80351110224678912", \
"join_timestamp": "2021-04-12T23:40:39.855793+00:00", "flags": 0}
"""

@testset "channel" begin
    @testset "guild text channel round-trip" begin
        c = JSON3.read(TEXT_CHANNEL_JSON, DiscordChannel)
        @test c.id == Snowflake(41771983423143937)
        @test c.type === ChannelTypes.GUILD_TEXT
        @test c.nsfw === true
        @test c.topic == "24/7 chat about how to gank Mike #2"
        @test c.parent_id == Snowflake(399942396007890945)
        @test c.bitrate === missing
        @test c.thread_metadata === missing
        ow = only(c.permission_overwrites)
        @test ow.type == 0
        @test ow.allow == Permission.view_channel
        @test ow.deny == Permission.send_messages
        @test JSON3.read(JSON3.write(c), DiscordChannel) == c
    end

    @testset "thread round-trip" begin
        t = JSON3.read(THREAD_JSON, DiscordChannel)
        @test t.type === ChannelTypes.PUBLIC_THREAD
        @test t.flags == ChannelFlag.pinned
        @test t.message_count == 1
        @test t.thread_metadata.archived === false
        @test t.thread_metadata.auto_archive_duration == 1440
        @test t.thread_metadata.archive_timestamp == DateTime(2021, 4, 12, 23, 40, 39, 855)
        @test t.thread_metadata.invitable === missing
        @test t.thread_metadata.create_timestamp === missing
        @test JSON3.read(JSON3.write(t), DiscordChannel) == t
    end

    @testset "forum channel round-trip" begin
        f = JSON3.read("""{
            "id": "3",
            "type": 15,
            "available_tags": [
                {"id": "9", "name": "help", "moderated": false, "emoji_id": null, "emoji_name": "❓"}
            ],
            "applied_tags": ["9"],
            "default_reaction_emoji": {"emoji_id": null, "emoji_name": "👍"},
            "default_sort_order": null,
            "default_forum_layout": 2,
            "flags": 16
        }""", DiscordChannel)
        @test f.type === ChannelTypes.GUILD_FORUM
        tag = only(f.available_tags)
        @test tag.emoji_id === nothing && tag.emoji_name == "❓"
        @test f.applied_tags == [Snowflake(9)]
        @test f.default_reaction_emoji.emoji_name == "👍"
        @test f.default_sort_order === nothing
        @test f.default_forum_layout === ForumLayoutTypes.GALLERY_VIEW
        @test ChannelFlag.require_tag in f.flags
        @test JSON3.read(JSON3.write(f), DiscordChannel) == f
    end

    @testset "thread member round-trip" begin
        m = JSON3.read(THREAD_MEMBER_JSON, ThreadMember)
        @test m.id == Snowflake(41771983423143937)
        @test m.user_id == Snowflake(80351110224678912)
        @test m.join_timestamp == DateTime(2021, 4, 12, 23, 40, 39, 855)
        @test m.flags == 0
        @test m.member === missing
        @test JSON3.read(JSON3.write(m), ThreadMember) == m
    end

    @testset "followed channel round-trip" begin
        f = JSON3.read("""{"channel_id": "1", "webhook_id": "2"}""", FollowedChannel)
        @test f == FollowedChannel(channel_id=1, webhook_id=2)
        @test JSON3.read(JSON3.write(f), FollowedChannel) == f
    end

    @testset "mention" begin
        c = JSON3.read(TEXT_CHANNEL_JSON, DiscordChannel)
        @test mention(c) == "<#41771983423143937>"
    end

    @testset "get_channel" begin
        fake = fakehttp(response(200; body=TEXT_CHANNEL_JSON))
        c = get_channel(fastapi(fake), 41771983423143937)
        req = only(fake.requests)
        @test req.method == "GET"
        @test req.url == "https://discord.com/api/v10/channels/41771983423143937"
        @test c isa DiscordChannel && c.name == "general"
    end

    @testset "modify_channel" begin
        fake = fakehttp(response(200; body=TEXT_CHANNEL_JSON))
        c = modify_channel(fastapi(fake), 42; name="renamed", topic=nothing, reason="cleanup")
        req = only(fake.requests)
        @test req.method == "PATCH"
        @test req.url == "https://discord.com/api/v10/channels/42"
        sent = sent_json(fake)
        @test sent.name == "renamed"
        @test sent.topic === nothing
        @test ("X-Audit-Log-Reason" => "cleanup") in req.headers
        @test c isa DiscordChannel
    end

    @testset "set_voice_channel_status" begin
        fake = fakehttp(response(204))
        set_voice_channel_status(fastapi(fake), 3; status="pod racing", reason="vibes")
        req = only(fake.requests)
        @test req.method == "PUT"
        @test endswith(req.url, "/channels/3/voice-status")
        @test sent_json(fake).status == "pod racing"
        @test ("X-Audit-Log-Reason" => "vibes") in req.headers
    end

    @testset "delete_channel" begin
        fake = fakehttp(response(200; body=TEXT_CHANNEL_JSON))
        c = delete_channel(fastapi(fake), 42; reason="spam")
        req = only(fake.requests)
        @test req.method == "DELETE"
        @test endswith(req.url, "/channels/42")
        @test ("X-Audit-Log-Reason" => "spam") in req.headers
        @test c isa DiscordChannel
    end

    @testset "edit_channel_permissions" begin
        fake = fakehttp(response(204))
        r = edit_channel_permissions(fastapi(fake), 1, 2;
                                     allow=Permission.view_channel, deny=Permission.none,
                                     type=0, reason="lockdown")
        req = only(fake.requests)
        @test req.method == "PUT"
        @test endswith(req.url, "/channels/1/permissions/2")
        sent = sent_json(fake)
        @test sent.allow == "1024" && sent.deny == "0" && sent.type == 0
        @test ("X-Audit-Log-Reason" => "lockdown") in req.headers
        @test r === nothing
    end

    @testset "follow_announcement_channel" begin
        fake = fakehttp(response(200; body="""{"channel_id": "1", "webhook_id": "2"}"""))
        f = follow_announcement_channel(fastapi(fake), 1; webhook_channel_id="5")
        req = only(fake.requests)
        @test req.method == "POST"
        @test endswith(req.url, "/channels/1/followers")
        @test sent_json(fake).webhook_channel_id == "5"
        @test f == FollowedChannel(channel_id=1, webhook_id=2)
    end

    @testset "trigger_typing_indicator" begin
        fake = fakehttp(response(204))
        @test trigger_typing_indicator(fastapi(fake), 6) === nothing
        req = only(fake.requests)
        @test req.method == "POST"
        @test endswith(req.url, "/channels/6/typing")
    end

    @testset "group_dm_add_recipient" begin
        fake = fakehttp(response(204))
        group_dm_add_recipient(fastapi(fake), 1, 2; access_token="tok", nick="pal")
        req = only(fake.requests)
        @test req.method == "PUT"
        @test endswith(req.url, "/channels/1/recipients/2")
        sent = sent_json(fake)
        @test sent.access_token == "tok" && sent.nick == "pal"
    end

    @testset "start_thread_from_message" begin
        fake = fakehttp(response(200; body=THREAD_JSON))
        t = start_thread_from_message(fastapi(fake), 1, 2;
                                      name="hot take", auto_archive_duration=1440, reason="split")
        req = only(fake.requests)
        @test req.method == "POST"
        @test endswith(req.url, "/channels/1/messages/2/threads")
        @test sent_json(fake).name == "hot take"
        @test ("X-Audit-Log-Reason" => "split") in req.headers
        @test t isa DiscordChannel && t.type === ChannelTypes.PUBLIC_THREAD
    end

    @testset "start_thread_in_forum_or_media_channel with files" begin
        fake = fakehttp(response(200; body=THREAD_JSON))
        start_thread_in_forum_or_media_channel(fastapi(fake), 1;
            name="post", message=(content="first!",), files=[DiscordFile("a.txt", "hello")])
        req = only(fake.requests)
        @test endswith(req.url, "/channels/1/threads")
        @test req.body isa HTTP.Form
        io = IOBuffer()
        write(io, req.body)
        raw = String(take!(io))
        @test occursin("payload_json", raw)
        @test occursin("first!", raw)
        @test occursin("a.txt", raw)
    end

    @testset "join_thread" begin
        fake = fakehttp(response(204))
        @test join_thread(fastapi(fake), 9) === nothing
        req = only(fake.requests)
        @test req.method == "PUT"
        @test endswith(req.url, "/channels/9/thread-members/@me")
    end

    @testset "get_thread_member" begin
        fake = fakehttp(response(200; body=THREAD_MEMBER_JSON))
        m = get_thread_member(fastapi(fake), 5, 7; with_member=true)
        req = only(fake.requests)
        @test req.method == "GET"
        @test endswith(req.url, "/channels/5/thread-members/7?with_member=true")
        @test m isa ThreadMember && m.flags == 0
    end

    @testset "list_thread_members" begin
        fake = fakehttp(response(200; body="[$THREAD_MEMBER_JSON]"))
        ms = list_thread_members(fastapi(fake), 5; limit=2, after=100)
        @test endswith(only(fake.requests).url, "/channels/5/thread-members?limit=2&after=100")
        @test ms isa Vector{ThreadMember}
        @test only(ms).user_id == Snowflake(80351110224678912)
    end

    @testset "list_public_archived_threads" begin
        fake = fakehttp(response(200;
            body="""{"threads": [$THREAD_JSON], "members": [], "has_more": false}"""))
        page = list_public_archived_threads(fastapi(fake), 4; limit=5)
        @test endswith(only(fake.requests).url, "/channels/4/threads/archived/public?limit=5")
        @test page.has_more == false
        @test length(page.threads) == 1
    end

    @testset "list_joined_private_archived_threads" begin
        fake = fakehttp(response(200; body="""{"threads": [], "members": [], "has_more": false}"""))
        page = list_joined_private_archived_threads(fastapi(fake), 4)
        @test endswith(only(fake.requests).url,
                       "/channels/4/users/@me/threads/archived/private")
        @test isempty(page.threads)
    end
end
