"""
    NobeliumError

Supertype of every exception Nobelium throws on its own behalf.
"""
abstract type NobeliumError <: Exception end

# Bot tokens follow a three-part dotted shape; scrub anything that looks like
# one before an error message or log line can leak it.
const TOKEN_PATTERN = r"(mfa\.[A-Za-z0-9_-]{20,}|[A-Za-z0-9_-]{23,}\.[A-Za-z0-9_-]{6,7}\.[A-Za-z0-9_-]{27,})"

"""
    redact(s) -> String

Replace anything token-shaped in `s` with `"<token>"`. Applied to every error
message and log line Nobelium produces.
"""
redact(s::AbstractString) = replace(s, TOKEN_PATTERN => "<token>")

"""
    APIError

Discord rejected a REST request. Carries the HTTP `status`, Discord's numeric
error `code` and `message`, and `errors` — the per-field validation failures
flattened into `"path" => "message"` pairs (e.g. `"embeds.0.title" => "Must be
1024 or fewer in length."`).
"""
struct APIError <: NobeliumError
    status::Int
    code::Int
    message::String
    errors::Vector{Pair{String,String}}
end

APIError(status::Integer, code::Integer, message::AbstractString) =
    APIError(status, code, message, Pair{String,String}[])

function Base.showerror(io::IO, e::APIError)
    print(io, "APIError: HTTP ", e.status, ": ", redact(e.message))
    e.code != 0 && print(io, " (Discord error code ", e.code, ")")
    for (path, msg) in e.errors
        print(io, "\n  ", path, ": ", msg)
    end
end

"""
    RateLimitedError

A request was rate limited and retried until [`API`](@ref)'s retry budget ran
out. `retry_after` is Discord's last requested wait in seconds; `global_limit`
says whether the global limit (rather than a per-route bucket) was hit.
"""
struct RateLimitedError <: NobeliumError
    retry_after::Float64
    global_limit::Bool
end

function Base.showerror(io::IO, e::RateLimitedError)
    print(io, "RateLimitedError: still ", e.global_limit ? "globally " : "",
          "rate limited after retries; Discord asked for ", e.retry_after, "s more")
end

"""
    GatewayClosedError

The gateway websocket closed. `resumable` tells you whether the session can be
resumed; Nobelium's shards handle that automatically, so user code mostly sees
this only for fatal codes (bad token, invalid intents, ...).
"""
struct GatewayClosedError <: NobeliumError
    code::Int
    reason::String
    resumable::Bool
end

function Base.showerror(io::IO, e::GatewayClosedError)
    print(io, "GatewayClosedError: close code ", e.code)
    isempty(e.reason) || print(io, " (", redact(e.reason), ")")
    print(io, e.resumable ? " — resumable" : " — not resumable")
end

# Discord reports request validation failures as a tree keyed by field name and
# array index, with `_errors` leaves. Flatten it to dotted paths for display.
function flatten_errors(node; path::String="", out=Pair{String,String}[])
    for (key, value) in pairs(node)
        name = String(key)
        if name == "_errors"
            for err in value
                push!(out, path => String(get(err, :message, "")))
            end
        elseif value isa Union{AbstractDict,JSON3.Object}
            flatten_errors(value; path=isempty(path) ? name : "$path.$name", out)
        end
    end
    out
end
