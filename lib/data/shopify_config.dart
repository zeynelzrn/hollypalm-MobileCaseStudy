/// Shopify Storefront API endpoint ve store bilgisi.
class ShopifyConfig {
  ShopifyConfig({
    required this.storefrontAccessToken,
    required this.storeDomain,
  });

  /// Örn: hollypalm-test.myshopify.com (URL'den scheme ve path olmadan)
  final String storeDomain;

  /// Storefront API access token
  final String storefrontAccessToken;

  String get graphqlEndpoint =>
      'https://$storeDomain/api/2024-01/graphql.json';
}
