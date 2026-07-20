"""
    Route(method, template)

A REST route with `{placeholder}` path parameters, e.g.
`Route(:POST, "/channels/{channel_id}/messages")`. Parameters are filled
positionally by [`request`](@ref) in template order.
"""
struct Route
    method::Symbol
    template::String
end

# Rate limits share a bucket across all values of minor parameters (a message
# id, an emoji) but not across these major ones.
const MAJOR_PARAMS = ("{channel_id}", "{guild_id}", "{webhook_id}", "{interaction_token}")

function path(route::Route, params...)
    out = route.template
    for p in params
        m = match(r"\{[a-z_]+\}", out)
        m === nothing && throw(ArgumentError("too many parameters for route $(route.template)"))
        out = string(out[1:m.offset-1], escapeuri(string(p)), out[m.offset+length(m.match):end])
    end
    occursin('{', out) && throw(ArgumentError("missing parameters for route $(route.template)"))
    out
end

# The key requests are grouped under until Discord tells us its real bucket id:
# method + template + the values of any major parameters.
function bucket_key(route::Route, params...)
    parts = [String(route.method), route.template]
    i = 0
    for m in eachmatch(r"\{[a-z_]+\}", route.template)
        i += 1
        i <= length(params) || break
        m.match in MAJOR_PARAMS && push!(parts, string(params[i]))
    end
    join(parts, ' ')
end
