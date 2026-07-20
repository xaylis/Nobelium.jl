export AudioSource, OpusFrames

# 48 kHz, 20 ms frames — the only configuration Discord speaks.
const OPUS_SAMPLE_RATE = 48_000
const FRAME_MILLIS = 20
const SAMPLES_PER_FRAME = OPUS_SAMPLE_RATE ÷ 1000 * FRAME_MILLIS

# Five frames of Opus silence flush jitter buffers when playback stops.
const SILENCE_FRAME = UInt8[0xf8, 0xff, 0xfe]

"""
    AudioSource

Anything that yields 20 ms Opus frames as `Vector{UInt8}` when iterated.
Nobelium ships [`OpusFrames`](@ref) for pre-encoded audio; wrap your own
decoder by implementing the iteration protocol.
"""
abstract type AudioSource end

"""
    OpusFrames(frames)

The simplest [`AudioSource`](@ref): a prepared collection of 20 ms Opus
frames. Produce them with e.g.
`ffmpeg -i song.mp3 -c:a libopus -f data -` fed through an Ogg demuxer, or any
Opus encoder bindings.
"""
struct OpusFrames <: AudioSource
    frames::Vector{Vector{UInt8}}
end

Base.iterate(s::OpusFrames, i=1) = i > length(s.frames) ? nothing : (s.frames[i], i + 1)
Base.length(s::OpusFrames) = length(s.frames)

# RTP: 12-byte header (version/payload type, sequence, timestamp, ssrc)
# followed by the encrypted opus payload.
function rtp_header(seq::UInt16, timestamp::UInt32, ssrc::UInt32)
    header = Vector{UInt8}(undef, 12)
    header[1] = 0x80
    header[2] = 0x78
    header[3:4] = reinterpret(UInt8, [hton(seq)])
    header[5:8] = reinterpret(UInt8, [hton(timestamp)])
    header[9:12] = reinterpret(UInt8, [hton(ssrc)])
    header
end

# The *_rtpsize modes append a 32-bit incrementing counter to each packet and
# use it (zero-padded) as the AEAD nonce, with the RTP header as AAD.
function encrypt_rtp_packet(opus::AbstractVector{UInt8}, header::Vector{UInt8},
                            counter::UInt32, key::Vector{UInt8})
    nonce = zeros(UInt8, XCHACHA20_NONCE_BYTES)
    nonce[1:4] = reinterpret(UInt8, [hton(counter)])
    sealed = encrypt_voice_frame(Vector{UInt8}(opus), header, nonce, key)
    vcat(header, sealed, nonce[1:4])
end
