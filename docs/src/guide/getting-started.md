# Getting started

## Create a bot account

1. Open the [Discord developer portal](https://discord.com/developers/applications) and create an application.
2. Under **Bot**, grab the token. Treat it like a password — anyone holding it *is* your bot.
3. If your bot reads message text, enable the **Message Content** privileged intent on the same page.
4. Under **OAuth2 → URL Generator**, tick `bot` (and `applications.commands` for slash commands), pick the permissions you need, and open the generated URL to invite the bot to a server.

## Install Nobelium

```julia
using Pkg
Pkg.add(url="https://github.com/xaylis/Nobelium.jl")
```

## Hello, gateway

Never hardcode the token; read it from the environment:

```julia
using Nobelium

client = Client(ENV["DISCORD_TOKEN"];
                intents=Intent.default | Intent.message_content)

on!(client, Ready) do c, ev
    @info "logged in as $(display_name(ev.user))"
end

on!(client, MessageCreate) do c, ev
    ev.message.author.bot === true && return
    ev.message.content == "!ping" && reply(c, ev.message; content="pong")
end

start!(client)
```

Run it with `DISCORD_TOKEN=... julia --project bot.jl`, say `!ping`, and you have a bot.

`start!` blocks until you call `stop!` from a handler or another task; pass
`async=true` to get the prompt back (useful in the REPL — the client keeps
running in the background).

## Where to next

- [Client and events](client-and-events.md) — the event model, `wait_for`, and the full event list.
- [The REST API](rest.md) — calling any of Discord's endpoints directly.
- [Your first bot](../tutorials/first-bot.md) — a guided build with commands and components.
