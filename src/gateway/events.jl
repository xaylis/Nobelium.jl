# https://docs.discord.com/developers/events/gateway-events

export Ready, UnavailableGuild, Resumed, Reconnect, InvalidSession,
    ApplicationCommandPermissionsUpdate, AutoModerationRuleCreate, AutoModerationRuleUpdate,
    AutoModerationRuleDelete, AutoModerationActionExecution, ChannelCreate, ChannelUpdate,
    ChannelDelete, ChannelPinsUpdate, ThreadCreate, ThreadUpdate, ThreadDelete,
    ThreadListSync, ThreadMemberUpdate, ThreadMembersUpdate, EntitlementCreate,
    EntitlementUpdate, EntitlementDelete, GuildCreate, GuildUpdate, GuildDelete,
    GuildAuditLogEntryCreate, GuildBanAdd, GuildBanRemove, GuildEmojisUpdate,
    GuildStickersUpdate, GuildIntegrationsUpdate, GuildMemberAdd, GuildMemberRemove,
    GuildMemberUpdate, GuildMembersChunk, GuildRoleCreate, GuildRoleUpdate, GuildRoleDelete,
    GuildScheduledEventCreate, GuildScheduledEventUpdate, GuildScheduledEventDelete,
    GuildScheduledEventUserAdd, GuildScheduledEventUserRemove, GuildSoundboardSoundCreate,
    GuildSoundboardSoundUpdate, GuildSoundboardSoundDelete, GuildSoundboardSoundsUpdate,
    SoundboardSounds, IntegrationCreate, IntegrationUpdate, IntegrationDelete,
    InteractionCreate, InviteCreate, InviteDelete, MessageCreate, MessageUpdate,
    MessageDelete, MessageDeleteBulk, MessageReactionAdd, MessageReactionRemove,
    MessageReactionRemoveAll, MessageReactionRemoveEmoji, PresenceUpdate,
    StageInstanceCreate, StageInstanceUpdate, StageInstanceDelete, SubscriptionCreate,
    SubscriptionUpdate, SubscriptionDelete, TypingStart, UserUpdate,
    VoiceChannelEffectSend, AnimationType, AnimationTypes, VoiceChannelStartTimeUpdate,
    VoiceChannelStatusUpdate, VoiceStateUpdate, VoiceServerUpdate, WebhooksUpdate,
    MessagePollVoteAdd, MessagePollVoteRemove, EVENT_TYPES

# --- Connection lifecycle --------------------------------------------------

@discord_object struct UnavailableGuild
    id::Snowflake
    unavailable::Optional{Bool}
end

"""
    Ready

Dispatched once the initial handshake completes; carries the state a client
needs to start interacting with the rest of the platform.
"""
@discord_object struct Ready <: AbstractEvent
    v::Int
    user::User
    guilds::Vector{UnavailableGuild}
    session_id::String
    resume_gateway_url::String
    shard::Optional{Vector{Int}}
    application::Application
end

struct Resumed <: AbstractEvent end
struct Reconnect <: AbstractEvent end

"""
    InvalidSession

Whether the session `resumable` — if so, resuming may still work; otherwise a
fresh identify is required. The payload is a bare boolean, not an object.
"""
struct InvalidSession <: AbstractEvent
    resumable::Bool
end
StructTypes.StructType(::Type{InvalidSession}) = StructTypes.CustomStruct()
StructTypes.lowertype(::Type{InvalidSession}) = Bool
StructTypes.lower(x::InvalidSession) = x.resumable
StructTypes.construct(::Type{InvalidSession}, b::Bool; kw...) = InvalidSession(b)

# --- Application commands ---------------------------------------------------

@gateway_event struct ApplicationCommandPermissionsUpdate
    permissions::GuildApplicationCommandPermissions
end

# --- Auto Moderation ---------------------------------------------------------

@gateway_event struct AutoModerationRuleCreate
    rule::AutoModerationRule
