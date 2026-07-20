# High-level helpers for answering interactions and messages. All of them
# accept either an API or a Client as the first argument.

export respond, defer, defer_update, update_message, autocomplete, modal,
    show_modal, followup, get_response, edit_response, delete_response, reply

_rest(api::API) = api
_rest(c::Client) = c.api

const Rest = Union{API,Client}

# Merge the ephemeral shorthand into message flags.
function _response_data(; ephemeral::Bool=false, flags=missing, kwargs...)
    ephemeral && (flags = (flags === missing ? 0 : Int(flags)) | Int(MessageFlag.ephemeral.value))
    flags === missing ? (; kwargs...) : (; flags, kwargs...)
end

"""
    respond(to, interaction; content, embeds, components, ephemeral=false, files, kwargs...)

Answer an interaction with a message. Must happen within 3 seconds of receiving
it — when you need longer, [`defer`](@ref) first and [`followup`](@ref) later.

```julia
on!(client, InteractionCreate) do c, ev
    respond(c, ev.interaction; content="pong!", ephemeral=true)
end
```
"""
respond(to::Rest, i::Interaction; files=nothing, with_response=missing, kwargs...) =
    create_interaction_response(_rest(to), i.id, i.token;
        type=Int(InteractionCallbackTypes.CHANNEL_MESSAGE_WITH_SOURCE.value),
        data=_response_data(; kwargs...), files, with_response)

"""
    defer(to, interaction; ephemeral=false)

Acknowledge now, answer later with [`followup`](@ref) or [`edit_response`](@ref).
"""
defer(to::Rest, i::Interaction; ephemeral::Bool=false) =
    create_interaction_response(_rest(to), i.id, i.token;
        type=Int(InteractionCallbackTypes.DEFERRED_CHANNEL_MESSAGE_WITH_SOURCE.value),
        data=_response_data(; ephemeral))

"""
    defer_update(to, interaction)

For component interactions: acknowledge without changing the message.
"""
defer_update(to::Rest, i::Interaction) =
    create_interaction_response(_rest(to), i.id, i.token;
        type=Int(InteractionCallbackTypes.DEFERRED_UPDATE_MESSAGE.value))

"""
    update_message(to, interaction; content, components, kwargs...)

For component interactions: edit the message the component sits on.
"""
update_message(to::Rest, i::Interaction; files=nothing, kwargs...) =
    create_interaction_response(_rest(to), i.id, i.token;
        type=Int(InteractionCallbackTypes.UPDATE_MESSAGE.value),
        data=_response_data(; kwargs...), files)

"""
    autocomplete(to, interaction, choices)

Answer an autocomplete interaction with up to 25 [`choice`](@ref)s.
"""
autocomplete(to::Rest, i::Interaction, choices::AbstractVector) =
    create_interaction_response(_rest(to), i.id, i.token;
        type=Int(InteractionCallbackTypes.APPLICATION_COMMAND_AUTOCOMPLETE_RESULT.value),
        data=(; choices))

"""
    modal(custom_id, title, components...) -> NamedTuple

Build a modal for [`show_modal`](@ref). Wrap inputs in [`labeled`](@ref).

```julia
modal("feedback", "Send feedback",
      labeled("What happened?", text_input("text"; style=TextInputStyles.PARAGRAPH)))
```
"""
modal(custom_id::AbstractString, title::AbstractString, components...) =
    (; custom_id, title, components=collect(components))

"""
    show_modal(to, interaction, modal)

Open a modal in response to a command or component interaction.
"""
show_modal(to::Rest, i::Interaction, m::NamedTuple) =
    create_interaction_response(_rest(to), i.id, i.token;
        type=Int(InteractionCallbackTypes.MODAL.value), data=m)

"""
    followup(to, interaction; content, ephemeral=false, files, kwargs...) -> Message

Send an extra message after responding (or deferring). Valid for 15 minutes.
"""
followup(to::Rest, i::Interaction; files=nothing, kwargs...) =
    create_followup_message(_rest(to), i.application_id, i.token;
                            files, _response_data(; kwargs...)...)

"""
    get_response(to, interaction) -> Message
"""
get_response(to::Rest, i::Interaction) =
    get_original_interaction_response(_rest(to), i.application_id, i.token)

"""
    edit_response(to, interaction; content, embeds, components, kwargs...) -> Message
"""
edit_response(to::Rest, i::Interaction; files=nothing, kwargs...) =
    edit_original_interaction_response(_rest(to), i.application_id, i.token; files, kwargs...)

"""
    delete_response(to, interaction)
"""
delete_response(to::Rest, i::Interaction) =
    delete_original_interaction_response(_rest(to), i.application_id, i.token)

"""
    reply(to, message; content, kwargs...) -> Message

Send a message as an inline reply to another.

```julia
on!(client, MessageCreate) do c, ev
    ev.message.content == "!ping" && reply(c, ev.message; content="pong")
end
```
"""
reply(to::Rest, m::Message; kwargs...) =
    create_message(_rest(to), m.channel_id;
                   message_reference=(; message_id=m.id), kwargs...)
