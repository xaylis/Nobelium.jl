# Nobelium.jl

[![CI](https://github.com/xaylis/Nobelium.jl/actions/workflows/ci.yml/badge.svg)](https://github.com/xaylis/Nobelium.jl/actions/workflows/ci.yml)
[![Documentation](https://img.shields.io/badge/docs-dev-blue.svg)](https://xaylis.github.io/Nobelium.jl/dev/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A Discord API wrapper for Julia.

## Installation

Requires Julia 1.10+. Nobelium is registered in the General registry:

```julia
using Pkg
Pkg.add("Nobelium")
```

## Making a bot

```julia
using Nobelium

client = Client(ENV["DISCORD_TOKEN"];
                intents=Intent.default | Intent.message_content)

on!(client, MessageCreate) do c, ev
    ev.message.author.bot === true && return
    if ev.message.content == "!ping"
        reply(c, ev.message; content="pong")
    end
end

start!(client)
```

## Using the REST API

Endpoints are plain functions, usable with or without a gateway connection:

```julia
api = API(ENV["DISCORD_TOKEN"])

channel = get_channel(api, channel_id)
msg = create_message(api, channel.id; content="deployed ✅")
create_reaction(api, channel.id, msg.id, "🎉")
```

## Documentation

Guides, tutorials, and the API reference live at
[xaylis.github.io/Nobelium.jl](https://xaylis.github.io/Nobelium.jl/dev/).

## License

MIT - see [LICENSE](LICENSE).
