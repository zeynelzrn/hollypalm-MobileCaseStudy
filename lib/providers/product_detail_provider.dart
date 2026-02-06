import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';
import '../data/product_repository.dart';
import 'shopify_providers.dart';

/// Ürün detay state: optimistik gösterim + gerçek veri.
class ProductDetailState {
  const ProductDetailState({
    this.product,
    this.isLoading = false,
    this.error,
    this.selectedVariantIndex = 0,
    this.displayImages = const [],
  });

  final Product? product;
  final bool isLoading;
  final String? error;
  final int selectedVariantIndex;
  /// Slider için görsel listesi; selectVariantByIndex çağrıldığında state güncellenir.
  final List<ProductImage> displayImages;

  ProductVariant? get selectedVariant {
    final p = product;
    if (p == null || p.variants.isEmpty) return null;
    final i = selectedVariantIndex.clamp(0, p.variants.length - 1);
    return p.variants[i];
  }

  /// Seçilen varyantın görseli (selectedVariant?.image).
  ProductImage? get selectedVariantImage => selectedVariant?.image;

  /// Slider için görsel listesi (tek kaynak, state’e göre türetilir):
  /// - Varyantın görseli varsa (variant.image) listenin 1. sırasına koy.
  /// 2) Yoksa ürün görselleri seçilen varyant index’ine göre öne alınır (1 görsel = değişmez).
  static List<ProductImage> computeDisplayImages(
    Product? p,
    int selectedVariantIndex,
  ) {
    if (p == null) return [];
    final variantImage = selectedVariantIndex >= 0 &&
            selectedVariantIndex < p.variants.length
        ? p.variants[selectedVariantIndex].image
        : null;
    final productImages = p.images.isNotEmpty
        ? List<ProductImage>.from(p.images)
        : (p.featuredImage != null ? [p.featuredImage!] : <ProductImage>[]);
    if (productImages.isEmpty) return [];
    final mainUrl = productImages.first.url;
    final useVariantAsFirst =
        variantImage != null && variantImage.url != mainUrl;
    if (useVariantAsFirst) {
      final rest =
          productImages.where((img) => img.url != variantImage.url).toList();
      return [variantImage, ...rest];
    }
    final len = productImages.length;
    final i = selectedVariantIndex.clamp(0, len - 1);
    if (i == 0 || len == 1) return productImages;
    return [
      productImages[i],
      ...productImages.sublist(0, i),
      ...productImages.sublist(i + 1),
    ];
  }

  ProductDetailState copyWith({
    Product? product,
    bool? isLoading,
    String? error,
    int? selectedVariantIndex,
    List<ProductImage>? displayImages,
    bool clearSelectedVariant = false,
  }) {
    return ProductDetailState(
      product: product ?? this.product,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedVariantIndex: clearSelectedVariant
          ? 0
          : (selectedVariantIndex ?? this.selectedVariantIndex),
      displayImages: displayImages ?? this.displayImages,
    );
  }
}

/// Product detail Notifier: hem API hem optimistik state.
class ProductDetailNotifier extends Notifier<ProductDetailState> {
  @override
  ProductDetailState build() {
    return const ProductDetailState();
  }

  ProductRepository get _repo => ref.read(productRepositoryProvider);

  /// Handle ile ürün yükle.
  Future<void> loadByHandle(String handle) async {
    state = state.copyWith(isLoading: true, error: null, clearSelectedVariant: true);
    try {
      final product = await _repo.getProductByHandle(handle);
      final displayImages = product != null
          ? ProductDetailState.computeDisplayImages(product, 0)
          : <ProductImage>[];
      state = state.copyWith(
        product: product,
        isLoading: false,
        error: product == null ? 'Ürün bulunamadı' : null,
        clearSelectedVariant: true,
        displayImages: displayImages,
      );
    } catch (e, _) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        clearSelectedVariant: true,
      );
    }
  }

  /// ID ile ürün yükle.
  Future<void> loadById(String id) async {
    state = state.copyWith(isLoading: true, error: null, clearSelectedVariant: true);
    try {
      final product = await _repo.getProductById(id);
      final displayImages = product != null
          ? ProductDetailState.computeDisplayImages(product, 0)
          : <ProductImage>[];
      state = state.copyWith(
        product: product,
        isLoading: false,
        error: product == null ? 'Ürün bulunamadı' : null,
        clearSelectedVariant: true,
        displayImages: displayImages,
      );
    } catch (e, _) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        clearSelectedVariant: true,
      );
    }
  }

  /// Varyant seçiminde state güncellenir (selectedVariantIndex + displayImages).
  void selectVariantByIndex(int index) {
    final product = state.product;
    if (product == null || index < 0 || index >= product.variants.length) return;
    final displayImages = ProductDetailState.computeDisplayImages(product, index);
    state = state.copyWith(
      selectedVariantIndex: index,
      displayImages: displayImages,
    );
  }
}

/// Product detail provider. [productHandle] veya [productId] ile çağrılır.
final productDetailProvider =
    NotifierProvider<ProductDetailNotifier, ProductDetailState>(
  ProductDetailNotifier.new,
);
