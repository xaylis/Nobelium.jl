# Many dispatch payloads are an existing object plus a few extra fields. A
# @gateway_event struct's first field is parsed from the whole payload; the
# remaining fields are read from the same payload alongside it.
macro gateway_event(ex)
    Meta.isexpr(ex, :struct) || error("@gateway_event expects a struct definition")
    name = ex.args[2]
    name isa Symbol || error("@gateway_event structs take no explicit supertype")
    ex.args[2] = :($name <: AbstractEvent)

    fields = Symbol[]
    ftypes = Any[]
    for f in ex.args[3].args
        f isa LineNumberNode && continue
        Meta.isexpr(f, :(::)) || error("@gateway_event fields must be `name::Type`, got `$f`")
        push!(fields, f.args[1])
        push!(ftypes, f.args[2])
    end
    isempty(fields) && error("@gateway_event needs at least the wrapped field")

    wtype = ftypes[1]
    extras = [:($_field($(ftypes[i]), get(obj, $(QuoteNode(fields[i])), $_ABSENT),
                        $(QuoteNode(name)), $(QuoteNode(fields[i]))))
              for i in 2:length(fields)]
    kwargs = [i == 1 ? fields[i] : Expr(:kw, fields[i], :missing) for i in eachindex(fields)]

    esc(quote
        Base.@__doc__ $ex
        $name(; $(kwargs...)) = $name($(fields...))
        $StructTypes.StructType(::Type{$name}) = $StructTypes.CustomStruct()
        $StructTypes.lowertype(::Type{$name}) = Any
        function $StructTypes.construct(::Type{$name}, obj::Union{$JSON3.Object,AbstractDict}; kw...)
            $name($_reconstruct($wtype, obj), $(extras...))
        end
    end)
end
