import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';

class LayeredCard extends StatefulWidget {
  final Widget child;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final double? elevation;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  const LayeredCard({
    super.key,
    required this.child,
    this.margin,
    this.padding,
    this.elevation = 8,
    this.backgroundColor,
    this.onTap,
    this.borderRadius,
  });

  @override
  State<LayeredCard> createState() => _LayeredCardState();
}

class _LayeredCardState extends State<LayeredCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = AppTheme.getColors(themeProvider.currentTheme);

    final card = Container(
      margin: widget.margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: widget.padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? colors.cardColor,
        borderRadius: widget.borderRadius ?? BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: widget.elevation! * 1.5,
            offset: Offset(0, widget.elevation! / 2),
            spreadRadius: -2,
          ),
          BoxShadow(
            color: (widget.backgroundColor ?? colors.cardColor).withOpacity(0.1),
            blurRadius: widget.elevation! * 2,
            offset: Offset(0, widget.elevation!),
            spreadRadius: -widget.elevation! / 2,
          ),
        ],
      ),
      child: widget.child,
    );

    Widget result = card;

    if (widget.onTap != null) {
      result = GestureDetector(
        onTapDown: (_) {
          _hoverController.forward();
          HapticFeedback.selectionClick();
        },
        onTapUp: (_) {
          _hoverController.reverse();
          HapticFeedback.lightImpact();
          widget.onTap?.call();
        },
        onTapCancel: () => _hoverController.reverse(),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: widget.borderRadius ?? BorderRadius.circular(22),
              child: card,
            ),
          ),
        ),
      );
    }

    return result;
  }
}

class FloatingCard extends StatefulWidget {
  final Widget child;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const FloatingCard({
    super.key,
    required this.child,
    this.margin,
    this.padding,
    this.backgroundColor,
    this.onTap,
  });

  @override
  State<FloatingCard> createState() => _FloatingCardState();
}

class _FloatingCardState extends State<FloatingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = AppTheme.getColors(themeProvider.currentTheme);
    final card = Container(
      margin: widget.margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: widget.padding ?? const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? colors.cardElevated,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 24,
            offset: const Offset(0, 10),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: colors.primaryColor.withOpacity(0.15),
            blurRadius: 32,
            offset: const Offset(0, 14),
            spreadRadius: -8,
          ),
        ],
      ),
      child: widget.child,
    );

    Widget result = card;

    if (widget.onTap != null) {
      result = GestureDetector(
        onTapDown: (_) => _hoverController.forward(),
        onTapUp: (_) {
          _hoverController.reverse();
          widget.onTap?.call();
        },
        onTapCancel: () => _hoverController.reverse(),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: card,
        ),
      );
    }

    return result;
  }
}
