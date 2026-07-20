# https://docs.discord.com/developers/events/gateway-events#activity-object

export Activity, ActivityTimestamps, ActivityEmoji, ActivityParty, ActivityAssets,
    ActivitySecrets, ActivityButton, ActivityType, ActivityTypes, StatusDisplayType,
    StatusDisplayTypes, ActivityFlags, ActivityFlag, ClientStatus

@discord_enum ActivityType UInt8 begin
    GAME = 0
    STREAMING = 1
    LISTENING = 2
    WATCHING = 3
    CUSTOM = 4
    COMPETING = 5
end

@discord_enum StatusDisplayType UInt8 begin
    NAME = 0
    STATE = 1
    DETAILS = 2
end

@discord_flags ActivityFlags UInt16 :number begin
    instance = 1 << 0
    join = 1 << 1
    spectate = 1 << 2
    join_request = 1 << 3
    sync = 1 << 4
    play = 1 << 5
    party_privacy_friends = 1 << 6
    party_privacy_voice_channel = 1 << 7
    embedded = 1 << 8
end

@discord_object struct ActivityTimestamps
    start::Optional{Int}
    stop::Optional{Int}
end

@discord_object struct ActivityEmoji
    name::String
    id::Optional{Snowflake}
    animated::Optional{Bool}
end

@discord_object struct ActivityParty
    id::Optional{String}
    size::Optional{Vector{Int}}
end

@discord_object struct ActivityAssets
    large_image::Optional{String}
    large_text::Optional{String}
    large_url::Optional{String}
    small_image::Optional{String}
    small_text::Optional{String}
    small_url::Optional{String}
    invite_cover_image::Optional{String}
end

@discord_object struct ActivitySecrets
    join::Optional{String}
    spectate::Optional{String}
    match::Optional{String}
end

"""
    ActivityButton

A Rich Presence button. Discord sends `buttons` on the wire as an array of
label strings; bots cannot see the URLs of other users' activity buttons.
"""
@discord_object struct ActivityButton
    label::String
    url::String
end

"""
    Activity

A user's activity — playing a game, streaming, listening, a custom status, etc.
"""
@discord_object struct Activity
    name::String
    type::ActivityType
    url::OptionalNullable{String}
    created_at::Int
    timestamps::Optional{ActivityTimestamps}
    application_id::Optional{Snowflake}
    status_display_type::OptionalNullable{StatusDisplayType}
    details::OptionalNullable{String}
    details_url::OptionalNullable{String}
    state::OptionalNullable{String}
    state_url::OptionalNullable{String}
    emoji::OptionalNullable{ActivityEmoji}
    party::Optional{ActivityParty}
    assets::Optional{ActivityAssets}
    secrets::Optional{ActivitySecrets}
    instance::Optional{Bool}
    flags::Optional{ActivityFlags}
    buttons::Optional{Vector{String}}
end

"""
    ClientStatus

A user's platform-dependent status from a [`PresenceUpdate`](@ref) event. Active
sessions carry `"online"`, `"idle"`, or `"dnd"`; offline platforms are absent.
"""
@discord_object struct ClientStatus
    desktop::Optional{String}
    mobile::Optional{String}
    web::Optional{String}
end