end

@gateway_event struct AutoModerationRuleUpdate
    rule::AutoModerationRule
end

@gateway_event struct AutoModerationRuleDelete
    rule::AutoModerationRule
end

@discord_object struct AutoModerationActionExecution <: AbstractEvent
    guild_id::Snowflake
    action::AutoModerationAction
    rule_id::Snowflake
    rule_trigger_type::AutoModerationTriggerType
    user_id::Snowflake
    channel_id::Optional{Snowflake}
    message_id::Optional{Snowflake}
    alert_system_message_id::Optional{Snowflake}
    content::String
    matched_keyword::Nullable{String}
    matched_content::Nullable{String}
end

# --- Channels ----------------------------------------------------------------

@gateway_event struct ChannelCreate
    channel::DiscordChannel
end

@gateway_event struct ChannelUpdate
    channel::DiscordChannel
end

@gateway_event struct ChannelDelete
    channel::DiscordChannel
end

@discord_object struct ChannelPinsUpdate <: AbstractEvent
    guild_id::Optional{Snowflake}
    channel_id::Snowflake
    last_pin_timestamp::OptionalNullable{DateTime}
end

# --- Threads -------------------------------------------------------------

@gateway_event struct ThreadCreate
    channel::DiscordChannel
    newly_created::Optional{Bool}
end

@gateway_event struct ThreadUpdate
    channel::DiscordChannel
end

@discord_object struct ThreadDelete <: AbstractEvent
    id::Snowflake
    guild_id::Snowflake
    parent_id::Snowflake
    type::ChannelType
end

@discord_object struct ThreadListSync <: AbstractEvent
    guild_id::Snowflake
    channel_ids::Optional{Vector{Snowflake}}
    threads::Vector{DiscordChannel}
    members::Vector{ThreadMember}
end

@gateway_event struct ThreadMemberUpdate
    member::ThreadMember
    guild_id::Snowflake
end

@discord_object struct ThreadMembersUpdate <: AbstractEvent
    id::Snowflake
    guild_id::Snowflake
    member_count::Int
    added_members::Optional{Vector{ThreadMember}}
    removed_member_ids::Optional{Vector{Snowflake}}
end

# --- Entitlements --------------------------------------------------------

@gateway_event struct EntitlementCreate
    entitlement::Entitlement
end

@gateway_event struct EntitlementUpdate
    entitlement::Entitlement
end

@gateway_event struct EntitlementDelete
    entitlement::Entitlement
end

# --- Guilds ----------------------------------------------------------------

@gateway_event struct GuildCreate
    guild::Guild
    joined_at::Optional{DateTime}
    large::Optional{Bool}
    unavailable::Optional{Bool}
    member_count::Optional{Int}
    voice_states::Optional{Vector{VoiceState}}
    members::Optional{Vector{GuildMember}}
    channels::Optional{Vector{DiscordChannel}}
    threads::Optional{Vector{DiscordChannel}}
    presences::Optional{Vector{Any}}
    stage_instances::Optional{Vector{StageInstance}}
    guild_scheduled_events::Optional{Vector{GuildScheduledEvent}}
    soundboard_sounds::Optional{Vector{SoundboardSound}}
end

@gateway_event struct GuildUpdate
    guild::Guild
end

@discord_object struct GuildDelete <: AbstractEvent
    id::Snowflake
    unavailable::Optional{Bool}
end

@gateway_event struct GuildAuditLogEntryCreate
    entry::AuditLogEntry
    guild_id::Snowflake
end

@discord_object struct GuildBanAdd <: AbstractEvent
    guild_id::Snowflake
    user::User
end

@discord_object struct GuildBanRemove <: AbstractEvent
    guild_id::Snowflake
    user::User
end

@discord_object struct GuildEmojisUpdate <: AbstractEvent
    guild_id::Snowflake
    emojis::Vector{Emoji}
end

