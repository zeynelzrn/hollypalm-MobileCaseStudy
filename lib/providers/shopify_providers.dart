import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../data/cart_repository.dart';
import '../data/product_repository.dart';
import '../data/shopify_config.dart';
import '../data/shopify_graphql_client.dart';

/// Shopify config provider (Holly Palm test store).
final shopifyConfigProvider = Provider<ShopifyConfig>((ref) {
  return ShopifyConfig(
    storeDomain: 'hollypalm-test.myshopify.com',
    storefrontAccessToken: '00e75e3bfd60f9cbb0d4f357c372d2b0',
  );
});

/// GraphQL client provider.
final graphqlClientProvider = Provider<GraphQLClient>((ref) {
  final config = ref.watch(shopifyConfigProvider);
  return createShopifyGraphQLClient(config);
});

/// Product repository provider.
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final client = ref.watch(graphqlClientProvider);
  return ProductRepository(client);
});

/// Cart repository provider.
final cartRepositoryProvider = Provider<CartRepository>((ref) {
  final client = ref.watch(graphqlClientProvider);
  return CartRepository(client);
});
