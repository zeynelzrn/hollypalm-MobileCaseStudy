import 'package:graphql_flutter/graphql_flutter.dart';

import '../models/cart.dart';

const String _cartCreateMutation = r'''
  mutation CartCreate($input: CartInput!) {
    cartCreate(input: $input) {
      cart { id
        lines(first: 100) {
          edges {
            node {
              id
              quantity
              merchandise {
                ... on ProductVariant {
                  id
                  title
                  image { url altText }
                  price { amount currencyCode }
                }
              }
            }
          }
        }
      }
      userErrors { code message field }
    }
  }
''';

const String _cartLinesAddMutation = r'''
  mutation CartLinesAdd($cartId: ID!, $lines: [CartLineInput!]!) {
    cartLinesAdd(cartId: $cartId, lines: $lines) {
      cart { id
        lines(first: 100) {
          edges {
            node {
              id
              quantity
              merchandise {
                ... on ProductVariant {
                  id
                  title
                  image { url altText }
                  price { amount currencyCode }
                }
              }
            }
          }
        }
      }
      userErrors { code message field }
    }
  }
''';

const String _cartLinesUpdateMutation = r'''
  mutation CartLinesUpdate($cartId: ID!, $lines: [CartLineUpdateInput!]!) {
    cartLinesUpdate(cartId: $cartId, lines: $lines) {
      cart { id
        lines(first: 100) {
          edges {
            node {
              id
              quantity
              merchandise {
                ... on ProductVariant {
                  id
                  title
                  image { url altText }
                  price { amount currencyCode }
                }
              }
            }
          }
        }
      }
      userErrors { code message field }
    }
  }
''';

const String _cartLinesRemoveMutation = r'''
  mutation CartLinesRemove($cartId: ID!, $lineIds: [ID!]!) {
    cartLinesRemove(cartId: $cartId, lineIds: $lineIds) {
      cart { id
        lines(first: 100) {
          edges {
            node {
              id
              quantity
              merchandise {
                ... on ProductVariant {
                  id
                  title
                  image { url altText }
                  price { amount currencyCode }
                }
              }
            }
          }
        }
      }
      userErrors { code message field }
    }
  }
''';

class CartRepository {
  CartRepository(this._client);

  final GraphQLClient _client;

  /// Yeni sepet oluştur ve ilk satırı ekle.
  Future<Cart?> createCart(String variantId, int quantity) async {
    final result = await _client.mutate(MutationOptions(
      document: gql(_cartCreateMutation),
      variables: {
        'input': {
          'lines': [
            {'merchandiseId': variantId, 'quantity': quantity}
          ],
        },
      },
    ));
    return _cartFromCartCreate(result);
  }

  /// Mevcut sepete satır ekle.
  Future<Cart?> addLines(String cartId, String variantId, int quantity) async {
    final result = await _client.mutate(MutationOptions(
      document: gql(_cartLinesAddMutation),
      variables: {
        'cartId': cartId,
        'lines': [
          {'merchandiseId': variantId, 'quantity': quantity}
        ],
      },
    ));
    return _cartFromCartLinesAdd(result);
  }

  Cart? _cartFromCartCreate(QueryResult result) {
    if (result.hasException || result.data == null) return null;
    final payload = result.data!['cartCreate'];
    final userErrors = payload['userErrors'] as List<dynamic>?;
    if (userErrors != null && userErrors.isNotEmpty) return null;
    final cartJson = payload['cart'];
    if (cartJson == null) return null;
    return _parseCart(cartJson);
  }

  Cart? _cartFromCartLinesAdd(QueryResult result) {
    if (result.hasException || result.data == null) return null;
    final payload = result.data!['cartLinesAdd'];
    final userErrors = payload['userErrors'] as List<dynamic>?;
    if (userErrors != null && userErrors.isNotEmpty) return null;
    final cartJson = payload['cart'];
    if (cartJson == null) return null;
    return _parseCart(cartJson);
  }

  /// Satır miktarını güncelle.
  Future<Cart?> updateLineQuantity(
    String cartId,
    String lineId,
    int quantity,
  ) async {
    final result = await _client.mutate(MutationOptions(
      document: gql(_cartLinesUpdateMutation),
      variables: {
        'cartId': cartId,
        'lines': [
          {'id': lineId, 'quantity': quantity}
        ],
      },
    ));
    if (result.hasException || result.data == null) return null;
    final payload = result.data!['cartLinesUpdate'];
    final userErrors = payload['userErrors'] as List<dynamic>?;
    if (userErrors != null && userErrors.isNotEmpty) return null;
    final cartJson = payload['cart'];
    if (cartJson == null) return null;
    return _parseCart(cartJson);
  }

  /// Satır(lar)ı sepetten kaldır.
  Future<Cart?> removeLines(String cartId, List<String> lineIds) async {
    if (lineIds.isEmpty) return null;
    final result = await _client.mutate(MutationOptions(
      document: gql(_cartLinesRemoveMutation),
      variables: {
        'cartId': cartId,
        'lineIds': lineIds,
      },
    ));
    if (result.hasException || result.data == null) return null;
    final payload = result.data!['cartLinesRemove'];
    final userErrors = payload['userErrors'] as List<dynamic>?;
    if (userErrors != null && userErrors.isNotEmpty) return null;
    final cartJson = payload['cart'];
    if (cartJson == null) return null;
    return _parseCart(cartJson);
  }

  Cart _parseCart(Map<String, dynamic> cartJson) {
    final id = cartJson['id'] as String?;
    final edges = cartJson['lines']?['edges'] as List<dynamic>? ?? [];
    final lines = edges.map((e) {
      final node = (e as Map<String, dynamic>)['node'] as Map<String, dynamic>;
      final merch = node['merchandise'] as Map<String, dynamic>?;
      final image = merch?['image'] as Map<String, dynamic>?;
      final price = merch?['price'] as Map<String, dynamic>?;
      return CartLine(
        id: node['id'] as String?,
        variantId: merch?['id'] as String? ?? '',
        quantity: node['quantity'] as int? ?? 0,
        title: merch?['title'] as String?,
        imageUrl: image?['url'] as String?,
        priceAmount: price?['amount'] as String?,
        priceCurrencyCode: price?['currencyCode'] as String?,
      );
    }).toList();
    return Cart(id: id, lines: lines);
  }
}
