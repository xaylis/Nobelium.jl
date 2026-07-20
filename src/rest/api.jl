const API_VERSION = 10
const _USER_AGENT = "DiscordBot (https://github.com/xaylis/Nobelium.jl, 0.2.0)"

"""
    DiscordFile(filename, data; content_type="application/octet-stream")

A file attachment for endpoints that accept uploads, e.g.
`create_message(api, ch; content="here!", files=[DiscordFile("plot.png", png_bytes)])`.
"""
struct DiscordFile
    filename::String
    data::Vector{UInt8}
    content_type::String
end

DiscordFile(filename::AbstractString, data::Vector{UInt8}; content_type="application/octet-stream") =
    DiscordFile(filename, data, content_type)
DiscordFile(filename::AbstractString, data::AbstractString; content_type="text/plain") =
    DiscordFile(filename, Vector{UInt8}(codeunits(data)), content_type)

"""
    API(token; kwargs...)

A standalone Discord REST client. Every endpoint function takes one of these
(or a `Client`, which carries one) as its first argument.

```julia
api = API(ENV["DISCORD_TOKEN"])
me = get_current_user(api)
```

Keyword arguments: `base_url`, `user_agent`, `max_retries` (retry budget for
server errors and connection failures), `limiter` (a `RateLimiter`),
and `http` — the transport function, injectable for testing.
"""
struct API
    token::String
    limiter::RateLimiter
    http::Any        # callable: (method, url, headers, body) -> HTTP.Response
    base_url::String
    user_agent::String
    max_retries::Int
end

API(token::AbstractString;
    base_url::AbstractString="https://discord.com/api/v$API_VERSION",
    user_agent::AbstractString=_USER_AGENT,
    max_retries::Integer=3,
    limiter::RateLimiter=RateLimiter(),
    http=_http_request) =
    API(String(strip(token)), limiter, http, base_url, user_agent, max_retries)

_http_request(method::String, url::String, headers, body) =
    HTTP.request(method, url, headers, body; status_exception=false, redirect=false)

# Endpoint kwargs come through as pairs; drop the `missing` ones (parameters the
# caller didn't set) and keep `nothing` (explicit nulls).
_payload(body) = body
_payload(::Nothing) = nothing
function _payload(body::Union{NamedTuple,AbstractDict,Base.Pairs})
    kept = [Symbol(k) => v for (k, v) in pairs(body) if v !== missing]
    isempty(kept) ? nothing : NamedTuple{Tuple(first.(kept))}(Tuple(last.(kept)))
end

_query_value(v) = string(v)
_query_value(v::AbstractVector) = join(v, ',')

function _query_string(query)
    parts = ["$(k)=$(escapeuri(_query_value(v)))" for (k, v) in pairs(query)
             if v !== missing && v !== nothing]
    isempty(parts) ? "" : '?' * join(parts, '&')
end

function _api_error(status::Integer, body::AbstractString)
    code, message, errors = 0, "", Pair{String,String}[]
    try
        j = JSON3.read(body)
        code = get(j, :code, 0)
        message = string(get(j, :message, ""))
        haskey(j, :errors) && (errors = flatten_errors(j.errors))
    catch
        message = first(body, 200)
    end
    isempty(message) && (message = "HTTP $status")
    APIError(status, code, message, errors)
end

