# Builders for message components — thin sugar over the component structs so a
# row of buttons doesn't take ten lines of keyword soup.

export action_row, button, link_button, string_select, select_option, text_input,
    user_select, role_select, mentionable_select, channel_select, labeled

"""
    action_row(components...) -> ActionRow

Wrap up to five buttons (or one select) in a row.

```julia
action_row(button("Yes"; custom_id="yes"), button("No"; custom_id="no", style=ButtonStyles.DANGER))
```
"""
action_row(components...) =
    ActionRow(type=ComponentTypes.ACTION_ROW, components=collect(Component, components))

"""
    button(label; custom_id, style=ButtonStyles.PRIMARY, emoji, disabled) -> Button
"""
button(label::AbstractString; custom_id::AbstractString, style::ButtonStyle=ButtonStyles.PRIMARY,
       emoji=missing, disabled=missing) =
    Button(; type=ComponentTypes.BUTTON, style, label, custom_id, emoji, disabled)

"""
    link_button(label, url; emoji, disabled) -> Button
"""
link_button(label::AbstractString, url::AbstractString; emoji=missing, disabled=missing) =
    Button(; type=ComponentTypes.BUTTON, style=ButtonStyles.LINK, label, url, emoji, disabled)

"""
    select_option(label, value; description, emoji, default) -> SelectOption
"""
select_option(label::AbstractString, value::AbstractString;
              description=missing, emoji=missing, default=missing) =
    SelectOption(; label, value, description, emoji, default)

"""
    string_select(custom_id, options; placeholder, min_values, max_values, disabled) -> StringSelect

```julia
string_select("flavor", [select_option("Vanilla", "v"), select_option("Chocolate", "c")])
```
"""
string_select(custom_id::AbstractString, options::AbstractVector; kwargs...) =
    StringSelect(; type=ComponentTypes.STRING_SELECT, custom_id,
                 options=collect(SelectOption, options), kwargs...)

user_select(custom_id::AbstractString; kwargs...) =
    UserSelect(; type=ComponentTypes.USER_SELECT, custom_id, kwargs...)
role_select(custom_id::AbstractString; kwargs...) =
    RoleSelect(; type=ComponentTypes.ROLE_SELECT, custom_id, kwargs...)
mentionable_select(custom_id::AbstractString; kwargs...) =
    MentionableSelect(; type=ComponentTypes.MENTIONABLE_SELECT, custom_id, kwargs...)
channel_select(custom_id::AbstractString; kwargs...) =
    ChannelSelect(; type=ComponentTypes.CHANNEL_SELECT, custom_id, kwargs...)

"""
    text_input(custom_id; style=TextInputStyles.SHORT, required, placeholder,
               min_length, max_length, value) -> TextInput

A text field for modals. Its visible label comes from wrapping it in
[`labeled`](@ref).
"""
text_input(custom_id::AbstractString; style::TextInputStyle=TextInputStyles.SHORT, kwargs...) =
    TextInput(; type=ComponentTypes.TEXT_INPUT, custom_id, style, kwargs...)

"""
    labeled(label, component; description) -> Label

Attach a label (and optional description) to a modal component.

```julia
labeled("Feedback", text_input("feedback"; style=TextInputStyles.PARAGRAPH))
```
"""
labeled(label::AbstractString, component::Component; description=missing) =
    Label(; type=ComponentTypes.LABEL, label, description, component)
