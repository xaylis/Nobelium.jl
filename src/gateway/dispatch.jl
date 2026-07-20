export on!, off!, wait_for, AbstractEvent, UnknownEvent

"""
    AbstractEvent

Supertype of every gateway event. Register handlers with [`on!`](@ref).
"""
abstract type AbstractEvent <: DiscordObject end

"""
    UnknownEvent

Fallback for dispatch types Nobelium doesn't know (yet) — carries the raw
event `name` and unparsed `data`, so new Discord features never crash a bot.
"""
struct UnknownEvent <: AbstractEvent
    name::String
    data::Any
end

# Handler registry. Handlers are keyed by event type; delivery fans out on
# separate tasks so one slow or throwing handler can't stall the shard reader.

struct Dispatcher
    lock::ReentrantLock
    handlers::Dict{DataType,Vector{Any}}
end

Dispatcher() = Dispatcher(ReentrantLock(), Dict{DataType,Vector{Any}}())

function _register!(d::Dispatcher, T::DataType, f)
    lock(d.lock) do
        push!(get!(Vector{Any}, d.handlers, T), f)
    end
    f
end

function _unregister!(d::Dispatcher, T::DataType, f)
    lock(d.lock) do
        fs = get(d.handlers, T, nothing)
        fs === nothing || filter!(g -> g !== f, fs)
    end
    nothing
end

function dispatch!(d::Dispatcher, client, event)
    fs = lock(d.lock) do
        fs = get(d.handlers, typeof(event), nothing)
        fs === nothing ? nothing : copy(fs)
    end
    fs === nothing && return
    for f in fs
        errormonitor(@async try
            f(client, event)
        catch e
            @error "handler for $(nameof(typeof(event))) threw" exception = (e, catch_backtrace())
        end)
    end
    nothing
end

function _wait_for(pred, d::Dispatcher, T::DataType; timeout=nothing)
    found = Channel{Any}(1)
    handler = (client, event) -> begin
        if pred(client, event)
            try
                put!(found, event)
            catch  # channel already closed by timeout
            end
        end
    end
    _register!(d, T, handler)
    timer = timeout === nothing ? nothing : Timer(_ -> close(found), timeout)
    try
        take!(found)
    catch e
        e isa InvalidStateException ? nothing : rethrow()
    finally
        timer === nothing || close(timer)
        _unregister!(d, T, handler)
    end
end
