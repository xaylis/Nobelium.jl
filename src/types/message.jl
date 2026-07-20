# https://docs.discord.com/developers/resources/message

export Message, MessageType, MessageTypes, MessageFlags, MessageFlag, Reaction, ReactionCountDetails, ReactionType,
    ReactionTypes, MessageReference, MessageReferenceType, MessageReferenceTypes,
    MessageSnapshot, SnapshotMessage, MessageActivity, MessageActivityType,
    MessageActivityTypes, MessageCall, ChannelMention, AllowedMentions,
    RoleSubscriptionData, MessageInteractionMetadata, MessagePin, SharedClientTheme,
    BaseTheme, BaseThemes

@discord_enum MessageType UInt8 begin
    DEFAULT = 0
    RECIPIENT_ADD = 1
    RECIPIENT_REMOVE = 2
    CALL = 3
    CHANNEL_NAME_CHANGE = 4
    CHANNEL_ICON_CHANGE = 5
    CHANNEL_PINNED_MESSAGE = 6
    USER_JOIN = 7
    GUILD_BOOST = 8
    GUILD_BOOST_TIER_1 = 9
    GUILD_BOOST_TIER_2 = 10
    GUILD_BOOST_TIER_3 = 11
    CHANNEL_FOLLOW_ADD = 12
    GUILD_DISCOVERY_DISQUALIFIED = 14
    GUILD_DISCOVERY_REQUALIFIED = 15
    GUILD_DISCOVERY_GRACE_PERIOD_INITIAL_WARNING = 16
    GUILD_DISCOVERY_GRACE_PERIOD_FINAL_WARNING = 17
    THREAD_CREATED = 18
    REPLY = 19
    CHAT_INPUT_COMMAND = 20
    THREAD_STARTER_MESSAGE = 21
    GUILD_INVITE_REMINDER = 22
    CONTEXT_MENU_COMMAND = 23
    AUTO_MODERATION_ACTION = 24
    ROLE_SUBSCRIPTION_PURCHASE = 25
    INTERACTION_PREMIUM_UPSELL = 26
    STAGE_START = 27
    STAGE_END = 28
    STAGE_SPEAKER = 29
    STAGE_TOPIC = 31
    GUILD_APPLICATION_PREMIUM_SUBSCRIPTION = 32
    GUILD_INCIDENT_ALERT_MODE_ENABLED = 36
    GUILD_INCIDENT_ALERT_MODE_DISABLED = 37
    GUILD_INCIDENT_REPORT_RAID = 38
    GUILD_INCIDENT_REPORT_FALSE_ALARM = 39
    PURCHASE_NOTIFICATION = 44
    POLL_RESULT = 46
end

@discord_flags MessageFlags UInt32 :number begin
    crossposted = 1 << 0
    is_crosspost = 1 << 1
    suppress_embeds = 1 << 2
    source_message_deleted = 1 << 3
    urgent = 1 << 4
    has_thread = 1 << 5
    ephemeral = 1 << 6
    loading = 1 << 7
    failed_to_mention_some_roles_in_thread = 1 << 8
    suppress_notifications = 1 << 12
    is_voice_message = 1 << 13
    has_snapshot = 1 << 14
    is_components_v2 = 1 << 15
end

@discord_enum MessageActivityType UInt8 begin
    JOIN = 1
    SPECTATE = 2
    LISTEN = 3
    JOIN_REQUEST = 5
end

@discord_object struct MessageActivity
    type::MessageActivityType
    party_id::Optional{String}
end

@discord_enum MessageReferenceType UInt8 begin
    DEFAULT = 0
    FORWARD = 1
end

"""
    MessageReference

Points at another message: a reply (`DEFAULT`), a forward (`FORWARD`), or the
source of a crosspost/pin/channel-follow message. `channel_id` is optional
when creating a reply but required for forwards.
"""
@discord_object struct MessageReference
    type::Optional{MessageReferenceType}
    message_id::Optional{Snowflake}
    channel_id::Optional{Snowflake}
    guild_id::Optional{Snowflake}
    fail_if_not_exists::Optional{Bool}
end

@discord_object struct MessageCall
    participants::Vector{Snowflake}
    ended_timestamp::OptionalNullable{DateTime}
end

@discord_enum ReactionType UInt8 begin
    NORMAL = 0
    BURST = 1
end

@discord_object struct ReactionCountDetails
    burst::Int
    normal::Int
end

@discord_object struct Reaction
    count::Int
    count_details::ReactionCountDetails
    me::Bool
    me_burst::Bool
    emoji::Emoji
    burst_colors::Vector{String}
