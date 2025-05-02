import 'package:flutter/material.dart';

class Bubble extends StatelessWidget {
  final double size;
  final double opacity;

  const Bubble({
    super.key,
    required this.size,
    this.opacity = 0.01,
  });

  @override
  Widget build(BuildContext context) {
    //* Calculamos el alpha basado en la opacidad recibida
    final int alpha =
        (255 * opacity).clamp(50, 255).toInt(); //! evita valores demasiado bajos

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color.fromARGB(alpha, 11, 59, 96),
      ),
    );
  }
}
