import 'package:flutter/material.dart';

class InwinLogo extends StatelessWidget {
  const InwinLogo({
    super.key,
    this.height = 100,
    this.fit = BoxFit.contain,
  });

  final double height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo inwin final.png',
      height: height,
      fit: fit,
    );
  }
}
