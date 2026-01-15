import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerCard extends StatelessWidget {
  final double height;
  final double? width;

  const ShimmerCard({
    super.key,
    this.height = 100,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF2A2A2A),
      highlightColor: const Color(0xFF3A3A3A),
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: const Color(0xFF242424),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

class ShimmerList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const ShimmerList({
    super.key,
    this.itemCount = 3,
    this.itemHeight = 120,
    this.shrinkWrap = true,
    this.physics = const NeverScrollableScrollPhysics(),
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemCount: itemCount,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ShimmerCard(height: itemHeight),
        );
      },
    );
  }
}
