import 'dart:ui';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/cart.dart';
import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_detail_provider.dart';
import '../widgets/premium_toast.dart';
import '../widgets/shimmer_skeleton.dart';

/// Ürün detay sayfası. [productHandle] veya [productId] ile açılır.
/// Optimistic UI: Varyant seçimi anında yansır.
class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({
    super.key,
    this.productHandle,
    this.productId,
  }) : assert(
          productHandle != null || productId != null,
          'productHandle veya productId gerekli',
        );

  final String? productHandle;
  final String? productId;

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  bool _isAddingToCart = false;
  int _stepperShakeKey = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProduct());
  }

  void _loadProduct() {
    final notifier = ref.read(productDetailProvider.notifier);
    if (widget.productHandle != null) {
      notifier.loadByHandle(widget.productHandle!);
    } else if (widget.productId != null) {
      notifier.loadById(widget.productId!);
    }
  }

  Future<void> _onAddToCart(BuildContext context, ProductVariant variant) async {
    setState(() => _isAddingToCart = true);
    showPremiumToast(context, message: 'Sepete eklendi', isSuccess: true);
    final success = await ref.read(cartProvider.notifier).addToCart(
          variantId: variant.id,
          quantity: 1,
          title: variant.title,
          imageUrl: variant.image?.url,
          priceAmount: variant.price.amount,
          priceCurrencyCode: variant.price.currencyCode,
        );
    if (!mounted) return;
    setState(() => _isAddingToCart = false);
    if (!success) {
      showPremiumToast(
        context,
        message:
            'Sepete eklenemedi. İnternet bağlantınızı kontrol edin. Değişiklik geri alındı.',
        isSuccess: false,
      );
    }
  }

  Future<void> _onDecreaseFromCart(
    BuildContext context,
    String variantId,
    int currentQuantity,
  ) async {
    final success = await ref.read(cartProvider.notifier).removeFromCart(variantId);
    if (!mounted) return;
    if (success && currentQuantity == 1) {
      showPremiumToast(
        context,
        message: 'Ürün sepetten kaldırıldı',
        type: PremiumToastType.info,
      );
    } else if (!success) {
      setState(() => _stepperShakeKey++);
      showPremiumToast(
        context,
        message: 'İşlem başarısız. Tekrar deneyin.',
        isSuccess: false,
      );
    }
  }

  Future<void> _onIncreaseInCart(BuildContext context, String variantId) async {
    final success =
        await ref.read(cartProvider.notifier).increaseQuantity(variantId);
    if (!mounted) return;
    if (!success) {
      setState(() => _stepperShakeKey++);
      showPremiumToast(
        context,
        message: 'Miktar güncellenemedi. Tekrar deneyin.',
        isSuccess: false,
      );
    }
  }

  /// HTML'den düz metin; kısa açıklama için ilk ~160 karakter.
  static String? _shortDescription(String? html) {
    if (html == null || html.isEmpty) return null;
    final stripped = html
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (stripped.isEmpty) return null;
    return stripped.length > 160 ? '${stripped.substring(0, 160)}…' : stripped;
  }

  Widget _buildAddOrStepper(
    BuildContext context,
    Cart cart,
    ProductVariant? selectedVariant,
  ) {
    if (selectedVariant == null) return const SizedBox.shrink();
    final quantity = cart.quantityForVariant(selectedVariant.id);
    final isStepper = quantity > 0;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
      child: isStepper
          ? KeyedSubtree(
              key: const ValueKey('stepper'),
              child: _CartStepper(
                variantId: selectedVariant.id,
                quantity: quantity,
                shakeTrigger: _stepperShakeKey,
                onDecrease: () => _onDecreaseFromCart(
                  context,
                  selectedVariant.id,
                  quantity,
                ),
                onIncrease: () => _onIncreaseInCart(context, selectedVariant.id),
              ),
            )
          : KeyedSubtree(
              key: const ValueKey('add'),
              child: _AddToCartButton(
                isAdding: _isAddingToCart,
                enabled: selectedVariant.availableForSale,
                onPressed: () => _onAddToCart(context, selectedVariant),
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productDetailProvider);
    final cart = ref.watch(cartProvider);

    if (state.isLoading && state.product == null) {
      return const ProductDetailSkeleton();
    }

    if (state.error != null && state.product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ürün')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(state.error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loadProduct,
                child: const Text('Tekrar dene'),
              ),
            ],
          ),
        ),
      );
    }

    final product = state.product;
    if (product == null) {
      return const Scaffold(
        body: Center(child: Text('Ürün bulunamadı')),
      );
    }

    final selectedVariant = state.selectedVariant;
    final price = selectedVariant?.price ?? product.priceRange?.minVariantPrice;
    final displayImages = state.displayImages;

    return Scaffold(
      appBar: AppBar(
        title: Text(product.title),
        actions: [
          IconButton(
            icon: cart.totalQuantity > 0
                ? Badge(
                    label: Text(
                      '${cart.totalQuantity}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                    child: const Icon(Icons.shopping_cart_outlined),
                  )
                : const Icon(Icons.shopping_cart_outlined),
            onPressed: () {},
          ),
          if (state.isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadProduct(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ProductImageCarousel(
                key: ValueKey(product.id),
                images: displayImages,
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (product.vendor != null &&
                        product.vendor!.isNotEmpty) ...[
                      Text(
                        product.vendor!,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      product.title,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (price != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        '${price.amount} ${price.currencyCode}',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ],
                    if (selectedVariant != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        selectedVariant.availableForSale
                            ? 'Stokta var'
                            : 'Stokta yok',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: selectedVariant.availableForSale
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.error,
                            ),
                      ),
                    ],
                    if (_shortDescription(product.descriptionHtml) != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _shortDescription(product.descriptionHtml)!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              height: 1.4,
                            ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (product.variants.length > 1) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Varyant',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 16),
                      _VariantSelector(
                        variants: product.variants,
                        selectedIndex: state.selectedVariantIndex,
                        onSelected: (index) {
                          ref
                              .read(productDetailProvider.notifier)
                              .selectVariantByIndex(index);
                        },
                      ),
                    ],
                    if (product.descriptionHtml != null &&
                        product.descriptionHtml!.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _ProductDescriptionAccordion(
                        descriptionHtml: product.descriptionHtml!,
                      ),
                    ],
                  ],
                ),
              ),
              // Floating footer altında kalan içeriğin gizlenmemesi için alt boşluk.
              SizedBox(height: MediaQuery.of(context).padding.bottom + 100),
            ],
          ),
        ),
      ),
      bottomNavigationBar: selectedVariant != null
          ? _FloatingFooter(
              child: _buildAddOrStepper(context, cart, selectedVariant),
            )
          : null,
    );
  }
}

