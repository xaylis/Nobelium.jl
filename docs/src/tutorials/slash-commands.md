# Slash commands

We'll register a `/poll` command that opens a modal, then posts the question
as a native Discord poll.

## Register the command

Guild commands update instantly, so develop against your test server:

```julia
using Nobelium

api = API(ENV["DISCORD_TOKEN"])
app = get_current_application(api)

create_guild_application_command(api, app.id, TEST_GUILD;
    slash_command("poll", "Ask the channel a question")...)
```

Registration persists — run this once (or at startup; it's idempotent by name).

## Open a modal

```julia
client = Client(ENV["DISCORD_TOKEN"]; intents=Intent.default)

on!(client, InteractionCreate) do c, ev
    i = ev.interaction

    if i.type == InteractionTypes.APPLICATION_COMMAND && i.data.name == "poll"
        show_modal(c, i, modal("poll-modal", "New poll",
            labeled("Question", text_input("question")),
            labeled("Option A", text_input("a")),
            labeled("Option B", text_input("b"))))

    elseif i.type == InteractionTypes.MODAL_SUBMIT && i.data.custom_id == "poll-modal"
        answers = Dict{String,String}()
        for row in i.data.components, comp in something(row.components, (row,))
            comp isa TextInput && (answers[comp.custom_id] = something(comp.value, ""))
        end

        respond(c, i; content="📊 Poll started!", ephemeral=true)
        create_message(c.api, i.channel_id;
            poll=(question=(text=answers["question"],),
                  answers=[(poll_media=(text=answers["a"],),),
                           (poll_media=(text=answers["b"],),)],
                  duration=24))
    end
end

start!(client)
```

Two things to note:

- Modal submissions come back through the same `InteractionCreate` event,
  distinguished by `i.type` and `custom_id`.
- REST keywords take plain named tuples wherever you'd write a JSON object —
  the `poll` payload above mirrors the docs one-to-one.

## Autocomplete

Mark an option with `autocomplete=true` when registering, then answer the
typing user live:

```julia
command_option(:string, "city", "Pick a city"; autocomplete=true)

# in the handler:
if i.type == InteractionTypes.APPLICATION_COMMAND_AUTOCOMPLETE
    typed = lowercase(something(i.data.options[1].value, ""))
    hits = filter(startswith(typed), CITIES)
    autocomplete(c, i, [choice(h, h) for h in first(hits, 25)])
end
```
