# Live smoke test against a real Discord guild. NOT part of Pkg.test — run it
# by hand when you want end-to-end proof:
#
#     DISCORD_TOKEN=... julia --project=. test/live/smoke.jl
#
# Safety model: the only delete calls in this script iterate the `created`
# ledger of artifacts the script itself made (all named nobelium-smoke-*), and
# cleanup runs in a finally block. Nothing pre-existing is modified or removed.

using Nobelium
using Dates

const TEST_GUILD = Snowflake(1392713127724060802)

api = API(ENV["DISCORD_TOKEN"])

results = Pair{String,Any}[]
check(f, name) = push!(results, name => try
    f()
    true
catch e
    sprint(showerror, e)
end)

created = Tuple{Symbol,Any}[]   # (:channel, id) / (:event, id) — cleanup ledger

# -- membership gate: refuse to touch anything if we're not where we expect --
me = get_current_user(api)
guild = try
    get_guild(api, TEST_GUILD)
catch e
    error("bot is not in the test guild ($TEST_GUILD); aborting before any writes")
end
println("acting as $(display_name(me)) in \"$(guild.name)\"\n")

try
    # ---- read-only sweep across resource groups ----
    check("gateway meta") do
        info = get_gateway_bot(api)
        startswith(info.url, "wss://") || error("odd gateway url: $(info.url)")
    end
    check("guild channels") do
        chs = get_guild_channels(api, TEST_GUILD)
        isempty(chs) && error("no channels visible")
    end
    check("members") do
        length(list_guild_members(api, TEST_GUILD; limit=5)) >= 1 || error("no members")
    end
    check("audit log") do
        get_guild_audit_log(api, TEST_GUILD; limit=1)
    end
    check("emojis") do
        list_guild_emojis(api, TEST_GUILD)
    end
    check("invites") do
        get_guild_invites(api, TEST_GUILD)
    end
    check("roles") do
        isempty(get_guild_roles(api, TEST_GUILD)) && error("no roles (missing @everyone?)")
    end
    check("voice regions") do
        isempty(list_voice_regions(api)) && error("no voice regions")
    end
    check("soundboard") do
        list_guild_soundboard_sounds(api, TEST_GUILD)
    end
    check("automod rules") do
        list_auto_moderation_rules_for_guild(api, TEST_GUILD)
    end
    check("scheduled events") do
        list_scheduled_events_for_guild(api, TEST_GUILD)
    end
    check("application") do
        get_current_application(api)
    end

    # ---- own artifacts: create, exercise, clean up ----
    stamp = Dates.format(now(UTC), "yyyymmdd-HHMMSS")
    channel = Ref{Any}(nothing)

    check("create channel") do
        ch = create_guild_channel(api, TEST_GUILD;
            name="nobelium-smoke-$stamp", topic="wrapper smoke test — safe to delete",
            reason="Nobelium.jl live smoke test")
        push!(created, (:channel, ch.id))
        channel[] = ch
    end

    if channel[] !== nothing
        ch = channel[]
        msg = Ref{Any}(nothing)

        check("create message") do
            m = create_message(api, ch.id;
                content="smoke test $(discord_timestamp(now(UTC)))",
                embeds=[Embed(title="Nobelium.jl", description="end-to-end check",
                              color=0x9b59b6)])
            msg[] = m
        end
        check("edit message") do
            edited = edit_message(api, ch.id, msg[].id; content="smoke test (edited)")
            edited.content == "smoke test (edited)" || error("edit didn't stick")
        end
        check("reactions") do
            create_reaction(api, ch.id, msg[].id, "🧪")
            users = get_reactions(api, ch.id, msg[].id, "🧪")
            any(u -> u.id == me.id, users) || error("own reaction missing")
        end
        check("pins") do
            pin_message(api, ch.id, msg[].id; reason="smoke")
            unpin_message(api, ch.id, msg[].id; reason="smoke")
        end
        check("components") do
            create_message(api, ch.id; content="buttons",
                components=[action_row(button("Click me"; custom_id="smoke-btn"))])
        end
        check("poll create + end") do
            pm = create_message(api, ch.id;
                poll=(question=(text="Does the rewrite work?",),
                      answers=[(poll_media=(text="Yes",),), (poll_media=(text="Also yes",),)],
                      duration=1))
            end_poll(api, ch.id, pm.id)
        end
        check("threads") do
            t = start_thread_from_message(api, ch.id, msg[].id;
                                          name="nobelium-smoke-thread")
            # thread dies with its parent channel; no separate cleanup needed
            t.id
        end
        check("delete message") do
            delete_message(api, ch.id, msg[].id; reason="smoke cleanup")
        end
        check("typing indicator") do
            trigger_typing_indicator(api, ch.id)
        end
    end

    check("scheduled event create + delete") do
        ev = create_guild_scheduled_event(api, TEST_GUILD;
            name="nobelium-smoke-$stamp",
            privacy_level=2,
            scheduled_start_time=string(now(UTC) + Hour(1)) * "Z",
            scheduled_end_time=string(now(UTC) + Hour(2)) * "Z",
            entity_type=3,
            entity_metadata=(location="the test suite",),
            reason="Nobelium.jl live smoke test")
        push!(created, (:event, ev.id))
        delete_guild_scheduled_event(api, TEST_GUILD, ev.id)
        filter!(x -> x != (:event, ev.id), created)
    end

    # ---- gateway ----
    check("gateway connect + READY + GUILD_CREATE") do
        client = Client(ENV["DISCORD_TOKEN"]; intents=Intent.guilds | Intent.guild_messages)
        seen_guild = Channel{Bool}(1)
        on!(client, GuildCreate) do c, ev
            ev.guild.id == TEST_GUILD && put!(seen_guild, true)
        end
        start!(client; async=true)
        try
            ok = false
            t = Timer(_ -> close(seen_guild), 15)
            try
                ok = take!(seen_guild)
            catch
            finally
                close(t)
            end
            ok || error("GUILD_CREATE for the test guild never arrived")
        finally
            stop!(client)
        end
    end
finally
    # ---- cleanup: only ever deletes what this run created ----
    for (kind, id) in reverse(created)
        try
            kind === :channel && delete_channel(api, id; reason="smoke cleanup")
            kind === :event && delete_guild_scheduled_event(api, TEST_GUILD, id)
        catch e
            @warn "cleanup of $kind $id failed" exception = e
        end
    end
end

# ---- report ----
println()
pass = count(r -> r.second === true, results)
for (name, r) in results
    println(r === true ? "  ✓ " : "  ✗ ", name, r === true ? "" : "  — $r")
end
println("\n$pass/$(length(results)) checks passed")
exit(pass == length(results) ? 0 : 1)
