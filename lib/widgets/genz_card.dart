import 'dart:ui';
import 'package:flutter/material.dart';

class GenZCard extends StatelessWidget {
  final Widget child;
  final double? height;
  final double? width;
  final Color? color;
  final bool isGlass;
  final VoidCallback? onTap;
  final EdgeInsets? padding;

  const GenZCard({
    super.key,
    required this.child,
    this.height,
    this.width,
    this.color,
    this.isGlass = false,
    this.onTap,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: isGlass
              ? ImageFilter.blur(sigmaX: 10, sigmaY: 10)
              : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
          child: Container(
            height: height,
            width: width,
            padding: padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  color ??
                  (isDark
                      ? Colors.white.withOpacity(isGlass ? 0.1 : 0.05)
                      : Colors.white),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05),
                width: 1.5,
              ),
              boxShadow: [
                if (!isGlass)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
