# Components

Buttons, selects, and layout elements attach to any message via the
`components` keyword.

## Buttons and selects

```julia
create_message(client.api, channel_id;
    content = "Deploy to production?",
    components = [action_row(
        button("Ship it"; custom_id="deploy", style=ButtonStyles.SUCCESS),
        button("Abort"; custom_id="abort", style=ButtonStyles.DANGER),
        link_button("Runbook", "https://example.com/runbook"),
    )])
```

```julia
string_select("flavor",
    [select_option("Vanilla", "vanilla"; emoji=Emoji(id=nothing, name="🍦")),
     select_option("Chocolate", "chocolate")];
    placeholder="Pick a flavor")
```

`user_select`, `role_select`, `mentionable_select`, and `channel_select` work
the same but let the user pick entities instead of fixed options.

Clicks and selections arrive as `InteractionCreate` with
`i.data.custom_id` telling you which component fired — answer with
`update_message`, `defer_update`, or a fresh `respond`.

## Components v2

The newer layout components — `Section`, `Container`, `TextDisplayComponent`,
`MediaGallery`, `Separator`, `Thumbnail`, and friends — are all available as
types and deserialize from any message. Set `MessageFlag.is_components_v2` in
the message flags to compose messages entirely out of components.

Unknown component types Discord adds later parse as `UnknownComponent` rather
than erroring, so reading messages stays future-proof.