@discord_object struct GuildStickersUpdate <: AbstractEvent
    guild_id::Snowflake
    stickers::Vector{Sticker}
end

@discord_object struct GuildIntegrationsUpdate <: AbstractEvent
    guild_id::Snowflake
end

@gateway_event struct GuildMemberAdd
    member::GuildMember
    guild_id::Snowflake
end

@discord_object struct GuildMemberRemove <: AbstractEvent
    guild_id::Snowflake
    user::User
end

"""
    GuildMemberUpdate

Sent when a guild member (or the user object inside it) is updated. Unlike
`GuildMemberAdd`, the payload only carries the fields that changed
alongside the member's identity, not a full `GuildMember`.
"""
@discord_object struct GuildMemberUpdate <: AbstractEvent
    guild_id::Snowflake
    roles::Vector{Snowflake}
    user::User
    nick::OptionalNullable{String}
    avatar::Nullable{String}
    banner::Nullable{String}
    joined_at::Nullable{DateTime}
    premium_since::OptionalNullable{DateTime}
    deaf::Optional{Bool}
    mute::Optional{Bool}
    pending::Optional{Bool}
    communication_disabled_until::OptionalNullable{DateTime}
    avatar_decoration_data::OptionalNullable{AvatarDecorationData}
    collectibles::OptionalNullable{Any}
end

@discord_object struct GuildMembersChunk <: AbstractEvent
    guild_id::Snowflake
    members::Vector{GuildMember}
    chunk_index::Int
    chunk_count::Int
    not_found::Optional{Vector{Any}}
    presences::Optional{Vector{Any}}
    nonce::Optional{String}
end

@discord_object struct GuildRoleCreate <: AbstractEvent
    guild_id::Snowflake
    role::Role
end

@discord_object struct GuildRoleUpdate <: AbstractEvent
    guild_id::Snowflake
    role::Role
end

@discord_object struct GuildRoleDelete <: AbstractEvent
    guild_id::Snowflake
    role_id::Snowflake
end

@gateway_event struct GuildScheduledEventCreate
    scheduled_event::GuildScheduledEvent
end

@gateway_event struct GuildScheduledEventUpdate
    scheduled_event::GuildScheduledEvent
end

@gateway_event struct GuildScheduledEventDelete
    scheduled_event::GuildScheduledEvent
end

@discord_object struct GuildScheduledEventUserAdd <: AbstractEvent
    guild_scheduled_event_id::Snowflake
    user_id::Snowflake
    guild_id::Snowflake
end

@discord_object struct GuildScheduledEventUserRemove <: AbstractEvent
    guild_scheduled_event_id::Snowflake
    user_id::Snowflake
    guild_id::Snowflake
end

@gateway_event struct GuildSoundboardSoundCreate
    sound::SoundboardSound
end

@gateway_event struct GuildSoundboardSoundUpdate
    sound::SoundboardSound
end

@discord_object struct GuildSoundboardSoundDelete <: AbstractEvent
    sound_id::Snowflake
    guild_id::Snowflake
end

@discord_object struct GuildSoundboardSoundsUpdate <: AbstractEvent
    soundboard_sounds::Vector{SoundboardSound}
    guild_id::Snowflake
end

@discord_object struct SoundboardSounds <: AbstractEvent
    soundboard_sounds::Vector{SoundboardSound}
    guild_id::Snowflake
end

# --- Integrations ----------------------------------------------------------

@gateway_event struct IntegrationCreate
    integration::Integration
    guild_id::Snowflake
end

@gateway_event struct IntegrationUpdate
    integration::Integration
    guild_id::Snowflake
end

@discord_object struct IntegrationDelete <: AbstractEvent
    id::Snowflake
    guild_id::Snowflake
    application_id::Optional{Snowflake}
end

# --- Interactions ------------------------------------------------------------

@gateway_event struct InteractionCreate
    interaction::Interaction
end

# --- Invites -----------------------------------------------------------------

