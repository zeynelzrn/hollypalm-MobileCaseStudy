/// Shopify Storefront API Product model.
class Product {
  const Product({
    required this.id,
    required this.title,
    required this.handle,
    this.vendor,
    this.descriptionHtml,
    required this.featuredImage,
    this.images = const [],
    required this.variants,
    this.priceRange,
  });

  final String id;
  final String title;
  final String handle;
  /// Marka (Shopify vendor).
  final String? vendor;
  final String? descriptionHtml;
  final ProductImage? featuredImage;
  /// Ürünün tüm görselleri (slider için).
  final List<ProductImage> images;
  final List<ProductVariant> variants;
  final ProductPriceRange? priceRange;

  factory Product.fromJson(Map<String, dynamic> json) {
    final imagesEdges = json['images']?['edges'] as List<dynamic>? ?? [];
    final imagesList = imagesEdges
        .map((e) => ProductImage.fromJson(
              (e as Map<String, dynamic>)['node'] as Map<String, dynamic>,
            ))
        .toList();
    return Product(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      handle: json['handle'] as String? ?? '',
      vendor: json['vendor'] as String?,
      descriptionHtml: json['descriptionHtml'] as String?,
      featuredImage: json['featuredImage'] != null
          ? ProductImage.fromJson(
              json['featuredImage'] as Map<String, dynamic>,
            )
          : null,
      images: imagesList,
      variants: (json['variants']?['edges'] as List<dynamic>?)
              ?.map((e) => ProductVariant.fromJson(
                    (e as Map<String, dynamic>)['node'] as Map<String, dynamic>,
                  ))
              .toList() ??
          [],
      priceRange: json['priceRange'] != null
          ? ProductPriceRange.fromJson(
              json['priceRange'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  ProductVariant? get firstVariant =>
      variants.isNotEmpty ? variants.first : null;
}

class ProductImage {
  const ProductImage({
    required this.url,
    this.altText,
    this.width,
    this.height,
  });

  final String url;
  final String? altText;
  final int? width;
  final int? height;

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      url: json['url'] as String? ?? '',
      altText: json['altText'] as String?,
      width: json['width'] as int?,
      height: json['height'] as int?,
    );
  }
}

class ProductVariant {
  const ProductVariant({
    required this.id,
    required this.title,
    required this.availableForSale,
    required this.price,
    this.compareAtPrice,
    required this.image,
    this.selectedOptions,
  });

  final String id;
  final String title;
  final bool availableForSale;
  final Money price;
  final Money? compareAtPrice;
  final ProductImage? image;
  final List<SelectedOption>? selectedOptions;

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      availableForSale: json['availableForSale'] as bool? ?? false,
      price: Money.fromJson(
        (json['price'] as Map<String, dynamic>? ?? {}),
      ),
      compareAtPrice: json['compareAtPrice'] != null
          ? Money.fromJson(json['compareAtPrice'] as Map<String, dynamic>)
          : null,
      image: json['image'] != null
          ? ProductImage.fromJson(json['image'] as Map<String, dynamic>)
          : null,
      selectedOptions: (json['selectedOptions'] as List<dynamic>?)
          ?.map((e) => SelectedOption.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Money {
  const Money({
    required this.amount,
    required this.currencyCode,
  });

  final String amount;
  final String currencyCode;

  factory Money.fromJson(Map<String, dynamic> json) {
    return Money(
      amount: json['amount'] as String? ?? '0',
      currencyCode: json['currencyCode'] as String? ?? 'USD',
    );
  }
}

class SelectedOption {
  const SelectedOption({
    required this.name,
    required this.value,
  });

  final String name;
  final String value;

  factory SelectedOption.fromJson(Map<String, dynamic> json) {
    return SelectedOption(
      name: json['name'] as String? ?? '',
      value: json['value'] as String? ?? '',
    );
  }
}

class ProductPriceRange {
  const ProductPriceRange({
    required this.minVariantPrice,
    required this.maxVariantPrice,
  });

  final Money minVariantPrice;
  final Money maxVariantPrice;

  factory ProductPriceRange.fromJson(Map<String, dynamic> json) {
    return ProductPriceRange(
      minVariantPrice: Money.fromJson(
        json['minVariantPrice'] as Map<String, dynamic>? ?? {},
      ),
      maxVariantPrice: Money.fromJson(
        json['maxVariantPrice'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}
