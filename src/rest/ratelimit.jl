# Discord rate limits requests per "bucket": groups of routes it identifies in
# the X-RateLimit-Bucket response header. Until we've seen a route's first
# response we guess buckets from the route itself (see bucket_key); afterwards
# we track exactly what Discord reports. On top of that sits the global limit
# of 50 requests a second.

mutable struct Bucket
    remaining::Int
    reset_at::Float64
end

mutable struct RateLimiter
    const lock::ReentrantLock
    const buckets::Dict{String,Bucket}   # bucket id (or route key) -> state
    const routes::Dict{String,String}    # route key -> Discord bucket id
    const clock::Function
    const sleeper::Function
    global_limit::Int
    global_window::Float64
    global_count::Int
    pause_until::Float64
end

RateLimiter(; clock=time, sleeper=sleep, global_limit=50) =
    RateLimiter(ReentrantLock(), Dict{String,Bucket}(), Dict{String,String}(),
                clock, sleeper, global_limit, -Inf, 0, -Inf)

function _bucket(rl::RateLimiter, key::String)
    id = get(rl.routes, key, key)
    get(rl.buckets, id, nothing)
end

# Block until the request behind `key` is allowed to go out, consuming one slot
# from its bucket and from the global window.
function acquire!(rl::RateLimiter, key::String)
    while true
        delay = lock(rl.lock) do
            now = rl.clock()
            now < rl.pause_until && return rl.pause_until - now
            if now - rl.global_window >= 1.0
                rl.global_window = now
                rl.global_count = 0
            end
            rl.global_count >= rl.global_limit && return rl.global_window + 1.0 - now
            b = _bucket(rl, key)
            if b !== nothing && b.remaining <= 0 && now < b.reset_at
                return b.reset_at - now
            end
            b !== nothing && (b.remaining -= 1)
            rl.global_count += 1
            0.0
        end
        delay <= 0 && return
        rl.sleeper(delay)
    end
end

# Fold a response's rate-limit headers back in.
function update!(rl::RateLimiter, key::String;
                 bucket::Union{String,Nothing}=nothing,
                 remaining::Union{Int,Nothing}=nothing,
                 reset_after::Union{Float64,Nothing}=nothing)
    lock(rl.lock) do
        id = bucket === nothing ? get(rl.routes, key, key) : bucket
        if bucket !== nothing && get(rl.routes, key, nothing) != bucket
            rl.routes[key] = bucket
            # the guessed per-route bucket is superseded
            delete!(rl.buckets, key)
        end
        b = get!(() -> Bucket(1, -Inf), rl.buckets, id)
        remaining === nothing || (b.remaining = remaining)
        reset_after === nothing || (b.reset_at = rl.clock() + reset_after)
    end
    nothing
end

# A 429 with "global": true halts everything.
function pause_globally!(rl::RateLimiter, seconds::Real)
    lock(rl.lock) do
        rl.pause_until = max(rl.pause_until, rl.clock() + seconds)
    end
    nothing
end
