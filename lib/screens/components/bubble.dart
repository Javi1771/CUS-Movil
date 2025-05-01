// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class Bubble extends StatelessWidget {
  final double size;
  final double opacity;

  const Bubble({
    super.key,
    required this.size,
    this.opacity = 0.1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF0E385D).withOpacity(opacity),
      ),
    );
  }
}
