# Discord JSON distinguishes fields that are absent from fields that are null.
# We mirror that with Julia's two bottom-ish values:
#
#   missing  — the field was not in the payload (or should be left out of one)
#   nothing  — the field was explicitly null (or should be sent as null)

"""
    Optional{T}

A field that may be absent from a Discord payload. Absent fields deserialize as
`missing` and `missing` fields are left out of serialized payloads.
"""
const Optional{T} = Union{T,Missing}

"""
    Nullable{T}

A field that is always present in a Discord payload but may be `null`. Null
deserializes as `nothing`, and `nothing` serializes back to `null`.
"""
const Nullable{T} = Union{T,Nothing}

"""
    OptionalNullable{T}

A field that may be absent *or* null. See [`Optional`](@ref) and [`Nullable`](@ref).
"""
const OptionalNullable{T} = Union{T,Missing,Nothing}

"""
    DiscordObject

Supertype of every Discord entity defined with [`@discord_object`](@ref).
Instances compare fieldwise with `==` and print compactly.
"""
abstract type DiscordObject end

function Base.:(==)(a::T, b::T) where {T<:DiscordObject}
    all(f -> isequal(getfield(a, f), getfield(b, f)), fieldnames(T))
end

function Base.hash(x::DiscordObject, h::UInt)
    for f in fieldnames(typeof(x))
        h = hash(getfield(x, f), h)
    end
    hash(nameof(typeof(x)), h)
end

function Base.show(io::IO, x::DiscordObject)
    print(io, nameof(typeof(x)), '(')
    shown = 0
    for f in fieldnames(typeof(x))
        v = getfield(x, f)
        v === missing && continue
        if shown == 4
            print(io, ", …")
            break
        end
        shown > 0 && print(io, ", ")
        print(io, f, '=')
        _showfield(io, v)
        shown += 1
    end
    print(io, ')')
end

_showfield(io::IO, v) = show(io, v)
_showfield(io::IO, v::AbstractVector) = print(io, '[', length(v), " item", length(v) == 1 ? "" : "s", ']')

# Discord timestamps look like "2017-07-11T17:27:07.299000+00:00": more
# precision than Dates handles and an offset that is always +00:00.
function discord_datetime(s::AbstractString)
    m = match(r"^(\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}:\d{2})(?:\.(\d+))?", s)
    m === nothing && throw(ArgumentError("unrecognized Discord timestamp: $s"))
    dt = DateTime(m[1], dateformat"yyyy-mm-ddTHH:MM:SS")
    m[2] === nothing && return dt
    dt + Millisecond(parse(Int, rpad(m[2], 3, '0')[1:3]))
end

# --- deserialization ------------------------------------------------------

struct _Absent end
const _ABSENT = _Absent()

_bare(::Type{T}) where {T} = Base.nonnothingtype(Base.nonmissingtype(T))

# constructfrom doesn't cover CustomStruct (which all our objects, enums, and
# flags are), so route those through construct and handle arrays ourselves.
function _reconstruct(::Type{T}, v) where {T}
    if StructTypes.StructType(T) isa StructTypes.CustomStruct
        StructTypes.construct(T, v)
    else
        StructTypes.constructfrom(T, v)
    end
end
_reconstruct(::Type{Any}, v) = v
_reconstruct(::Type{DateTime}, s::AbstractString) = discord_datetime(s)
_reconstruct(::Type{Vector{T}}, v::AbstractVector) where {T} =
    T[el isa T ? el : _reconstruct(T, el) for el in v]

function _field(::Type{FT}, v, owner::Symbol, fname::Symbol) where {FT}
    if v === _ABSENT
        Missing <: FT && return missing
        throw(ArgumentError("$owner is missing required field `$fname`"))
    elseif v === nothing
        Nothing <: FT && return nothing
        Missing <: FT && return missing
        throw(ArgumentError("$owner has null in non-nullable field `$fname`"))
    elseif v === missing
        Missing <: FT && return missing
        throw(ArgumentError("$owner is missing required field `$fname`"))
    end
    v isa FT ? v : _reconstruct(_bare(FT), v)
end

