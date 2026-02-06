/// Sepet satırı (optimistic veya API'den gelen).
class CartLine {
  const CartLine({
    required this.variantId,
    required this.quantity,
    this.title,
    this.imageUrl,
    this.priceAmount,
    this.priceCurrencyCode,
    this.id,
  });

  final String variantId;
  final int quantity;
  final String? title;
  final String? imageUrl;
  final String? priceAmount;
  final String? priceCurrencyCode;
  /// Shopify'dan dönen line id (optimistic eklemede null).
  final String? id;

  CartLine copyWith({
    String? id,
    int? quantity,
  }) {
    return CartLine(
      variantId: variantId,
      quantity: quantity ?? this.quantity,
      title: title,
      imageUrl: imageUrl,
      priceAmount: priceAmount,
      priceCurrencyCode: priceCurrencyCode,
      id: id ?? this.id,
    );
  }
}

/// Sepet state (Optimistic UI: eklenen satırlar hemen listede).
class Cart {
  const Cart({
    this.id,
    this.lines = const [],
  });

  final String? id;
  final List<CartLine> lines;

  int get totalQuantity =>
      lines.fold(0, (sum, line) => sum + line.quantity);

  /// Belirtilen variantId için sepetteki toplam adet.
  int quantityForVariant(String variantId) {
    return lines
        .where((l) => l.variantId == variantId)
        .fold(0, (sum, l) => sum + l.quantity);
  }

  /// variantId'ye ait ilk satırı bulur (aynı variant birden fazla satırda olabilir).
  CartLine? lineForVariant(String variantId) {
    try {
      return lines.firstWhere((l) => l.variantId == variantId);
    } catch (_) {
      return null;
    }
  }

  Cart copyWith({
    String? id,
    List<CartLine>? lines,
  }) {
    return Cart(
      id: id ?? this.id,
      lines: lines ?? this.lines,
    );
  }
}
