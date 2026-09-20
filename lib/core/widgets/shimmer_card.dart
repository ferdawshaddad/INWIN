import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../constants/app_theme.dart';

/// Generic shimmer skeleton for loading states.
class ShimmerCard extends StatelessWidget {
  final double height;
  final double? width;
  final double radius;

  const ShimmerCard({
    super.key,
    this.height = 80,
    this.width,
    this.radius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.divider,
      highlightColor: Colors.white,
      child: Container(
        height: height,
        width: width ?? double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

/// Full shimmer list — 4 skeleton cards
class ShimmerList extends StatelessWidget {
  final int count;
  const ShimmerList({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) => Column(
    children: List.generate(
      count,
      (i) => ShimmerCard(height: 88 + (i % 2) * 12.0),
    ),
  );
}

/// Shimmer row — for inline content (e.g. inside a card)
class ShimmerLine extends StatelessWidget {
  final double width;
  final double height;

  const ShimmerLine({super.key, this.width = double.infinity, this.height = 14});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.divider,
      highlightColor: Colors.white,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(7),
        ),
      ),
    );
  }
}
