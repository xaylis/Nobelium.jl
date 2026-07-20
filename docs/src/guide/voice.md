# Voice (experimental)

Nobelium can join voice channels and stream audio. The support is
**experimental and send-only**: it speaks the current voice gateway (v8) with
the required `aead_xchacha20_poly1305_rtpsize` transport encryption, but does
not yet implement Discord's DAVE end-to-end encryption protocol — expect this
area to evolve.

## Requirements

- `libsodium_jll` loaded next to Nobelium (it activates the encryption
  extension): `using Nobelium, libsodium_jll`
- the `guild_voice_states` intent
- audio as **pre-encoded Opus frames** (48 kHz, 20 ms). Nobelium deliberately
  ships no audio encoder; produce frames with any Opus encoder, e.g. ffmpeg +
  an Ogg demuxer, or Opus bindings.

## Playing audio

```julia
using Nobelium, libsodium_jll

client = Client(ENV["DISCORD_TOKEN"];
                intents=Intent.default)   # includes guild_voice_states

on!(client, MessageCreate) do c, ev
    ev.message.content == "!play" || return
    vc = connect_voice!(c, ev.guild_id, VOICE_CHANNEL_ID)
    try
        play!(vc, OpusFrames(my_frames))   # blocks, paced at 20 ms per frame
    finally
        disconnect_voice!(vc)
    end
end

start!(client)
```

`connect_voice!` performs the whole dance — voice state/server events, the
voice websocket handshake, UDP IP discovery, and encryption setup — and
returns once the connection can transmit. `play!` toggles the speaking flag,
paces frames in real time, and flushes silence frames at the end so the last
of the audio isn't clipped.

## Known limitations

- Send-only: incoming audio is not decoded.
- No DAVE (E2EE): contexts where Discord mandates end-to-end encryption may
  reject the connection.
- One `VoiceClient` per guild at a time, driven manually — no queueing layer.
