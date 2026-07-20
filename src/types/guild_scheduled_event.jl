# https://docs.discord.com/developers/resources/guild-scheduled-event

export GuildScheduledEvent, GuildScheduledEventUser, GuildScheduledEventEntityMetadata,
    RecurrenceRule, RecurrenceRuleNWeekday,
    GuildScheduledEventPrivacyLevel, GuildScheduledEventPrivacyLevels,
    GuildScheduledEventStatus, GuildScheduledEventStatuss,
    GuildScheduledEventEntityType, GuildScheduledEventEntityTypes,
    RecurrenceRuleFrequency, RecurrenceRuleFrequencys,
    RecurrenceRuleWeekday, RecurrenceRuleWeekdays,
    RecurrenceRuleMonth, RecurrenceRuleMonths

@discord_enum GuildScheduledEventPrivacyLevel UInt8 begin
    GUILD_ONLY = 2
end

@discord_enum GuildScheduledEventStatus UInt8 begin
    SCHEDULED = 1
    ACTIVE = 2
    COMPLETED = 3
    CANCELED = 4
end

@discord_enum GuildScheduledEventEntityType UInt8 begin
    STAGE_INSTANCE = 1
    VOICE = 2
    EXTERNAL = 3
end

@discord_enum RecurrenceRuleFrequency UInt8 begin
    YEARLY = 0
    MONTHLY = 1
    WEEKLY = 2
    DAILY = 3
end

@discord_enum RecurrenceRuleWeekday UInt8 begin
    MONDAY = 0
    TUESDAY = 1
    WEDNESDAY = 2
    THURSDAY = 3
    FRIDAY = 4
    SATURDAY = 5
    SUNDAY = 6
end

@discord_enum RecurrenceRuleMonth UInt8 begin
    JANUARY = 1
    FEBRUARY = 2
    MARCH = 3
    APRIL = 4
    MAY = 5
    JUNE = 6
    JULY = 7
    AUGUST = 8
    SEPTEMBER = 9
    OCTOBER = 10
    NOVEMBER = 11
    DECEMBER = 12
end

@discord_object struct GuildScheduledEventEntityMetadata
    location::Optional{String}
end

"""
    RecurrenceRuleNWeekday

A weekday within a specific week (`n` = 1-5) for a recurrence rule.
"""
@discord_object struct RecurrenceRuleNWeekday
    n::Int
    day::RecurrenceRuleWeekday
end

"""
    RecurrenceRule

How often a scheduled event recurs, a stricter subset of iCalendar RFC 5545.
The `end`, `by_year_day`, and `count` fields cannot be set by clients.
"""
@discord_object struct RecurrenceRule
    start::DateTime
    var"end"::Nullable{DateTime}
    frequency::RecurrenceRuleFrequency
    interval::Int
    by_weekday::Nullable{Vector{RecurrenceRuleWeekday}}
    by_n_weekday::Nullable{Vector{RecurrenceRuleNWeekday}}
    by_month::Nullable{Vector{RecurrenceRuleMonth}}
    by_month_day::Nullable{Vector{Int}}
    by_year_day::Nullable{Vector{Int}}
    count::Nullable{Int}
end

@discord_object struct GuildScheduledEvent
    id::Snowflake
    guild_id::Snowflake
    channel_id::Nullable{Snowflake}
    creator_id::OptionalNullable{Snowflake}
    name::String
    description::OptionalNullable{String}
    scheduled_start_time::DateTime
    scheduled_end_time::Nullable{DateTime}
    privacy_level::GuildScheduledEventPrivacyLevel
    status::GuildScheduledEventStatus
    entity_type::GuildScheduledEventEntityType
    entity_id::Nullable{Snowflake}
    entity_metadata::Nullable{GuildScheduledEventEntityMetadata}
    creator::Optional{User}
    user_count::Optional{Int}
    image::OptionalNullable{String}
    recurrence_rule::Nullable{RecurrenceRule}
end

"""
    GuildScheduledEventUser

A user subscribed to a scheduled event, with their guild member when requested.
"""
@discord_object struct GuildScheduledEventUser
    guild_scheduled_event_id::Snowflake
    user::User
    member::Optional{GuildMember}
end
