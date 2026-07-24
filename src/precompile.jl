# Compile the hot paths at precompile time so a bot's first real event doesn't
# pay seconds of JIT latency at runtime — Discord only allows 3 seconds to
# acknowledge an interaction, and cold-parsing one costs more than that.
#
# Everything here runs against canned payloads and a stub transport; nothing
# touches the network.

using PrecompileTools: @setup_workload, @compile_workload

@setup_workload begin
    interaction_create = """{
        "id": "1", "application_id": "2", "type": 2, "token": "t", "version": 1,
        "app_permissions": "0", "entitlements": [], "authorizing_integration_owners": {},
        "attachment_size_limit": 8388608, "guild_id": "3", "channel_id": "4", "locale": "en-US",
        "member": {"roles": ["6"], "joined_at": "2020-01-01T00:00:00.000000+00:00",
                   "deaf": false, "mute": false, "flags": 0, "nick": null, "premium_since": null,
                   "permissions": "2147483647", "pending": false,
                   "user": {"id": "5", "username": "u", "discriminator": "0", "avatar": null}},
        "data": {"id": "7", "name": "cmd", "type": 1,
            "options": [{"name": "user", "type": 6, "value": "5"},
                        {"name": "count", "type": 4, "value": 3},
                        {"name": "reason", "type": 3, "value": "why"}],
            "resolved": {
                "users": {"5": {"id": "5", "username": "u", "discriminator": "0", "avatar": null}},
                "members": {"5": {"roles": [], "joined_at": "2020-01-01T00:00:00.000000+00:00", "flags": 0}}}}
    }"""
    component_interaction = """{
        "id": "1", "application_id": "2", "type": 3, "token": "t", "version": 1,
        "app_permissions": "0", "entitlements": [], "authorizing_integration_owners": {},
        "attachment_size_limit": 8388608, "guild_id": "3", "channel_id": "4",
        "user": {"id": "5", "username": "u", "discriminator": "0", "avatar": null},
        "data": {"custom_id": "btn", "component_type": 2}
    }"""
    message_create = """{
        "id": "200", "channel_id": "300", "guild_id": "400",
        "author": {"id": "5", "username": "author", "discriminator": "0", "avatar": null},
        "content": "hello world", "timestamp": "2020-01-01T00:00:00.000000+00:00",
        "edited_timestamp": null, "tts": false, "mention_everyone": false,
        "mentions": [], "mention_roles": [], "attachments": [],
        "embeds": [{"title": "t", "description": "d", "color": 5793266,
                    "fields": [{"name": "n", "value": "v", "inline": true}]}],
        "pinned": false, "type": 0
    }"""
    ready = """{
        "v": 10, "user": {"id": "1", "username": "bot", "discriminator": "0", "avatar": null, "bot": true},
        "guilds": [{"id": "3", "unavailable": true}], "session_id": "s",
        "resume_gateway_url": "wss://example.invalid", "shard": [0, 1],
        "application": {"id": "2", "flags": 0}
    }"""
    stub = API("precompile";
               http=(m, u, h, b) -> HTTP.Response(204, Pair{String,String}[]; body=UInt8[]))

    @compile_workload begin
        # Gateway parsing — the biggest first-use cost a live bot hits.
        i = StructTypes.construct(InteractionCreate, JSON3.read(interaction_create)).interaction
        StructTypes.construct(InteractionCreate, JSON3.read(component_interaction))
        m = StructTypes.construct(MessageCreate, JSON3.read(message_create)).message
        StructTypes.construct(Ready, JSON3.read(ready))

        # Reading command options.
        for o in options(i)
            option(i, o.name)
        end

        # Command builders and their wire form.
        cmd = slash_command("cmd", "d";
            options=[command_option(:user, "user", "d"; required=true),
                     command_option(:integer, "count", "d"),
                     command_option(:string, "reason", "d")])
        JSON3.write([cmd, user_command("U"), message_command("M")])

        # Acknowledgement paths, against the stub transport.
        respond(stub, i; content="w")
        respond(stub, i; content="w", ephemeral=true)
        defer(stub, i)
        defer(stub, i; ephemeral=true)
        defer_update(stub, i)
        edit_original_interaction_response(stub, 1, "t"; content="w")
        create_followup_message(stub, 1, "t"; content="w")

        # Common REST sends.
        create_message(stub, 1; content="w")
        create_message(stub, 1;
            embeds=[Embed(title="t", color=0x5865f2,
                          fields=[EmbedField(name="n", value="v", inline=true)])],
            components=[action_row(button("b"; custom_id="btn"))])
        reply(stub, m; content="w")
    end
end
