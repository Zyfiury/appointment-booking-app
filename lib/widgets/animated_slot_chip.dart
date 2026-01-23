import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AnimatedSlotChip extends StatefulWidget {
  final String slot;
  final bool selected;
  final ThemeColors colors;
  final VoidCallback onTap;

  const AnimatedSlotChip({
    super.key,
    required this.slot,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  @override
  State<AnimatedSlotChip> createState() => _AnimatedSlotChipState();
}

class _AnimatedSlotChipState extends State<AnimatedSlotChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _colorAnimation = ColorTween(
      begin: widget.colors.surfaceColor,
      end: widget.colors.primaryColor.withOpacity(0.2),
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.selected) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(AnimatedSlotChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected != oldWidget.selected) {
      if (widget.selected) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedBuilder(
          animation: _colorAnimation,
          builder: (context, child) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: widget.selected
                    ? widget.colors.primaryColor.withOpacity(0.2)
                    : widget.colors.surfaceColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.selected
                      ? widget.colors.primaryColor
                      : widget.colors.borderColor.withOpacity(0.5),
                  width: widget.selected ? 2 : 1,
                ),
                boxShadow: widget.selected
                    ? [
                        BoxShadow(
                          color: widget.colors.primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                widget.slot,
                style: TextStyle(
                  color: widget.selected
                      ? widget.colors.primaryColor
                      : widget.colors.textPrimary,
                  fontWeight: widget.selected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
