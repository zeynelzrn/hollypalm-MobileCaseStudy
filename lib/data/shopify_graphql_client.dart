import 'package:graphql_flutter/graphql_flutter.dart';

import 'shopify_config.dart';

/// Shopify Storefront API GraphQL client factory.
GraphQLClient createShopifyGraphQLClient(ShopifyConfig config) {
  final httpLink = HttpLink(
    config.graphqlEndpoint,
    defaultHeaders: {
      'X-Shopify-Storefront-Access-Token': config.storefrontAccessToken,
      'Content-Type': 'application/json',
    },
  );
  return GraphQLClient(
    link: httpLink,
    cache: GraphQLCache(store: InMemoryStore()),
  );
}