/// Ekranın en altında sabit, 80–100px yüksekliğinde gölgeli ve blur efektli panel (Floating Footer).
class _FloatingFooter extends StatelessWidget {
  const _FloatingFooter({required this.child});

  final Widget child;

  static const double _contentHeight = 100;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      height: _contentHeight + bottomPadding,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: double.infinity,
            height: _contentHeight + bottomPadding,
            padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + bottomPadding),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.92),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.12),
                ),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Carousel: Varyant değişince görseller güncellenir ve animateToPage ile ilk sayfaya akıcı kayar.
class _ProductImageCarousel extends StatefulWidget {
  const _ProductImageCarousel({
    super.key,
    required this.images,
  });

  final List<ProductImage> images;

  @override
  State<_ProductImageCarousel> createState() => _ProductImageCarouselState();
}

class _ProductImageCarouselState extends State<_ProductImageCarousel> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void didUpdateWidget(covariant _ProductImageCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.images != widget.images &&
        widget.images.isNotEmpty &&
        _currentPage != 0) {
      _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
      _currentPage = 0;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    if (images.isEmpty) {
      return AspectRatio(
        aspectRatio: 1,
        child: ColoredBox(
          color: Colors.grey.shade200,
          child: const Center(
            child: Icon(Icons.image_not_supported, size: 48),
          ),
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: images.length,
            itemBuilder: (context, index) {
              final image = images[index];
              return Image.network(
                image.url,
                fit: BoxFit.cover,
                key: ValueKey(image.url),
                errorBuilder: (_, __, ___) => const ColoredBox(
                  color: Colors.grey,
                  child: Center(child: Icon(Icons.image_not_supported)),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(images.length, (index) {
            final isSelected = index == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isSelected ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade400,
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

/// Sepette ürün varken gösterilen '-' miktar '+' stepper.
/// [shakeTrigger] artırıldığında (rollback) sallanma animasyonu oynatılır.
class _CartStepper extends StatefulWidget {
  const _CartStepper({
    required this.variantId,
    required this.quantity,
    required this.shakeTrigger,
    required this.onDecrease,
    required this.onIncrease,
  });

  final String variantId;
  final int quantity;
  final int shakeTrigger;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  State<_CartStepper> createState() => _CartStepperState();
}

class _CartStepperState extends State<_CartStepper>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(covariant _CartStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shakeTrigger != oldWidget.shakeTrigger && widget.shakeTrigger > 0) {
      _shakeController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  double _shakeOffset(double t) {
    if (t >= 1) return 0;
    const amp = 10.0;
    const cycles = 5;
    return math.sin(t * cycles * 2 * math.pi) * amp * (1 - t);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        final tx = _shakeOffset(_shakeAnimation.value);
        if (tx == 0) return child!;
        return Transform.translate(
          offset: Offset(tx, 0),
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primary.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton.filled(
              onPressed: widget.onDecrease,
              icon: const Icon(Icons.remove_rounded),
              style: IconButton.styleFrom(
                backgroundColor: primary.withOpacity(0.12),
                foregroundColor: primary,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                '${widget.quantity}',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: primary,
                ),
              ),
            ),
            IconButton.filled(
              onPressed: widget.onIncrease,
              icon: const Icon(Icons.add_rounded),
              style: IconButton.styleFrom(
                backgroundColor: primary.withOpacity(0.12),
                foregroundColor: primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddToCartButton extends StatefulWidget {
  const _AddToCartButton({
    required this.isAdding,
    required this.enabled,
    this.onPressed,
  });

  final bool isAdding;
  final bool enabled;
  final VoidCallback? onPressed;

  @override
  State<_AddToCartButton> createState() => _AddToCartButtonState();
}

class _AddToCartButtonState extends State<_AddToCartButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final onPrimary = theme.colorScheme.onPrimary;
    final disabled = !widget.enabled || widget.isAdding;

    return Listener(
      onPointerDown: (_) =>
          widget.enabled && !widget.isAdding ? setState(() => _pressed = true) : null,
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 100),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: disabled ? null : widget.onPressed,
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: disabled
                    ? null
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [primary, primary.withOpacity(0.85)],
                      ),
                color: disabled ? Colors.grey.shade300 : null,
                boxShadow: disabled
                    ? null
                    : [
                        BoxShadow(
                          color: primary.withOpacity(0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
              ),
              child: Center(
                child: widget.isAdding
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: onPrimary,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_shopping_cart_rounded, color: onPrimary),
                          const SizedBox(width: 12),
                          Text(
                            'Sepete Ekle',
                            style: theme.textTheme.titleMedium?.copyWith(
                                  color: onPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Ürün açıklaması: hafif gölge + ince kenarlık Card, ExpansionTile akordiyon.
class _ProductDescriptionAccordion extends StatelessWidget {
  const _ProductDescriptionAccordion({
    required this.descriptionHtml,
  });

  final String descriptionHtml;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.dividerColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      margin: EdgeInsets.zero,
      child: Theme(
        data: theme.copyWith(
          dividerColor: Colors.transparent,
          splashColor: theme.colorScheme.primary.withOpacity(0.08),
          highlightColor: theme.colorScheme.primary.withOpacity(0.04),
        ),
        child: ExpansionTile(
          title: Text(
            'Ürün Açıklaması',
            style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          childrenPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          children: [
            Html(
              data: descriptionHtml,
              style: {
                'p': Style(
                  margin: Margins.only(bottom: 12),
                ),
                'strong': Style(
                  fontWeight: FontWeight.bold,
                ),
                'b': Style(
                  fontWeight: FontWeight.bold,
                ),
                'em': Style(
                  fontStyle: FontStyle.italic,
                ),
                'i': Style(
                  fontStyle: FontStyle.italic,
                ),
                'ul': Style(
                  margin: Margins.only(bottom: 12),
                ),
                'ol': Style(
                  margin: Margins.only(bottom: 12),
                ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _VariantSelector extends StatelessWidget {
  const _VariantSelector({
    required this.variants,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<ProductVariant> variants;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(variants.length, (i) {
        final v = variants[i];
        final selected = i == selectedIndex;
        return _VariantChip(
          label: v.title,
          selected: selected,
          onTap: () => onSelected(i),
        );
      }),
    );
  }
}

/// Seçildiğinde hafif büyüyen ve rengi yumuşak geçişle değişen varyant çipi.
class _VariantChip extends StatelessWidget {
  const _VariantChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedScale(
          scale: selected ? 1.08 : 1.0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: selected
                  ? primary.withOpacity(0.18)
                  : theme.colorScheme.surfaceContainerHighest.withOpacity(0.6),
              border: Border.all(
                color: selected ? primary : Colors.transparent,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(Icons.check_rounded, size: 18, color: primary),
                  ),
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected ? primary : theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

