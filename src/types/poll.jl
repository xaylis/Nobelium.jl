# https://docs.discord.com/developers/resources/poll

export Poll, PollCreateRequest, PollMedia, PollAnswer, PollResults, PollAnswerCount,
    PollLayoutType, PollLayoutTypes

@discord_enum PollLayoutType UInt8 begin
    DEFAULT = 1
end

@discord_object struct PollMedia
    text::Optional{String}
    emoji::Optional{Emoji}
end

@discord_object struct PollAnswer
    answer_id::Optional{Int}
    poll_media::PollMedia
end

@discord_object struct PollAnswerCount
    id::Int
    count::Int
    me_voted::Bool
end

@discord_object struct PollResults
    is_finalized::Bool
    answer_counts::Vector{PollAnswerCount}
end

"""
    Poll

A poll attached to a message. `results` is absent until Discord has tallied
votes, which can lag slightly behind the raw vote count.
"""
@discord_object struct Poll
    question::PollMedia
    answers::Vector{PollAnswer}
    expiry::Nullable{DateTime}
    allow_multiselect::Bool
    layout_type::PollLayoutType
    results::Optional{PollResults}
end

"""
    PollCreateRequest

The shape [`create_message`](@ref) and friends expect under a `poll` field,
distinct from [`Poll`](@ref) in that `answers` carry no `answer_id` yet and
`duration` replaces `expiry`.
"""
@discord_object struct PollCreateRequest
    question::PollMedia
    answers::Vector{PollAnswer}
    duration::Optional{Int}
    allow_multiselect::Optional{Bool}
    layout_type::Optional{PollLayoutType}
end
