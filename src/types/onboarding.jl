# https://docs.discord.com/developers/resources/guild#guild-onboarding-object

export GuildOnboarding, OnboardingPrompt, OnboardingPromptOption, OnboardingMode,
    OnboardingModes, PromptType, PromptTypes

@discord_enum OnboardingMode UInt8 begin
    ONBOARDING_DEFAULT = 0
    ONBOARDING_ADVANCED = 1
end

@discord_enum PromptType UInt8 begin
    MULTIPLE_CHOICE = 0
    DROPDOWN = 1
end

"""
    OnboardingPromptOption

An option in an onboarding prompt. When creating or updating one, set
`emoji_id`/`emoji_name`/`emoji_animated` rather than `emoji`.
"""
@discord_object struct OnboardingPromptOption
    id::Snowflake
    channel_ids::Vector{Snowflake}
    role_ids::Vector{Snowflake}
    emoji::Optional{Emoji}
    emoji_id::Optional{Snowflake}
    emoji_name::Optional{String}
    emoji_animated::Optional{Bool}
    title::String
    description::Nullable{String}
end

@discord_object struct OnboardingPrompt
    id::Snowflake
    type::PromptType
    options::Vector{OnboardingPromptOption}
    title::String
    single_select::Bool
    required::Bool
    in_onboarding::Bool
end

"""
    GuildOnboarding

A guild's new-member onboarding configuration.
"""
@discord_object struct GuildOnboarding
    guild_id::Snowflake
    prompts::Vector{OnboardingPrompt}
    default_channel_ids::Vector{Snowflake}
    enabled::Bool
    mode::OnboardingMode
end
