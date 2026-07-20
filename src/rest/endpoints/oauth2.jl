# https://docs.discord.com/developers/topics/oauth2

export AuthorizationInfo, get_current_bot_application_information,
    get_current_authorization_information

"""
    AuthorizationInfo

What a bearer token is authorized for: a partial [`Application`](@ref), the
granted scopes, when the token expires, and (with the `identify` scope) the user.
"""
@discord_object struct AuthorizationInfo
    application::Application
    scopes::Vector{String}
    expires::DateTime
    user::Optional{User}
end

"""
    get_current_bot_application_information(api) -> Application

[Docs](https://docs.discord.com/developers/topics/oauth2#get-current-bot-application-information)
"""
get_current_bot_application_information(api::API) =
    request(api, Route(:GET, "/oauth2/applications/@me"); into=Application)

"""
    get_current_authorization_information(api) -> AuthorizationInfo

Requires a bearer token.
[Docs](https://docs.discord.com/developers/topics/oauth2#get-current-authorization-information)
"""
get_current_authorization_information(api::API) =
    request(api, Route(:GET, "/oauth2/@me"); into=AuthorizationInfo, auth=:bearer)
