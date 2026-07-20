# https://docs.discord.com/developers/interactions/receiving-and-responding

export create_interaction_response, get_original_interaction_response,
    edit_original_interaction_response, delete_original_interaction_response,
    create_followup_message, get_followup_message, edit_followup_message,
    delete_followup_message

"""
    create_interaction_response(api, interaction_id, interaction_token; type, data, files, with_response) -> InteractionCallbackResponse

Answer an interaction. Must happen within 3 seconds of receiving it. Returns
`nothing` unless `with_response=true`, which returns the message (or other
resource) the response produced.
[Docs](https://docs.discord.com/developers/interactions/receiving-and-responding#create-interaction-response)
"""
function create_interaction_response(api::API, interaction::SnowflakeLike, token::AbstractString;
                                     with_response=missing, files=nothing, kwargs...)
    request(api, Route(:POST, "/interactions/{interaction_id}/{interaction_token}/callback"),
            snowflake(interaction), token;
            body=kwargs, query=(; with_response), files,
            into=(with_response === true ? InteractionCallbackResponse : nothing), auth=:none)
end

"""
    get_original_interaction_response(api, application_id, interaction_token) -> Message

[Docs](https://docs.discord.com/developers/interactions/receiving-and-responding#get-original-interaction-response)
"""
get_original_interaction_response(api::API, application::SnowflakeLike, token::AbstractString) =
    request(api,
            Route(:GET, "/webhooks/{application_id}/{interaction_token}/messages/@original"),
            snowflake(application), token; into=Message, auth=:none)

"""
    edit_original_interaction_response(api, application_id, interaction_token; content, embeds, components, files, ...) -> Message

[Docs](https://docs.discord.com/developers/interactions/receiving-and-responding#edit-original-interaction-response)
"""
edit_original_interaction_response(api::API, application::SnowflakeLike, token::AbstractString;
                                   files=nothing, kwargs...) =
    request(api,
            Route(:PATCH, "/webhooks/{application_id}/{interaction_token}/messages/@original"),
            snowflake(application), token; body=kwargs, files, into=Message, auth=:none)

"""
    delete_original_interaction_response(api, application_id, interaction_token)

[Docs](https://docs.discord.com/developers/interactions/receiving-and-responding#delete-original-interaction-response)
"""
delete_original_interaction_response(api::API, application::SnowflakeLike, token::AbstractString) =
    request(api,
            Route(:DELETE, "/webhooks/{application_id}/{interaction_token}/messages/@original"),
            snowflake(application), token; auth=:none)

"""
    create_followup_message(api, application_id, interaction_token; content, embeds, components, files, ...) -> Message

Send an extra message after responding (or deferring). Valid for 15 minutes.
[Docs](https://docs.discord.com/developers/interactions/receiving-and-responding#create-followup-message)
"""
create_followup_message(api::API, application::SnowflakeLike, token::AbstractString;
                        files=nothing, kwargs...) =
    request(api, Route(:POST, "/webhooks/{application_id}/{interaction_token}"),
            snowflake(application), token; body=kwargs, files, into=Message, auth=:none)

"""
    get_followup_message(api, application_id, interaction_token, message_id) -> Message

[Docs](https://docs.discord.com/developers/interactions/receiving-and-responding#get-followup-message)
"""
get_followup_message(api::API, application::SnowflakeLike, token::AbstractString,
                     message::SnowflakeLike) =
    request(api, Route(:GET, "/webhooks/{application_id}/{interaction_token}/messages/{message_id}"),
            snowflake(application), token, snowflake(message); into=Message, auth=:none)

"""
    edit_followup_message(api, application_id, interaction_token, message_id; content, embeds, components, files, ...) -> Message

[Docs](https://docs.discord.com/developers/interactions/receiving-and-responding#edit-followup-message)
"""
edit_followup_message(api::API, application::SnowflakeLike, token::AbstractString,
                      message::SnowflakeLike; files=nothing, kwargs...) =
    request(api, Route(:PATCH, "/webhooks/{application_id}/{interaction_token}/messages/{message_id}"),
            snowflake(application), token, snowflake(message); body=kwargs, files,
            into=Message, auth=:none)

"""
    delete_followup_message(api, application_id, interaction_token, message_id)

[Docs](https://docs.discord.com/developers/interactions/receiving-and-responding#delete-followup-message)
"""
delete_followup_message(api::API, application::SnowflakeLike, token::AbstractString,
                        message::SnowflakeLike) =
    request(api,
            Route(:DELETE, "/webhooks/{application_id}/{interaction_token}/messages/{message_id}"),
            snowflake(application), token, snowflake(message); auth=:none)
