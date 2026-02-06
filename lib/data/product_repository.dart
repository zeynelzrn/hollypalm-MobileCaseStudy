import 'package:flutter/foundation.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../models/product.dart';

/// Storefront API: handle ile ürün (product query — productByHandle deprecated ve null dönebiliyor).
const String productByHandleQuery = r'''
  query ProductByHandle($handle: String!) {
    product(handle: $handle) {
      id
      title
      handle
      vendor
      descriptionHtml
      featuredImage {
        url
        altText
        width
        height
      }
      images(first: 15) {
        edges {
          node {
            url
            altText
            width
            height
          }
        }
      }
      priceRange {
        minVariantPrice { amount currencyCode }
        maxVariantPrice { amount currencyCode }
      }
      variants(first: 50) {
        edges {
          node {
            id
            title
            availableForSale
            price { amount currencyCode }
            compareAtPrice { amount currencyCode }
            image { url altText width height }
            selectedOptions { name value }
          }
        }
      }
    }
  }
''';

/// Storefront API: Mağazadaki ürün listesi (handle bulmak için debug).
const String productsListQuery = r'''
  query ProductsList($first: Int!) {
    products(first: $first) {
      edges {
        node {
          id
          handle
          title
        }
      }
    }
  }
''';

/// ID ile ürün (product query).
const String productByIdQuery = r'''
  query Product($id: ID!) {
    product(id: $id) {
      id
      title
      handle
      vendor
      descriptionHtml
      featuredImage {
        url
        altText
        width
        height
      }
      images(first: 15) {
        edges {
          node {
            url
            altText
            width
            height
          }
        }
      }
      priceRange {
        minVariantPrice { amount currencyCode }
        maxVariantPrice { amount currencyCode }
      }
      variants(first: 50) {
        edges {
          node {
            id
            title
            availableForSale
            price { amount currencyCode }
            compareAtPrice { amount currencyCode }
            image { url altText width height }
            selectedOptions { name value }
          }
        }
      }
    }
  }
''';

class ProductRepository {
  ProductRepository(this._client);

  final GraphQLClient _client;

  /// ID ile ürün getir (Shopify GID formatı: gid://shopify/Product/123)
  Future<Product?> getProductById(String id) async {
    final result = await _client.query(QueryOptions(
      document: gql(productByIdQuery),
      variables: {'id': id},
      fetchPolicy: FetchPolicy.networkOnly,
    ));
    _debugPrintResult(result, 'getProductById', variables: {'id': id});
    return _productFromResult(result, key: 'product');
  }

  /// Handle ile ürün getir
  Future<Product?> getProductByHandle(String handle) async {
    final result = await _client.query(QueryOptions(
      document: gql(productByHandleQuery),
      variables: {'handle': handle},
      fetchPolicy: FetchPolicy.networkOnly,
    ));
    _debugPrintResult(result, 'getProductByHandle', variables: {'handle': handle});
    final product = _productFromResult(result, key: 'product');
    if (product == null && !kReleaseMode) {
      debugPrint('Ürün bulunamadı. Mağazadaki ürünler listeleniyor...');
      debugPrintProductHandles();
    }
    return product;
  }

  /// Debug: Mağazada görünen ürünlerin handle listesini konsola yazdırır.
  Future<void> debugPrintProductHandles() async {
    final result = await _client.query(QueryOptions(
      document: gql(productsListQuery),
      variables: {'first': 25},
      fetchPolicy: FetchPolicy.networkOnly,
    ));
    if (result.hasException) {
      debugPrint('Products listesi alınamadı: ${result.exception}');
      return;
    }
    final edges = result.data?['products']?['edges'] as List<dynamic>? ?? [];
    if (edges.isEmpty) {
      debugPrint('Storefront API’de hiç ürün yok. Ürünler “Online Store” (veya ilgili channel) ile yayında mı kontrol edin.');
      return;
    }
    debugPrint('━━━ Mağazada görünen ürünler (handle) ━━━');
    for (final e in edges) {
      final node = (e as Map<String, dynamic>)['node'] as Map<String, dynamic>?;
      if (node != null) {
        debugPrint('  handle: ${node['handle']}  title: ${node['title']}');
      }
    }
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  void _debugPrintResult(
    QueryResult result,
    String method, {
    Map<String, dynamic>? variables,
  }) {
    if (kReleaseMode) return;
    debugPrint('━━━ GraphQL $method ━━━');
    if (variables != null) {
      debugPrint('Variables: $variables');
    }
    if (result.exception != null) {
      debugPrint('Exception: ${result.exception}');
      debugPrint('Exception link: ${result.exception?.linkException}');
      debugPrint('Exception graphqlErrors: ${result.exception?.graphqlErrors}');
    }
    debugPrint('Raw data: ${result.data}');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━');
  }

  Product? _productFromResult(QueryResult result, {required String key}) {
    if (result.hasException) return null;
    final data = result.data;
    if (data == null || data[key] == null) return null;
    return Product.fromJson(
      data[key] as Map<String, dynamic>,
    );
  }
}
