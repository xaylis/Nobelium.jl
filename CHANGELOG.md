# Changelog

## v0.2.0

Complete rewrite. Nothing from 0.1.x survives; the public API is new.

### Added

- REST endpoints for the resource groups 0.1.x lacked: OAuth2, applications,
  stage instances, guild scheduled events, guild templates, polls,
  SKUs/entitlements/subscriptions, soundboard, lobbies, onboarding, and
  application emojis.
- Typed structs for the gateway dispatch events, with an `UnknownEvent`
  fallback for anything Discord ships next.
- Lossless absent-vs-null JSON handling (`missing` vs `nothing`) in both
  directions.
- Interaction toolkit: command/component/modal builders and response helpers
  (`respond`, `defer`, `followup`, `show_modal`, `update_message`, ...).
- Self-configuring sharding with identify buckets, session resume, and
  heartbeat supervision.
- Thread-safe bounded entity caches maintained from gateway events.
- Experimental voice: voice gateway v8, UDP transport,
  `aead_xchacha20_poly1305_rtpsize` encryption via a `libsodium_jll`
  package extension.
- Token redaction in all errors and logs.
- A live smoke-test script (`test/live/smoke.jl`) exercising the wrapper
  against a real guild.

### Changed

- Julia 1.10 is now the minimum.
- Documentation moved to DocumenterVitepress.
- Voice encryption switched from the retired XSalsa20 modes (rejected by
  Discord since November 2024) to the required AEAD mode.
