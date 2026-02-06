import 'package:flutter/material.dart';

/// Ürün detay sayfası için shimmer skeleton (veri gelene kadar).
class ProductDetailSkeleton extends StatefulWidget {
  const ProductDetailSkeleton({super.key});

  @override
  State<ProductDetailSkeleton> createState() => _ProductDetailSkeletonState();
}

class _ProductDetailSkeletonState extends State<ProductDetailSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: _ShimmerBox(
                  animation: _animation,
                  borderRadius: 0,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ShimmerBox(
                      animation: _animation,
                      height: 28,
                      width: double.infinity,
                      borderRadius: 8,
                    ),
                    const SizedBox(height: 16),
                    _ShimmerBox(
                      animation: _animation,
                      height: 24,
                      width: 120,
                      borderRadius: 8,
                    ),
                    const SizedBox(height: 24),
                    _ShimmerBox(
                      animation: _animation,
                      height: 56,
                      width: double.infinity,
                      borderRadius: 20,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({
    required this.animation,
    this.height,
    this.width,
    this.borderRadius = 4,
  });

  final Animation<double> animation;
  final double? height;
  final double? width;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              begin: Alignment(animation.value - 1, 0),
              end: Alignment(animation.value, 0),
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade100,
                Colors.grey.shade300,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}
