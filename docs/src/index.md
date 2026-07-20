```@raw html
---
layout: home

hero:
  name: Nobelium.jl
  text: Discord bots in Julia
  tagline: Build Discord bots with an interface that feels like Julia.
  actions:
    - theme: brand
      text: Get started
      link: /guide/getting-started
    - theme: alt
      text: Tutorials
      link: /tutorials/first-bot
    - theme: alt
      text: View on GitHub
      link: https://github.com/xaylis/Nobelium.jl

features:
  - title: One package
    details: REST, gateway events, slash commands, components, and voice, without extra plumbing.
  - title: Julian by design
    details: Multiple dispatch for events, do-blocks for handlers, keyword arguments everywhere. No framework ceremony.
  - title: Correct under pressure
    details: Per-route rate limiting, automatic resume after disconnects, and lossless absent-vs-null JSON handling.
  - title: Batteries included
    details: Slash commands, buttons, select menus, modals, thread-safe caching, and sharding that configures itself.
---
```

## A complete bot in fifteen lines

```julia
using Nobelium

client = Client(ENV["DISCORD_TOKEN"];
                intents=Intent.default | Intent.message_content)

on!(client, MessageCreate) do c, ev
    ev.message.author.bot === true && return
    if startswith(ev.message.content, "!roll")
        reply(c, ev.message; content="🎲 you rolled a $(rand(1:6))")
    end
end

start!(client)
```

## Installation

Nobelium requires Julia 1.10 or later.

```julia
using Pkg
Pkg.add(url="https://github.com/xaylis/Nobelium.jl")
```
