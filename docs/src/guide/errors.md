# Errors

Everything Nobelium throws on its own behalf subtypes `NobeliumError`.

## `APIError`

Discord rejected a REST call. The error carries the HTTP status, Discord's
numeric error code, the message, and — for validation failures — every field
error flattened to a dotted path:

```julia
try
    create_message(api, ch; embeds=[Embed(title="x"^300)])
catch e
    e isa APIError || rethrow()
    e.status        # 400
    e.code          # 50035
    e.errors        # ["embeds.0.title" => "Must be 256 or fewer in length."]
end
```

Common codes worth branching on: `10003` unknown channel, `10008` unknown
message, `50001` missing access, `50013` missing permissions.

## `RateLimitedError`

Thrown only after the pipeline has already retried through several 429s —
usually a sign something upstream is hammering one route.

## `GatewayClosedError`

A gateway close that can't be resumed. Recoverable closes are handled
internally; this surfaces the fatal ones — bad token (4004), invalid or
disallowed intents (4013/4014), bad sharding (4010/4011) — from `start!`.

## Token safety

Nobelium never logs your token, and every error message and log line passes
through a redaction filter that scrubs anything token-shaped before it can
reach a terminal or a log file.
