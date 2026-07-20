using Documenter
using DocumenterVitepress
using Nobelium

makedocs(;
    modules=[Nobelium],
    authors="Nobelium contributors",
    repo="https://github.com/xaylis/Nobelium.jl",
    sitename="Nobelium.jl",
    format=DocumenterVitepress.MarkdownVitepress(;
        repo="github.com/xaylis/Nobelium.jl",
        devbranch="main",
        devurl="dev",
    ),
    pages=[
        "Home" => "index.md",
        "Guide" => [
            "Getting started" => "guide/getting-started.md",
            "Client and events" => "guide/client-and-events.md",
            "The REST API" => "guide/rest.md",
            "Interactions" => "guide/interactions.md",
            "Components" => "guide/components.md",
            "Caching" => "guide/caching.md",
            "Sharding" => "guide/sharding.md",
            "Voice" => "guide/voice.md",
            "Errors" => "guide/errors.md",
        ],
        "Tutorials" => [
            "Your first bot" => "tutorials/first-bot.md",
            "Slash commands" => "tutorials/slash-commands.md",
            "A moderation bot" => "tutorials/moderation-bot.md",
        ],
        "Reference" => [
            "Client" => "reference/client.md",
            "Events" => "reference/events.md",
            "Types" => "reference/types.md",
            "REST endpoints" => "reference/rest.md",
        ],
    ],
    warnonly=true,
)

DocumenterVitepress.deploydocs(;
    repo="github.com/xaylis/Nobelium.jl",
    target=joinpath(@__DIR__, "build"),
    devbranch="main",
    branch="gh-pages",
    push_preview=true,
)