function _construct(::Type{T}, obj) where {T}
    args = Any[]
    for (fname, ftype) in zip(fieldnames(T), fieldtypes(T))
        v = get(obj, fname) do
            get(obj, String(fname), _ABSENT)
        end
        push!(args, _field(ftype, v, nameof(T), fname))
    end
    T(args...)
end

# --- serialization --------------------------------------------------------

# Lowering to a NamedTuple drops `missing` (absent) and keeps `nothing`, which
# JSON3 then writes as null. Nested objects lower recursively on their own.
function _lower(x::T) where {T}
    names = Symbol[]
    values = Any[]
    for f in fieldnames(T)
        v = getfield(x, f)
        v === missing && continue
        push!(names, f)
        push!(values, v)
    end
    NamedTuple{Tuple(names)}(Tuple(values))
end

"""
    @discord_object struct Name
        id::Snowflake
        topic::OptionalNullable{String}
        ...
    end

Define a Discord entity: an immutable struct (subtyping [`DiscordObject`](@ref)
unless another supertype is given) plus a keyword constructor where every
[`Optional`](@ref) field defaults to `missing`, wired up for JSON so that
absent/null round-trip losslessly in both directions.
"""
macro discord_object(ex)
    Meta.isexpr(ex, :struct) || error("@discord_object expects a struct definition")
    header = ex.args[2]
    name = header isa Symbol ? header : header.args[1]
    header isa Symbol && (ex.args[2] = :($header <: DiscordObject))

    fields = Symbol[]
    optionals = Symbol[]
    for f in ex.args[3].args
        f isa LineNumberNode && continue
        Meta.isexpr(f, :(::)) || error("@discord_object fields must be `name::Type`, got `$f`")
        fname, ftype = f.args
        push!(fields, fname)
        if Meta.isexpr(ftype, :curly) && ftype.args[1] in (:Optional, :OptionalNullable)
            push!(optionals, fname)
        end
    end

    kwargs = [f in optionals ? Expr(:kw, f, :missing) : f for f in fields]
    esc(quote
        Base.@__doc__ $ex
        $name(; $(kwargs...)) = $name($(fields...))
        $StructTypes.StructType(::Type{$name}) = $StructTypes.CustomStruct()
        $StructTypes.lowertype(::Type{$name}) = Any
        $StructTypes.lower(x::$name) = $_lower(x)
        $StructTypes.construct(::Type{$name}, obj::$JSON3.Object; kw...) = $_construct($name, obj)
        $StructTypes.construct(::Type{$name}, obj::AbstractDict; kw...) = $_construct($name, obj)
    end)
end

"""
    @discord_enum ChannelType UInt8 begin
        GUILD_TEXT = 0
        DM = 1
        ...
    end

Define a Discord enum as a module of constants plus a type alias, so values
read as `ChannelTypes.GUILD_TEXT` and fields as `type::ChannelType`. Unlike
`@enum`, values Discord adds later still round-trip: an unknown number
deserializes fine and prints as `ChannelType(42)`.
"""
macro discord_enum(name::Symbol, basetype::Symbol, values...)
    if length(values) == 1 && Meta.isexpr(values[1], :block)
        values = Tuple(v for v in values[1].args if !(v isa LineNumberNode))
    end
    modname = Symbol(name, 's')
    T = :($modname.T)

    consts = Expr[]
    names = Expr[]
    for v in values
        Meta.isexpr(v, :(=)) || error("@discord_enum expects NAME = value entries, got `$v`")
        vname, vval = v.args
        push!(consts, :(const $vname = T($vval)))
        push!(names, :(NAMES[$basetype($vval)] = $(QuoteNode(vname))))
    end

    modexpr = :(module $modname
        struct T
            value::$basetype
        end
        T(x::T) = x
        const NAMES = Base.Dict{$basetype,Symbol}()
        $(consts...)
        $(names...)
    end)

    esc(Expr(:toplevel, modexpr, quote
        const $name = $T
        $StructTypes.StructType(::Type{$T}) = $StructTypes.CustomStruct()
        $StructTypes.lower(x::$T) = x.value
        $StructTypes.lowertype(::Type{$T}) = $basetype
        $StructTypes.construct(::Type{$T}, x::Number; kw...) = $T($basetype(x))
        Base.:(==)(x::$T, n::Integer) = x.value == n
        Base.:(==)(n::Integer, x::$T) = x.value == n
        Base.hash(x::$T, h::UInt) = hash(x.value, h)
        function Base.show(io::IO, x::$T)
            label = get($modname.NAMES, x.value, nothing)
            if label === nothing
                print(io, $(string(name)), '(', x.value, ')')
            else
                print(io, $(string(modname)), '.', label)
            end
        end
        nothing
    end))
