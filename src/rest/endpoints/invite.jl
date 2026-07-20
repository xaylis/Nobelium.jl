# https://docs.discord.com/developers/resources/invite

export get_invite, delete_invite, get_invite_target_users,
    update_invite_target_users, get_invite_target_users_job_status

"""
    get_invite(api, code; with_counts, guild_scheduled_event_id) -> Invite

[Docs](https://docs.discord.com/developers/resources/invite#get-invite)
"""
get_invite(api::API, code::AbstractString; kwargs...) =
    request(api, Route(:GET, "/invites/{invite_code}"), code; query=kwargs, into=Invite)

"""
    delete_invite(api, code; reason) -> Invite

Requires `MANAGE_CHANNELS` on the invite's channel or `MANAGE_GUILD`.
[Docs](https://docs.discord.com/developers/resources/invite#delete-invite)
"""
function delete_invite(api::API, code::AbstractString; reason=nothing)
    request(api, Route(:DELETE, "/invites/{invite_code}"), code; into=Invite, reason)
end

"""
    get_invite_target_users(api, code) -> String

The users allowed to accept a targeted invite, as CSV (`user_id` header, one
ID per line).
[Docs](https://docs.discord.com/developers/resources/invite#get-target-users)
"""
get_invite_target_users(api::API, code::AbstractString) =
    request(api, Route(:GET, "/invites/{invite_code}/target-users"), code; into=String)

"""
    update_invite_target_users(api, code, csv)

Replace a targeted invite's allowed users. `csv` is the file content: a single
`user_id` column. Processing is asynchronous — poll
[`get_invite_target_users_job_status`](@ref).
[Docs](https://docs.discord.com/developers/resources/invite#update-target-users)
"""
update_invite_target_users(api::API, code::AbstractString, csv::AbstractString) =
    request(api, Route(:PUT, "/invites/{invite_code}/target-users"), code;
            body=HTTP.Form(["target_users_file" =>
                HTTP.Multipart("target_users.csv", IOBuffer(csv), "text/csv")]))

"""
    get_invite_target_users_job_status(api, code)

[Docs](https://docs.discord.com/developers/resources/invite#get-target-users-job-status)
"""
get_invite_target_users_job_status(api::API, code::AbstractString) =
    request(api, Route(:GET, "/invites/{invite_code}/target-users/job-status"), code; into=Any)