@discord_object struct InviteCreate <: AbstractEvent
    channel_id::Snowflake
    code::String
    created_at::DateTime
    guild_id::Optional{Snowflake}
    inviter::Optional{User}
    max_age::Int
    max_uses::Int
    target_type::Optional{Int}
    target_user::Optional{User}
    target_application::Optional{Application}
    temporary::Bool
    uses::Int
    expires_at::Nullable{DateTime}
    role_ids::Optional{Vector{Snowflake}}
end

@discord_object struct InviteDelete <: AbstractEvent
    channel_id::Snowflake
    guild_id::Optional{Snowflake}
    code::String
end

# --- Messages ------------------------------------------------------------

@gateway_event struct MessageCreate
    message::Message
    guild_id::Optional{Snowflake}
    member::Optional{GuildMember}
end

@gateway_event struct MessageUpdate
    message::Message
    guild_id::Optional{Snowflake}
    member::Optional{GuildMember}
end

@discord_object struct MessageDelete <: AbstractEvent
    id::Snowflake
    channel_id::Snowflake
    guild_id::Optional{Snowflake}
end

@discord_object struct MessageDeleteBulk <: AbstractEvent
    ids::Vector{Snowflake}
    channel_id::Snowflake
    guild_id::Optional{Snowflake}
end

@discord_object struct MessageReactionAdd <: AbstractEvent
    user_id::Snowflake
    channel_id::Snowflake
    message_id::Snowflake
    guild_id::Optional{Snowflake}
    member::Optional{GuildMember}
    emoji::Emoji
    message_author_id::Optional{Snowflake}
    burst::Bool
    burst_colors::Optional{Vector{String}}
    type::Int
end

@discord_object struct MessageReactionRemove <: AbstractEvent
    user_id::Snowflake
    channel_id::Snowflake
    message_id::Snowflake
    guild_id::Optional{Snowflake}
    emoji::Emoji
    burst::Bool
    type::Int
end

@discord_object struct MessageReactionRemoveAll <: AbstractEvent
    channel_id::Snowflake
    message_id::Snowflake
    guild_id::Optional{Snowflake}
end

@discord_object struct MessageReactionRemoveEmoji <: AbstractEvent
    channel_id::Snowflake
    guild_id::Optional{Snowflake}
    message_id::Snowflake
    emoji::Emoji
end

# --- Presence ----------------------------------------------------------------

"""
    PresenceUpdate

A user's current state on a guild. `user` is a partial user object — only
`id` is guaranteed present — so it is left untyped.
"""
@discord_object struct PresenceUpdate <: AbstractEvent
    user::Any
    guild_id::Snowflake
    status::String
    activities::Vector{Activity}
    client_status::ClientStatus
end

# --- Stage instances -----------------------------------------------------

@gateway_event struct StageInstanceCreate
    stage_instance::StageInstance
end

@gateway_event struct StageInstanceUpdate
    stage_instance::StageInstance
end

@gateway_event struct StageInstanceDelete
    stage_instance::StageInstance
end

# --- Subscriptions -------------------------------------------------------

@gateway_event struct SubscriptionCreate
    subscription::Subscription
end

@gateway_event struct SubscriptionUpdate
    subscription::Subscription
end

@gateway_event struct SubscriptionDelete
    subscription::Subscription
end

# --- Typing / user ---------------------------------------------------------

@discord_object struct TypingStart <: AbstractEvent
    channel_id::Snowflake
    guild_id::Optional{Snowflake}
    user_id::Snowflake
    timestamp::Int
    member::Optional{GuildMember}
end

@gateway_event struct UserUpdate
    user::User
end

# --- Voice -----------------------------------------------------------------

@discord_enum AnimationType UInt8 begin
    PREMIUM = 0
    BASIC = 1
end

