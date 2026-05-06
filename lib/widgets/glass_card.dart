import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../config/theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final BorderRadiusGeometry borderRadius;
  final EdgeInsetsGeometry? padding;
  final bool showBorder;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;
  final BoxBorder? border;
  final Color? backgroundColor;
  final BoxConstraints? constraints;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(AppTheme.borderRadius)),
    this.padding,
    this.margin,
    this.showBorder = true,
    this.border,
    this.backgroundColor,
    this.onTap,
    this.constraints,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget cardContent = Container(
      padding: padding,
      margin: margin,
      constraints: constraints,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        color: backgroundColor,
        gradient: backgroundColor == null ? AppTheme.glassGradient(isDark) : null,
        border: border ?? (showBorder 
            ? Border.all(
                color: isDark 
                    ? Colors.white.withValues(alpha: 0.1) 
                    : Colors.white.withValues(alpha: 0.2),
                width: 1,
              ) 
            : null),
      ),
      child: child,
    );

    // Use kIsWeb from foundation for more reliable detection
    if (!kIsWeb) {
      cardContent = ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: cardContent,
        ),
      );
    } else {
      // On web, BackdropFilter is extremely expensive and causes layout lag
      cardContent = ClipRRect(
        borderRadius: borderRadius,
        child: cardContent,
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: cardContent,
    );
  }
}

