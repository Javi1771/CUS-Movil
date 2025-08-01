// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../screens/components/help_button.dart';

class PasoHeader extends StatelessWidget {
  final int pasoActual;
  final String tituloPaso;
  final String tituloSiguiente;
  final Color colorPrimario;

  const PasoHeader({
    super.key, // ✅ super.key utilizado correctamente
    required this.pasoActual,
    required this.tituloPaso,
    required this.tituloSiguiente,
    this.colorPrimario = const Color(0xFF0B3B60),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 190,
      decoration: BoxDecoration(
        color: colorPrimario,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(60),
          bottomRight: Radius.circular(60),
        ),
      ),
      child: Stack(
        children: [
          const Positioned(
            top: 35,
            right: 5,
            child: HelpButton(
              iconColor: Colors.white,
              backgroundColor: Color.fromARGB(255, 35, 102, 153),
              supportEmail: 'sistemas@sanjuandelrio.gob.mx',
              emailSubject: 'Soporte CUS',
            ),
          ),

          // Círculos decorativos
          Positioned(
            top: -20,
            left: -60,
            child: Transform.rotate(
              angle: -0.4,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(
                      (0.05 * 255).toInt()), // ✅ reemplazo de withOpacity
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Positioned(
            right: -50,
            bottom: -40,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(
                    (0.06 * 255).toInt()), // ✅ reemplazo de withOpacity
                borderRadius: BorderRadius.circular(60),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Registro Cívico',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: const Color(0xFF0377C6),
                        child: Text(
                          '$pasoActual',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Paso $pasoActual: $tituloPaso',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Siguiente: $tituloSiguiente',
                              style: const TextStyle(
                                color: Color(0xFFE2ECF4),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
