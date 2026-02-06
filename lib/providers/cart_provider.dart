import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/cart_repository.dart';
import '../models/cart.dart';
import 'shopify_providers.dart';

/// Sepet Notifier: Optimistic UI — "Sepete Ekle" tıklanınca satır hemen
/// sepete eklenir, arka planda API çağrılır; hata olursa geri alınır.
class CartNotifier extends Notifier<Cart> {
  @override
  Cart build() => const Cart();

  CartRepository get _repo => ref.read(cartRepositoryProvider);

  /// Optimistic UI: Önce state'e satır eklenir, sonra API çağrılır.
  /// Başarısız olursa önceki state'e dönülür (rollback). Başarılı ise true, hata ise false döner.
  Future<bool> addToCart({
    required String variantId,
    int quantity = 1,
    String? title,
    String? imageUrl,
    String? priceAmount,
    String? priceCurrencyCode,
  }) async {
    final previousCart = state;

    final optimisticLine = CartLine(
      variantId: variantId,
      quantity: quantity,
      title: title,
      imageUrl: imageUrl,
      priceAmount: priceAmount,
      priceCurrencyCode: priceCurrencyCode,
      id: null,
    );

    if (state.id == null || state.id!.isEmpty) {
      state = state.copyWith(
        lines: [...state.lines, optimisticLine],
      );
      try {
        final cart = await _repo.createCart(variantId, quantity);
        if (cart != null) {
          state = cart;
          return true;
        }
      } catch (_) {}
      state = previousCart;
      return false;
    }

    state = state.copyWith(
      lines: [...state.lines, optimisticLine],
    );
    try {
      final cart = await _repo.addLines(state.id!, variantId, quantity);
      if (cart != null) {
        state = cart;
        return true;
      }
    } catch (_) {}
    state = previousCart;
    return false;
  }

  /// Optimistic: Bir adet azalt veya satır 1 ise tamamen kaldır. Hata olursa rollback.
  Future<bool> removeFromCart(String variantId) async {
    final previousCart = state;
    final line = state.lineForVariant(variantId);
    if (line == null) return true;

    if (line.id == null) {
      state = state.copyWith(
        lines: state.lines.where((l) => l.variantId != variantId).toList(),
      );
      return true;
    }

    if (line.quantity > 1) {
      final newQuantity = line.quantity - 1;
      state = state.copyWith(
        lines: state.lines.map((l) {
          if (l.variantId == variantId && l.id == line.id) {
            return l.copyWith(quantity: newQuantity);
          }
          return l;
        }).toList(),
      );
      try {
        final cart = await _repo.updateLineQuantity(state.id!, line.id!, newQuantity);
        if (cart != null) {
          state = cart;
          return true;
        }
      } catch (_) {}
      state = previousCart;
      return false;
    }

    state = state.copyWith(
      lines: state.lines
          .where((l) => !(l.variantId == variantId && l.id == line.id))
          .toList(),
    );
    try {
      final cart = await _repo.removeLines(state.id!, [line.id!]);
      if (cart != null) {
        state = cart;
        return true;
      }
    } catch (_) {}
    state = previousCart;
    return false;
  }

  /// Miktar artır (optimistic + API).
  Future<bool> increaseQuantity(String variantId) async {
    final line = state.lineForVariant(variantId);
    if (line == null) return addToCart(variantId: variantId).then((_) => true);
    final newQuantity = line.quantity + 1;
    final previousCart = state;
    state = state.copyWith(
      lines: state.lines.map((l) {
        if (l.variantId == variantId && l.id == line.id) {
          return l.copyWith(quantity: newQuantity);
        }
        return l;
      }).toList(),
    );
    if (line.id == null) {
      state = previousCart;
      return addToCart(
        variantId: variantId,
        quantity: newQuantity,
        title: line.title,
        imageUrl: line.imageUrl,
        priceAmount: line.priceAmount,
        priceCurrencyCode: line.priceCurrencyCode,
      );
    }
    try {
      final cart = await _repo.updateLineQuantity(state.id!, line.id!, newQuantity);
      if (cart != null) {
        state = cart;
        return true;
      }
    } catch (_) {}
    state = previousCart;
    return false;
  }

  void clearCart() {
    state = const Cart();
  }
}

final cartProvider = NotifierProvider<CartNotifier, Cart>(CartNotifier.new);
