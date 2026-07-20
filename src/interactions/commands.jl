# Builders for application commands. These produce plain named tuples shaped
# like the docs' JSON params, ready for create_global_application_command and
# friends.

export slash_command, user_command, message_command, command_option, choice,
    subcommand, subcommand_group

"""
    slash_command(name, description; options=[], kwargs...) -> NamedTuple

Build a CHAT_INPUT command payload.

```julia
create_global_application_command(api, app_id;
    slash_command("roll", "Roll some dice";
        options=[command_option(:integer, "sides", "How many sides"; required=true)])...)
```
"""
function slash_command(name::AbstractString, description::AbstractString;
                       options=missing, kwargs...)
    cmd = (; name, description, type=Int(ApplicationCommandTypes.CHAT_INPUT.value), kwargs...)
    options === missing ? cmd : (; cmd..., options)
end

"""
    user_command(name; kwargs...) -> NamedTuple

A command shown in the right-click menu on users.
"""
user_command(name::AbstractString; kwargs...) =
    (; name, type=Int(ApplicationCommandTypes.USER.value), kwargs...)

"""
    message_command(name; kwargs...) -> NamedTuple

A command shown in the right-click menu on messages.
"""
message_command(name::AbstractString; kwargs...) =
    (; name, type=Int(ApplicationCommandTypes.MESSAGE.value), kwargs...)

const _OPTION_TYPES = Dict(
    :subcommand => 1, :subcommand_group => 2, :string => 3, :integer => 4,
    :boolean => 5, :user => 6, :channel => 7, :role => 8, :mentionable => 9,
    :number => 10, :attachment => 11,
)

"""
    command_option(type, name, description; required, choices, autocomplete, ...) -> NamedTuple

One option of a slash command. `type` is a symbol: `:string`, `:integer`,
`:boolean`, `:user`, `:channel`, `:role`, `:mentionable`, `:number`, or
`:attachment`. Pass `choices=[choice("Red", "red"), ...]` for fixed choices.
"""
function command_option(type::Symbol, name::AbstractString, description::AbstractString;
                        kwargs...)
    haskey(_OPTION_TYPES, type) ||
        throw(ArgumentError("unknown option type :$type (one of $(join(keys(_OPTION_TYPES), ", ")))"))
    (; type=_OPTION_TYPES[type], name, description, kwargs...)
end

"""
    choice(name, value) -> NamedTuple
"""
choice(name::AbstractString, value) = (; name, value)

"""
    subcommand(name, description; options=[]) -> NamedTuple
"""
function subcommand(name::AbstractString, description::AbstractString; options=missing)
    sub = (; type=1, name, description)
    options === missing ? sub : (; sub..., options)
end

"""
    subcommand_group(name, description, subcommands...) -> NamedTuple
"""
subcommand_group(name::AbstractString, description::AbstractString, subcommands...) =
    (; type=2, name, description, options=collect(subcommands))