@discord_object struct VoiceChannelEffectSend <: AbstractEvent
    channel_id::Snowflake
    guild_id::Snowflake
    user_id::Snowflake
    emoji::OptionalNullable{Emoji}
    animation_type::OptionalNullable{AnimationType}
    animation_id::Optional{Int}
    sound_id::Optional{Snowflake}
    sound_volume::Optional{Float64}
end

@discord_object struct VoiceChannelStatusUpdate <: AbstractEvent
    id::Snowflake
    guild_id::Snowflake
    status::Nullable{String}
end

@discord_object struct VoiceChannelStartTimeUpdate <: AbstractEvent
    id::Snowflake
    guild_id::Snowflake
    voice_start_time::OptionalNullable{Int}
end

@gateway_event struct VoiceStateUpdate
    voice_state::VoiceState
end

@discord_object struct VoiceServerUpdate <: AbstractEvent
    token::String
    guild_id::Snowflake
    endpoint::Nullable{String}
end

# --- Webhooks ----------------------------------------------------------------

@discord_object struct WebhooksUpdate <: AbstractEvent
    guild_id::Snowflake
    channel_id::Snowflake
end

# --- Polls -------------------------------------------------------------------

@discord_object struct MessagePollVoteAdd <: AbstractEvent
    user_id::Snowflake
    channel_id::Snowflake
    message_id::Snowflake
    guild_id::Optional{Snowflake}
    answer_id::Int
end

@discord_object struct MessagePollVoteRemove <: AbstractEvent
    user_id::Snowflake
    channel_id::Snowflake
    message_id::Snowflake
    guild_id::Optional{Snowflake}
    answer_id::Int
end

# --- Dispatch name -> type -----------------------------------------------

