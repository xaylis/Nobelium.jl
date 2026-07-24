# Interactions

Slash commands, context menus, buttons, selects, and modals all arrive as one
event: `InteractionCreate`. You have three seconds to answer.

## Registering commands

Commands are registered once via REST — globally, or per guild (instant, ideal
while developing):

```julia
app = get_current_application(client.api)

create_guild_application_command(client.api, app.id, guild_id;
    slash_command("roll", "Roll some dice";
        options=[
            command_option(:integer, "sides", "How many sides"; min_value=2, max_value=120),
        ])...)
```

`slash_command`, `user_command`, `message_command`, `command_option`,
`subcommand`, and `choice` build the payloads; splat them into the
`create_*_application_command` endpoints.

## Answering

```julia
on!(client, InteractionCreate) do c, ev
    i = ev.interaction
    i.type == InteractionTypes.APPLICATION_COMMAND || return
    i.data.name == "roll" || return

    sides = Int(option(i, "sides", 6))
    respond(c, i; content="🎲 $(rand(1:sides))")
end
```

The response helpers cover every callback type:

| Helper | Effect |
|---|---|
| `respond(c, i; content, embeds, components, ephemeral)` | Send a message |
| `defer(c, i; ephemeral)` | Buy time; follow up within 15 minutes |
| `followup(c, i; content, ...)` | Extra messages after responding/deferring |
| `edit_response` / `get_response` / `delete_response` | Manage the original reply |
| `defer_update(c, i)` / `update_message(c, i; ...)` | Component interactions: leave/edit the parent message |
| `autocomplete(c, i, choices)` | Answer autocomplete queries |
| `show_modal(c, i, modal(...))` | Open a modal |

`ephemeral=true` makes the reply visible only to the user who triggered it.

## Modals

```julia
show_modal(c, i, modal("feedback", "Send feedback",
    labeled("What happened?", text_input("text"; style=TextInputStyles.PARAGRAPH))))
```

The submission comes back as another `InteractionCreate` with
`i.type == InteractionTypes.MODAL_SUBMIT` and your values under
`i.data.components`.
