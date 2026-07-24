# Your first bot

Let's build a small dice bot end to end: it answers a text command, adds a
reaction, and asks a follow-up question with buttons.

Project setup:

```julia
mkdir("dicebot"); cd("dicebot")
using Pkg; Pkg.activate("."); Pkg.add("Nobelium")
```

Create `bot.jl`:

```julia
using Nobelium

client = Client(ENV["DISCORD_TOKEN"];
                intents=Intent.default | Intent.message_content)

on!(client, Ready) do c, ev
    @info "ready as $(display_name(ev.user)) in $(length(ev.guilds)) guild(s)"
    update_presence!(c; activities=[activity("dice rattle"; type=2)])
end
```

## Rolling

```julia
on!(client, MessageCreate) do c, ev
    m = ev.message
    m.author.bot === true && return
    startswith(m.content, "!roll") || return

    roll = rand(1:6)
    msg = reply(c, m; content="🎲 you rolled a **$roll**")
    roll == 6 && create_reaction(c.api, m.channel_id, m.id, "🎉")

    if roll == 1
        again = create_message(c.api, m.channel_id;
            content="Ouch. Double or nothing?",
            components=[action_row(
                button("Go again"; custom_id="reroll", style=ButtonStyles.PRIMARY),
                button("I'm done"; custom_id="stop", style=ButtonStyles.SECONDARY),
            )])
    end
end
```

## Handling the buttons

```julia
on!(client, InteractionCreate) do c, ev
    i = ev.interaction
    i.type == InteractionTypes.MESSAGE_COMPONENT || return

    if i.data.custom_id == "reroll"
        respond(c, i; content="🎲 $(rand(1:6))")
    elseif i.data.custom_id == "stop"
        update_message(c, i; content="Probably wise.", components=[])
    end
end

start!(client)
```

Run it:

```bash
DISCORD_TOKEN=your-token julia --project bot.jl
```

That's the whole loop: events in with `on!`, actions out through `c.api` and
the helpers. From here, [slash commands](slash-commands.md) give your bot a
proper `/` interface.