end

"""
    @discord_flags Permissions UInt64 :string begin
        create_instant_invite = 1 << 0
        kick_members = 1 << 1
        ...
    end

Define a Discord bit-flag set: a module of individual flags plus a plural type
alias, so single flags read as `Permission.kick_members` and combined values as
`Permissions`. Flags combine with `|`, intersect with `&`, and support
`flag in flags`. The third argument picks the wire format — `:number` for
fields Discord sends as JSON numbers, `:string` for stringified ones (permissions).
"""
macro discord_flags(name::Symbol, basetype::Symbol, wire::QuoteNode, values...)
    if length(values) == 1 && Meta.isexpr(values[1], :block)
        values = Tuple(v for v in values[1].args if !(v isa LineNumberNode))
    end
    endswith(String(name), 's') || error("@discord_flags type name should be plural, got `$name`")
    modname = Symbol(chop(String(name)))
    T = :($modname.T)

    consts = Expr[]
    names = Expr[]
    allbits = :(zero($basetype))
    for v in values
        Meta.isexpr(v, :(=)) || error("@discord_flags expects name = value entries, got `$v`")
        vname, vval = v.args
        push!(consts, :(const $vname = T($vval)))
        push!(names, :($basetype($vval) => $(QuoteNode(vname))))
        allbits = :($allbits | $basetype($vval))
    end

    modexpr = :(module $modname
        struct T
            value::$basetype
        end
        T(x::T) = x
        const none = T(0)
        $(consts...)
        const all = T($allbits)
        const NAMES = [$(names...)]
    end)

    serialization = wire.value === :string ? quote
        $StructTypes.lower(x::$T) = string(x.value)
        $StructTypes.lowertype(::Type{$T}) = String
        $StructTypes.construct(::Type{$T}, s::AbstractString; kw...) = $T(parse($basetype, s))
        $StructTypes.construct(::Type{$T}, x::Number; kw...) = $T($basetype(x))
    end : quote
        $StructTypes.lower(x::$T) = x.value
        $StructTypes.lowertype(::Type{$T}) = $basetype
        $StructTypes.construct(::Type{$T}, x::Number; kw...) = $T($basetype(x))
        $StructTypes.construct(::Type{$T}, s::AbstractString; kw...) = $T(parse($basetype, s))
    end

    esc(Expr(:toplevel, modexpr, quote
        const $name = $T
        $StructTypes.StructType(::Type{$T}) = $StructTypes.CustomStruct()
        $serialization
        Base.:|(a::$T, b::$T) = $T(a.value | b.value)
        Base.:&(a::$T, b::$T) = $T(a.value & b.value)
        Base.xor(a::$T, b::$T) = $T(xor(a.value, b.value))
        Base.:~(a::$T) = $T(~a.value & $modname.all.value)
        Base.in(a::$T, b::$T) = !iszero(a.value) && a.value & b.value == a.value
        Base.iszero(a::$T) = iszero(a.value)
        Base.hash(x::$T, h::UInt) = hash(x.value, h)
        function Base.show(io::IO, x::$T)
            iszero(x.value) && return print(io, $(string(modname)), ".none")
            rest = x.value
            shown = false
            for (bit, label) in $modname.NAMES
                iszero(bit & rest) && continue
                shown && print(io, " | ")
                print(io, $(string(modname)), '.', label)
                rest &= ~bit
                shown = true
            end
            if !iszero(rest)
                shown && print(io, " | ")
                print(io, $(string(name)), "(0x", string(rest, base=16), ')')
            end
        end
        nothing
    end))
end
