import 'package:flutter/material.dart';

class StaggeredList extends StatelessWidget {
  final List<Widget> children;
  final Duration staggerDuration;
  final Duration itemDuration;
  final Curve curve;

  const StaggeredList({
    super.key,
    required this.children,
    this.staggerDuration = const Duration(milliseconds: 100),
    this.itemDuration = const Duration(milliseconds: 400),
    this.curve = Curves.easeOutCubic,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        children.length,
        (index) => TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: itemDuration + (staggerDuration * index),
          curve: curve,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            );
          },
          child: children[index],
        ),
      ),
    );
  }
}