const EVENT_TYPES = Dict{String,DataType}(
    "READY" => Ready,
    "RESUMED" => Resumed,
    "RECONNECT" => Reconnect,
    "INVALID_SESSION" => InvalidSession,
    "APPLICATION_COMMAND_PERMISSIONS_UPDATE" => ApplicationCommandPermissionsUpdate,
    "AUTO_MODERATION_RULE_CREATE" => AutoModerationRuleCreate,
    "AUTO_MODERATION_RULE_UPDATE" => AutoModerationRuleUpdate,
    "AUTO_MODERATION_RULE_DELETE" => AutoModerationRuleDelete,
    "AUTO_MODERATION_ACTION_EXECUTION" => AutoModerationActionExecution,
    "CHANNEL_CREATE" => ChannelCreate,
    "CHANNEL_UPDATE" => ChannelUpdate,
    "CHANNEL_DELETE" => ChannelDelete,
    "CHANNEL_PINS_UPDATE" => ChannelPinsUpdate,
    "THREAD_CREATE" => ThreadCreate,
    "THREAD_UPDATE" => ThreadUpdate,
    "THREAD_DELETE" => ThreadDelete,
    "THREAD_LIST_SYNC" => ThreadListSync,
    "THREAD_MEMBER_UPDATE" => ThreadMemberUpdate,
    "THREAD_MEMBERS_UPDATE" => ThreadMembersUpdate,
    "ENTITLEMENT_CREATE" => EntitlementCreate,
    "ENTITLEMENT_UPDATE" => EntitlementUpdate,
    "ENTITLEMENT_DELETE" => EntitlementDelete,
    "GUILD_CREATE" => GuildCreate,
    "GUILD_UPDATE" => GuildUpdate,
    "GUILD_DELETE" => GuildDelete,
    "GUILD_AUDIT_LOG_ENTRY_CREATE" => GuildAuditLogEntryCreate,
    "GUILD_BAN_ADD" => GuildBanAdd,
    "GUILD_BAN_REMOVE" => GuildBanRemove,
    "GUILD_EMOJIS_UPDATE" => GuildEmojisUpdate,
    "GUILD_STICKERS_UPDATE" => GuildStickersUpdate,
    "GUILD_INTEGRATIONS_UPDATE" => GuildIntegrationsUpdate,
    "GUILD_MEMBER_ADD" => GuildMemberAdd,
    "GUILD_MEMBER_REMOVE" => GuildMemberRemove,
    "GUILD_MEMBER_UPDATE" => GuildMemberUpdate,
    "GUILD_MEMBERS_CHUNK" => GuildMembersChunk,
    "GUILD_ROLE_CREATE" => GuildRoleCreate,
    "GUILD_ROLE_UPDATE" => GuildRoleUpdate,
    "GUILD_ROLE_DELETE" => GuildRoleDelete,
    "GUILD_SCHEDULED_EVENT_CREATE" => GuildScheduledEventCreate,
    "GUILD_SCHEDULED_EVENT_UPDATE" => GuildScheduledEventUpdate,
    "GUILD_SCHEDULED_EVENT_DELETE" => GuildScheduledEventDelete,
    "GUILD_SCHEDULED_EVENT_USER_ADD" => GuildScheduledEventUserAdd,
    "GUILD_SCHEDULED_EVENT_USER_REMOVE" => GuildScheduledEventUserRemove,
    "GUILD_SOUNDBOARD_SOUND_CREATE" => GuildSoundboardSoundCreate,
    "GUILD_SOUNDBOARD_SOUND_UPDATE" => GuildSoundboardSoundUpdate,
    "GUILD_SOUNDBOARD_SOUND_DELETE" => GuildSoundboardSoundDelete,
    "GUILD_SOUNDBOARD_SOUNDS_UPDATE" => GuildSoundboardSoundsUpdate,
    "SOUNDBOARD_SOUNDS" => SoundboardSounds,
    "INTEGRATION_CREATE" => IntegrationCreate,
    "INTEGRATION_UPDATE" => IntegrationUpdate,
    "INTEGRATION_DELETE" => IntegrationDelete,
    "INTERACTION_CREATE" => InteractionCreate,
    "INVITE_CREATE" => InviteCreate,
    "INVITE_DELETE" => InviteDelete,
    "MESSAGE_CREATE" => MessageCreate,
    "MESSAGE_UPDATE" => MessageUpdate,
    "MESSAGE_DELETE" => MessageDelete,
    "MESSAGE_DELETE_BULK" => MessageDeleteBulk,
    "MESSAGE_REACTION_ADD" => MessageReactionAdd,
    "MESSAGE_REACTION_REMOVE" => MessageReactionRemove,
    "MESSAGE_REACTION_REMOVE_ALL" => MessageReactionRemoveAll,
    "MESSAGE_REACTION_REMOVE_EMOJI" => MessageReactionRemoveEmoji,
    "PRESENCE_UPDATE" => PresenceUpdate,
    "STAGE_INSTANCE_CREATE" => StageInstanceCreate,
    "STAGE_INSTANCE_UPDATE" => StageInstanceUpdate,
    "STAGE_INSTANCE_DELETE" => StageInstanceDelete,
    "SUBSCRIPTION_CREATE" => SubscriptionCreate,
    "SUBSCRIPTION_UPDATE" => SubscriptionUpdate,
    "SUBSCRIPTION_DELETE" => SubscriptionDelete,
    "TYPING_START" => TypingStart,
    "USER_UPDATE" => UserUpdate,
    "VOICE_CHANNEL_EFFECT_SEND" => VoiceChannelEffectSend,
    "VOICE_CHANNEL_START_TIME_UPDATE" => VoiceChannelStartTimeUpdate,
    "VOICE_CHANNEL_STATUS_UPDATE" => VoiceChannelStatusUpdate,
    "VOICE_STATE_UPDATE" => VoiceStateUpdate,
    "VOICE_SERVER_UPDATE" => VoiceServerUpdate,
    "WEBHOOKS_UPDATE" => WebhooksUpdate,
    "MESSAGE_POLL_VOTE_ADD" => MessagePollVoteAdd,
    "MESSAGE_POLL_VOTE_REMOVE" => MessagePollVoteRemove,
)
