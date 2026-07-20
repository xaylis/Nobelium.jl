# Provides the aead_xchacha20_poly1305_rtpsize transport encryption voice
# connections require. Activated by loading libsodium_jll next to Nobelium.
module NobeliumSodiumExt

using Nobelium
using libsodium_jll: libsodium

function Nobelium.encrypt_voice_frame(plaintext::Vector{UInt8}, aad::Vector{UInt8},
                                      nonce::Vector{UInt8}, key::Vector{UInt8})
    length(nonce) == Nobelium.XCHACHA20_NONCE_BYTES || throw(ArgumentError("nonce must be 24 bytes"))
    length(key) == 32 || throw(ArgumentError("key must be 32 bytes"))
    out = Vector{UInt8}(undef, length(plaintext) + Nobelium.XCHACHA20_TAG_BYTES)
    outlen = Ref{UInt64}(0)
    rc = ccall((:crypto_aead_xchacha20poly1305_ietf_encrypt, libsodium), Cint,
               (Ptr{UInt8}, Ptr{UInt64}, Ptr{UInt8}, UInt64, Ptr{UInt8}, UInt64,
                Ptr{Cvoid}, Ptr{UInt8}, Ptr{UInt8}),
               out, outlen, plaintext, length(plaintext), aad, length(aad),
               C_NULL, nonce, key)
    rc == 0 || error("libsodium encryption failed (code $rc)")
    resize!(out, outlen[])
end

end
