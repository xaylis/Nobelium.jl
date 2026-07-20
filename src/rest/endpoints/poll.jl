# https://docs.discord.com/developers/resources/poll

export get_answer_voters, end_poll

"""
    get_answer_voters(api, channel_id, message_id, answer_id; after, limit)

Users who voted for a poll answer. The result has a single `users` key.
[Docs](https://docs.discord.com/developers/resources/poll#get-answer-voters)
"""
get_answer_voters(api::API, channel::SnowflakeLike, message::SnowflakeLike, answer::Integer; kwargs...) =
    request(api, Route(:GET, "/channels/{channel_id}/polls/{message_id}/answers/{answer_id}"),
            snowflake(channel), snowflake(message), answer; query=kwargs, into=Any)

"""
    end_poll(api, channel_id, message_id) -> Message

Immediately end a poll instead of waiting for its expiry.
[Docs](https://docs.discord.com/developers/resources/poll#end-poll)
"""
end_poll(api::API, channel::SnowflakeLike, message::SnowflakeLike) =
    request(api, Route(:POST, "/channels/{channel_id}/polls/{message_id}/expire"),
            snowflake(channel), snowflake(message); into=Message)
