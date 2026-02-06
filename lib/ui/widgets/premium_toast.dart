import 'dart:ui';

import 'package:flutter/material.dart';

enum PremiumToastType { success, error, info }

/// Ekranın üstünden animasyonla inen, süre sonunda animasyonla çıkan bildirim.
void showPremiumToast(
  BuildContext context, {
  required String message,
  bool isSuccess = true,
  PremiumToastType? type,
  Duration duration = const Duration(seconds: 2),
}) {
  final effectiveType =
      type ?? (isSuccess ? PremiumToastType.success : PremiumToastType.error);
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => _AnimatedPremiumToast(
      message: message,
      type: effectiveType,
      displayDuration: duration,
      onExit: () {
        entry.remove();
      },
    ),
  );
  overlay.insert(entry);
}

class _AnimatedPremiumToast extends StatefulWidget {
  const _AnimatedPremiumToast({
    required this.message,
    required this.type,
    required this.displayDuration,
    required this.onExit,
  });

  final String message;
  final PremiumToastType type;
  final Duration displayDuration;
  final VoidCallback onExit;

  @override
  State<_AnimatedPremiumToast> createState() => _AnimatedPremiumToastState();
}

class _AnimatedPremiumToastState extends State<_AnimatedPremiumToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slide;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.65, curve: Curves.easeOut),
      ),
    );
    _controller.forward();
    Future.delayed(widget.displayDuration, _runExit);
  }

  void _runExit() async {
    if (!mounted) return;
    await _controller.reverse();
    if (mounted) widget.onExit();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color color;
    final IconData icon;
    switch (widget.type) {
      case PremiumToastType.success:
        color = Colors.green.shade700;
        icon = Icons.check_circle_rounded;
        break;
      case PremiumToastType.error:
        color = Colors.red.shade700;
        icon = Icons.error_rounded;
        break;
      case PremiumToastType.info:
        color = theme.colorScheme.primary;
        icon = Icons.remove_shopping_cart_rounded;
        break;
    }
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 24,
      right: 24,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return SlideTransition(
            position: _slide,
            child: FadeTransition(
              opacity: _opacity,
              child: Material(
                color: Colors.transparent,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(icon, color: Colors.white, size: 28),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              widget.message,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
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
        },
      ),
    );
  }
}
