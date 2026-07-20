using libsodium_jll   # activates NobeliumSodiumExt
using Nobelium: rtp_header, encrypt_rtp_packet, encrypt_voice_frame,
    voice_encryption_available, SILENCE_FRAME, SAMPLES_PER_FRAME,
    XCHACHA20_NONCE_BYTES, XCHACHA20_TAG_BYTES

@testset "voice" begin
    @testset "rtp header" begin
        h = rtp_header(0x0102, 0x03040506, 0x0708090a)
        @test length(h) == 12
        @test h[1] == 0x80 && h[2] == 0x78
        @test h[3:4] == [0x01, 0x02]            # big-endian sequence
        @test h[5:8] == [0x03, 0x04, 0x05, 0x06]
        @test h[9:12] == [0x07, 0x08, 0x09, 0x0a]
    end

    @testset "constants" begin
        @test SAMPLES_PER_FRAME == 960
        @test SILENCE_FRAME == [0xf8, 0xff, 0xfe]
    end

    @testset "encryption via libsodium" begin
        @test voice_encryption_available()
        key = rand(UInt8, 32)
        nonce = zeros(UInt8, XCHACHA20_NONCE_BYTES)
        aad = rand(UInt8, 12)
        sealed = encrypt_voice_frame(UInt8[1, 2, 3, 4], aad, nonce, key)
        @test length(sealed) == 4 + XCHACHA20_TAG_BYTES
        @test sealed[1:4] != UInt8[1, 2, 3, 4]

        # same input, same key/nonce -> deterministic; different nonce -> different
        @test encrypt_voice_frame(UInt8[1, 2, 3, 4], aad, nonce, key) == sealed
        nonce2 = copy(nonce); nonce2[1] = 0x01
        @test encrypt_voice_frame(UInt8[1, 2, 3, 4], aad, nonce2, key) != sealed

        @test_throws ArgumentError encrypt_voice_frame(UInt8[1], aad, UInt8[0x00], key)
        @test_throws ArgumentError encrypt_voice_frame(UInt8[1], aad, nonce, UInt8[0x00])
    end

    @testset "rtp packet layout" begin
        key = rand(UInt8, 32)
        header = rtp_header(0x0001, 0x00000001, 0x00000042)
        packet = encrypt_rtp_packet(UInt8[9, 9, 9], header, UInt32(7), key)
        @test packet[1:12] == header
        # trailing 4 bytes are the big-endian nonce counter
        @test packet[end-3:end] == [0x00, 0x00, 0x00, 0x07]
        @test length(packet) == 12 + 3 + XCHACHA20_TAG_BYTES + 4
    end

    @testset "OpusFrames iterates" begin
        frames = OpusFrames([UInt8[1], UInt8[2]])
        @test collect(frames) == [UInt8[1], UInt8[2]]
        @test length(frames) == 2
    end
end
