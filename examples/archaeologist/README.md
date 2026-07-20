# The Archaeologist

An example bot with two slash commands:

- `/excavate` — digs a random message out of the server's history, with a
  "dig again" button and a link to the site.
- `/timecapsule message: minutes:` — seals a message away, puts the reveal on
  the server calendar, and opens it later with a poll.

## Run it

```bash
cd examples/archaeologist
julia --project=. -e 'using Pkg; Pkg.develop(path="../.."); Pkg.instantiate()'
DISCORD_TOKEN=your-token DISCORD_GUILD=your-guild-id julia --project=. bot.jl
```

The bot needs the `applications.commands` scope and permission to read message
history, manage events, and send messages in the guild.
