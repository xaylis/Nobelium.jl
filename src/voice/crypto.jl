# Voice transport encryption. Discord requires an AEAD mode since November
# 2024; we implement aead_xchacha20_poly1305_rtpsize, provided by the
# NobeliumSodiumExt extension when libsodium_jll is loaded alongside Nobelium.

const VOICE_ENCRYPTION_MODE = "aead_xchacha20_poly1305_rtpsize"
const XCHACHA20_NONCE_BYTES = 24
const XCHACHA20_TAG_BYTES = 16

"""
    encrypt_voice_frame(plaintext, aad, nonce, key) -> Vector{UInt8}

AEAD-encrypt one audio frame (ciphertext + tag). Implemented by the
libsodium extension; without it, voice connections refuse to start.
"""
function encrypt_voice_frame end

voice_encryption_available() = !isempty(methods(encrypt_voice_frame))