"""
    request(api::API, route::Route, params...; kwargs...)

Send one REST request through the rate limiter with retries, and parse the
response. This is the pipeline every endpoint function is a thin wrapper over.

Keywords: `body` (pairs or an object; `missing` values are dropped, `nothing`
becomes null), `query`, `files` (a vector of [`DiscordFile`](@ref), sent as
multipart), `reason` (the `X-Audit-Log-Reason` header), `into` (result type;
`nothing` discards the response, `Any` returns parsed JSON), and `auth`
(`:bot`, `:bearer`, or `:none`).
"""
function request(api::API, route::Route, params...;
                 body=nothing, query=nothing, files=nothing, reason=nothing,
                 into=nothing, auth::Symbol=:bot)
    url = api.base_url * path(route, params...)
    query === nothing || (url *= _query_string(query))
    key = bucket_key(route, params...)

    headers = ["User-Agent" => api.user_agent]
    if auth === :bot
        push!(headers, "Authorization" => "Bot $(api.token)")
    elseif auth === :bearer
        push!(headers, "Authorization" => "Bearer $(api.token)")
    elseif auth !== :none
        throw(ArgumentError("auth must be :bot, :bearer, or :none"))
    end
    reason === nothing || push!(headers, "X-Audit-Log-Reason" => escapeuri(reason))

    payload = _payload(body)
    if payload isa HTTP.Form
        reqbody = payload
    elseif files !== nothing
        parts = Pair{String,Any}["files[$(i-1)]" =>
            HTTP.Multipart(f.filename, IOBuffer(f.data), f.content_type)
            for (i, f) in enumerate(files)]
        payload === nothing ||
            pushfirst!(parts, "payload_json" => HTTP.Multipart(nothing, IOBuffer(JSON3.write(payload)), "application/json"))
        reqbody = HTTP.Form(parts)
    elseif payload !== nothing
        push!(headers, "Content-Type" => "application/json")
        reqbody = JSON3.write(payload)
    else
        reqbody = UInt8[]
    end

    # A multipart Form is a one-shot stream; keep a pristine copy so retries
    # don't send empty bodies.
    template = reqbody isa HTTP.Form ? deepcopy(reqbody) : nothing

    failures = 0
    limited = 0
    while true
        acquire!(api.limiter, key)
        template === nothing || (reqbody = deepcopy(template))
        resp = try
            api.http(String(route.method), url, headers, reqbody)
        catch e
            e isa InterruptException && rethrow()
            failures += 1
            failures > api.max_retries && rethrow()
            api.limiter.sleeper(0.5 * 2.0^failures * (0.75 + rand() / 2))
            continue
        end

        update!(api.limiter, key;
                bucket=_header(resp, "X-RateLimit-Bucket"),
                remaining=_intheader(resp, "X-RateLimit-Remaining"),
                reset_after=_floatheader(resp, "X-RateLimit-Reset-After"))

        if resp.status == 429
            retry_after, is_global = _429_delay(resp)
            limited += 1
            limited > 5 && throw(RateLimitedError(retry_after, is_global))
            is_global && pause_globally!(api.limiter, retry_after)
            api.limiter.sleeper(retry_after)
        elseif 500 <= resp.status < 600
            failures += 1
            failures > api.max_retries && throw(_api_error(resp.status, String(resp.body)))
            api.limiter.sleeper(0.5 * 2.0^failures * (0.75 + rand() / 2))
        elseif resp.status >= 400
            throw(_api_error(resp.status, String(resp.body)))
        else
            resp.status == 204 && return nothing
            into === nothing && return nothing
            raw = String(resp.body)
            isempty(raw) && return nothing
            into === String && return raw
            return into === Any ? JSON3.read(raw) : JSON3.read(raw, into)
        end
    end
end

_header(resp, name) = (v = HTTP.header(resp, name); isempty(v) ? nothing : String(v))
_intheader(resp, name) = (v = _header(resp, name); v === nothing ? nothing : tryparse(Int, v))
_floatheader(resp, name) = (v = _header(resp, name); v === nothing ? nothing : tryparse(Float64, v))

function _429_delay(resp)
    retry_after = 1.0
    is_global = !isempty(HTTP.header(resp, "X-RateLimit-Global"))
    try
        j = JSON3.read(String(copy(resp.body)))
        retry_after = Float64(get(j, :retry_after, 1.0))
        is_global |= get(j, :global, false) === true
    catch
        v = _floatheader(resp, "Retry-After")
        v === nothing || (retry_after = v)
    end
    retry_after, is_global
end
