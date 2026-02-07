import 'dart:ui';
import 'package:flutter/cupertino.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final double? height;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.blur = 10.0,
    this.opacity = 0.7,
    this.height,
    this.borderRadius,
    this.padding,
    this.margin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final br = borderRadius ?? BorderRadius.circular(20);

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: br,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              height: height,
              decoration: BoxDecoration(
                color: CupertinoColors.systemBackground.resolveFrom(context).withOpacity(opacity),
                borderRadius: br,
                border: Border.all(
                  color: CupertinoColors.systemGrey4.resolveFrom(context).withOpacity(0.5),
                  width: 0.5,
                ),
              ),
              padding: padding ?? const EdgeInsets.all(24.0),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