end



@discord_object struct ChannelMention
    id::Snowflake
    guild_id::Snowflake
    type::ChannelType
    name::String
end

"""
    AllowedMentions

Controls which mentions in a message's content (or component content)
actually notify users, independent of what the content contains. `parse`
entries are `"roles"`, `"users"`, and/or `"everyone"`.
"""
@discord_object struct AllowedMentions
    parse::Optional{Vector{String}}
    roles::Optional{Vector{Snowflake}}
    users::Optional{Vector{Snowflake}}
    replied_user::Optional{Bool}
end

@discord_object struct RoleSubscriptionData
    role_subscription_listing_id::Snowflake
    tier_name::String
    total_months_subscribed::Int
    is_renewal::Bool
end

"""
    MessageInteractionMetadata

Metadata about the interaction a message was sent in response to. Discord
documents three variants (application command, message component, modal
submit); this struct merges them; which fields are set depends on `type`.
"""
@discord_object struct MessageInteractionMetadata
    id::Snowflake
    type::InteractionType
    user::User
    authorizing_integration_owners::Dict{String,Snowflake}
    original_response_message_id::Optional{Snowflake}
    target_user::Optional{User}
    target_message_id::Optional{Snowflake}
    interacted_message_id::Optional{Snowflake}
    triggering_interaction_metadata::Optional{MessageInteractionMetadata}
end

@discord_enum BaseTheme UInt8 begin
    UNSET = 0
    DARK = 1
    LIGHT = 2
    DARKER = 3
    MIDNIGHT = 4
end

@discord_object struct SharedClientTheme
    colors::Vector{String}
    gradient_angle::Int
    base_mix::Int
    base_theme::OptionalNullable{BaseTheme}
end

"""
    SnapshotMessage

The minimal subset of [`Message`](@ref) fields Discord includes in a
[`MessageSnapshot`](@ref): `type`, `content`, `embeds`, `attachments`,
`timestamp`, `edited_timestamp`, `flags`, `mentions`, `mention_roles`,
`stickers`, `sticker_items`, and `components` — notably no `id` or `author`.
"""
@discord_object struct SnapshotMessage
    type::MessageType
    content::String
    embeds::Vector{Embed}
    attachments::Vector{Attachment}
    timestamp::DateTime
    edited_timestamp::Nullable{DateTime}
    flags::Optional{MessageFlags}
    mentions::Vector{User}
    mention_roles::Vector{Snowflake}
    stickers::Optional{Vector{Sticker}}
    sticker_items::Optional{Vector{StickerItem}}
    components::Optional{Vector{Component}}
end

"""
    MessageSnapshot

A point-in-time copy of a forwarded message.
"""
@discord_object struct MessageSnapshot
    message::SnapshotMessage
end

"""
    Message

A message sent in a channel. `content`, `embeds`, `attachments`, `components`
come back empty (and `poll` absent) unless the app has the `MESSAGE_CONTENT`
privileged intent.
"""
@discord_object struct Message
    id::Snowflake
    channel_id::Snowflake
    author::User
    content::String
    timestamp::DateTime
    edited_timestamp::Nullable{DateTime}
    tts::Bool
    mention_everyone::Bool
    mentions::Vector{User}
    mention_roles::Vector{Snowflake}
    mention_channels::Optional{Vector{ChannelMention}}
    attachments::Vector{Attachment}
    embeds::Vector{Embed}
    reactions::Optional{Vector{Reaction}}
    nonce::Optional{Union{Int,String}}
    pinned::Bool
    webhook_id::Optional{Snowflake}
    type::MessageType
    activity::Optional{MessageActivity}
    application::Optional{Application}
    application_id::Optional{Snowflake}
    flags::Optional{MessageFlags}
    message_reference::Optional{MessageReference}
    message_snapshots::Optional{Vector{MessageSnapshot}}
    referenced_message::OptionalNullable{Message}
    interaction_metadata::Optional{MessageInteractionMetadata}
    interaction::Optional{MessageInteraction}
    thread::Optional{DiscordChannel}
    components::Optional{Vector{Component}}
    sticker_items::Optional{Vector{StickerItem}}
    stickers::Optional{Vector{Sticker}}
    position::Optional{Int}
    role_subscription_data::Optional{RoleSubscriptionData}
    resolved::Optional{ResolvedData}
    poll::Optional{Poll}
    call::Optional{MessageCall}
    shared_client_theme::Optional{SharedClientTheme}
end

@discord_object struct MessagePin
    pinned_at::DateTime
    message::Message
end
