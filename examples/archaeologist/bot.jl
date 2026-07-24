# The Archaeologist — a small Nobelium.jl demo bot with two slash commands:
#
#   /excavate                          digs up a random message from the server's past
#   /timecapsule message: minutes:     seals a message and reveals it later with a poll
#
# Run with:  DISCORD_TOKEN=... DISCORD_GUILD=... julia --project bot.jl

using Nobelium
using Dates
using Random

const TOKEN = ENV["DISCORD_TOKEN"]
const GUILD = Snowflake(ENV["DISCORD_GUILD"])

client = Client(TOKEN; intents=Intent.guilds)

# ---------------------------------------------------------------- commands --

const COMMANDS = [
    slash_command("excavate", "Dig up a random message from this server's past"),
    slash_command("timecapsule", "Seal a message away and reveal it later";
        options=[
            command_option(:string, "message", "What to put in the capsule"; required=true),
            command_option(:integer, "minutes", "How long to keep it sealed";
                           required=true, min_value=1, max_value=120),
        ]),
]

# Julia compiles code on first use, which can cost seconds — more than
# Discord's 3-second interaction window. Run every acknowledgement path once
# against a stub transport so the first real command answers instantly.
function warmup()
    stub = API("warmup"; http=(m, u, h, b) -> Nobelium.HTTP.Response(204, Pair{String,String}[]; body=UInt8[]))
    fake = Interaction(id=1, application_id=1, type=InteractionTypes.APPLICATION_COMMAND,
                       token="warmup", version=1, app_permissions=Permissions(0),
                       entitlements=[], authorizing_integration_owners=Dict{String,Snowflake}(),
                       attachment_size_limit=8388608)
    respond(stub, fake; content="w")
    respond(stub, fake; content="w", ephemeral=true)
    defer(stub, fake)
    defer(stub, fake; ephemeral=true)
    defer_update(stub, fake)
end

on!(client, Ready) do c, ev
    warmup()
    bulk_overwrite_guild_application_commands(c.api, ev.application.id, GUILD, COMMANDS)
    @info "ready as $(display_name(ev.user)) — commands registered"
end

# -------------------------------------------------------------- /excavate --

# Pick a random moment between the guild's creation and now, then read the
# messages just before it. Snowflakes encode their timestamp, so a DateTime
# converts straight into a pagination cursor.
function dig(api, guild_id)
    channels = filter(c -> c.type == ChannelTypes.GUILD_TEXT, get_guild_channels(api, guild_id))
    isempty(channels) && return nothing
    epoch = timestamp(guild_id)
    for _ in 1:8
        site = rand(channels)
        moment = epoch + Millisecond(rand(0:Dates.value(now(UTC) - epoch)))
        layer = try
            get_channel_messages(api, site.id; before=Snowflake(moment), limit=50)
        catch e
            e isa APIError && continue   # can't read this channel; dig elsewhere
            rethrow()
        end
        finds = filter(m -> m.author.bot !== true && !isempty(m.content) &&
                            length(m.content) <= 800, layer)
        isempty(finds) || return (site, rand(finds))
    end
    nothing
end

function artifact_embed(site, find)
    age = Day(Dates.value(now(UTC) - timestamp(find.id)) ÷ 86_400_000)
    Embed(
        title="🏺 Artifact unearthed!",
        description="> $(find.content)",
        color=0xc2853a,
        fields=[
            EmbedField(name="Author", value=display_name(find.author), inline=true),
            EmbedField(name="Dig site", value=mention(site), inline=true),
            EmbedField(name="Carbon dating", value="$(discord_timestamp(timestamp(find.id); style=:R)) ($(age) old)", inline=true),
        ],
    )
end

function excavate!(c, i)
    result = try
        dig(c.api, GUILD)
    catch e
        e isa APIError || rethrow()
        return edit_response(c, i; content="The dig collapsed: $(e.message)")
    end
    if result === nothing
        return edit_response(c, i; content="The dig turned up nothing but dust. 🌫️")
    end
    site, find = result
    create_reaction(c.api, find.channel_id, find.id, "🏺")   # mark the find in situ
    edit_response(c, i;
        embeds=[artifact_embed(site, find)],
        components=[action_row(
            button("Dig again"; custom_id="dig-again", style=ButtonStyles.SECONDARY),
            link_button("Visit the site",
                        "https://discord.com/channels/$(GUILD)/$(find.channel_id)/$(find.id)"),
        )])
end

# ------------------------------------------------------------ /timecapsule --

function seal!(c, i)
    text = String(option(i, "message", ""))
    minutes = Int(option(i, "minutes", 5))
    # Acknowledge inside Discord's 3-second window before doing anything slow.
    defer(c, i; ephemeral=true)

    reveal_at = now(UTC) + Minute(minutes)
    buried_by = i.member === missing ? i.user : i.member.user

    event = try
        create_guild_scheduled_event(c.api, GUILD;
            name="⏳ Time capsule opening",
            privacy_level=2,
            entity_type=3,
            entity_metadata=(location=mention_channel(i.channel_id),),
            scheduled_start_time="$(reveal_at)Z",
            scheduled_end_time="$(reveal_at + Minute(5))Z",
            description="Sealed by $(display_name(buried_by)). No peeking.")
    catch e
        e isa APIError || rethrow()
        edit_response(c, i; content="Couldn't seal the capsule: $(e.message)")
        return
    end

    edit_response(c, i;
        content="🤐 Sealed. Your capsule opens $(discord_timestamp(reveal_at; style=:R)) — there's even a calendar event for it.")

    channel_id = i.channel_id
    Timer(60minutes) do _
        try
            create_message(c.api, channel_id;
                embeds=[Embed(title="⏳ Time capsule opened!",
                              description="> $text",
                              color=0x7fdbca,
                              footer=EmbedFooter(text="Buried $(minutes) minute(s) ago by $(display_name(buried_by))"))],
                poll=(question=(text="Was that worth the wait?",),
                      answers=[(poll_media=(text="Absolutely",),),
                               (poll_media=(text="We waited $(minutes) minutes for this?",),)],
                      duration=1))
            delete_guild_scheduled_event(c.api, GUILD, event.id)
        catch e
            @error "capsule reveal failed" exception=e
        end
    end
end

# ------------------------------------------------------------- dispatch ----

on!(client, InteractionCreate) do c, ev
    i = ev.interaction
    if i.type == InteractionTypes.APPLICATION_COMMAND
        if i.data.name == "excavate"
            defer(c, i)               # digs can take a few seconds
            excavate!(c, i)
        elseif i.data.name == "timecapsule"
            seal!(c, i)
        end
    elseif i.type == InteractionTypes.MESSAGE_COMPONENT && i.data.custom_id == "dig-again"
        defer_update(c, i)
        excavate!(c, i)
    end
end

start!(client)
