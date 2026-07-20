# https://docs.discord.com/developers/resources/sku
# https://docs.discord.com/developers/resources/entitlement
# https://docs.discord.com/developers/resources/subscription

export list_skus, list_entitlements, get_entitlement, consume_entitlement,
    create_test_entitlement, delete_test_entitlement, list_sku_subscriptions,
    get_sku_subscription

"""
    list_skus(api, application_id) -> Vector{SKU}

[Docs](https://docs.discord.com/developers/resources/sku#list-skus)
"""
list_skus(api::API, application::SnowflakeLike) =
    request(api, Route(:GET, "/applications/{application_id}/skus"), snowflake(application);
            into=Vector{SKU})

"""
    list_entitlements(api, application_id; user_id, sku_ids, before, after, limit,
                      guild_id, exclude_ended, exclude_deleted) -> Vector{Entitlement}

[Docs](https://docs.discord.com/developers/resources/entitlement#list-entitlements)
"""
list_entitlements(api::API, application::SnowflakeLike; kwargs...) =
    request(api, Route(:GET, "/applications/{application_id}/entitlements"),
            snowflake(application); query=kwargs, into=Vector{Entitlement})

"""
    get_entitlement(api, application_id, entitlement_id) -> Entitlement

[Docs](https://docs.discord.com/developers/resources/entitlement#get-entitlement)
"""
get_entitlement(api::API, application::SnowflakeLike, entitlement::SnowflakeLike) =
    request(api, Route(:GET, "/applications/{application_id}/entitlements/{entitlement_id}"),
            snowflake(application), snowflake(entitlement); into=Entitlement)

"""
    consume_entitlement(api, application_id, entitlement_id)

Marks a one-time purchase consumable entitlement as consumed.
[Docs](https://docs.discord.com/developers/resources/entitlement#consume-an-entitlement)
"""
consume_entitlement(api::API, application::SnowflakeLike, entitlement::SnowflakeLike) =
    request(api, Route(:POST, "/applications/{application_id}/entitlements/{entitlement_id}/consume"),
            snowflake(application), snowflake(entitlement))

"""
    create_test_entitlement(api, application_id; sku_id, owner_id, owner_type) -> Entitlement

`owner_type` is `1` for a guild subscription, `2` for a user subscription.
[Docs](https://docs.discord.com/developers/resources/entitlement#create-test-entitlement)
"""
create_test_entitlement(api::API, application::SnowflakeLike; kwargs...) =
    request(api, Route(:POST, "/applications/{application_id}/entitlements"),
            snowflake(application); body=kwargs, into=Entitlement)

"""
    delete_test_entitlement(api, application_id, entitlement_id)

[Docs](https://docs.discord.com/developers/resources/entitlement#delete-test-entitlement)
"""
delete_test_entitlement(api::API, application::SnowflakeLike, entitlement::SnowflakeLike) =
    request(api, Route(:DELETE, "/applications/{application_id}/entitlements/{entitlement_id}"),
            snowflake(application), snowflake(entitlement))

"""
    list_sku_subscriptions(api, sku_id; before, after, limit, user_id) -> Vector{Subscription}

`user_id` is required unless the request is authenticated via OAuth2.
[Docs](https://docs.discord.com/developers/resources/subscription#list-sku-subscriptions)
"""
list_sku_subscriptions(api::API, sku::SnowflakeLike; kwargs...) =
    request(api, Route(:GET, "/skus/{sku_id}/subscriptions"), snowflake(sku);
            query=kwargs, into=Vector{Subscription})

"""
    get_sku_subscription(api, sku_id, subscription_id) -> Subscription

[Docs](https://docs.discord.com/developers/resources/subscription#get-sku-subscription)
"""
get_sku_subscription(api::API, sku::SnowflakeLike, subscription::SnowflakeLike) =
    request(api, Route(:GET, "/skus/{sku_id}/subscriptions/{subscription_id}"),
            snowflake(sku), snowflake(subscription); into=Subscription)
