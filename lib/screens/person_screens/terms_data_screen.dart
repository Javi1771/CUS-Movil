// ignore_for_file: deprecated_member_use

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../widgets/steap_header.dart';
import '../../widgets/navigation_buttons.dart';

class TermsAndConditionsScreen extends StatefulWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  State<TermsAndConditionsScreen> createState() =>
      _TermsAndConditionsScreenState();
}

class _TermsAndConditionsScreenState extends State<TermsAndConditionsScreen>
    with SingleTickerProviderStateMixin {
  static const govBlue = Color(0xFF0B3B60);
  bool _accepted = false;
  late final AnimationController _checkAnim;

  @override
  void initState() {
    super.initState();
    _checkAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _checkAnim.dispose();
    super.dispose();
  }

  void _toggleAccepted() {
    setState(() {
      _accepted = !_accepted;
      if (_accepted) {
        _checkAnim.forward();
      } else {
        _checkAnim.reverse();
      }
    });
  }

  Widget _sectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: govBlue),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: govBlue,
            ),
          ),
        ],
      ),
    );
  }

  void _goNext() {
    if (_accepted) {
      //* Obtenemos los datos que vinieron de la pantalla anterior
      final List<String> datosFinales =
          ModalRoute.of(context)!.settings.arguments as List<String>;

      //* Navegamos a la pantalla de "Vista Previa"
      Navigator.pushNamed(
        context,
        '/preview-data',
        arguments: datosFinales,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //* Gradiente de fondo sutil
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF1F4F8), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            //* PasoHeader con paso 5
            const PasoHeader(
              pasoActual: 5,
              tituloPaso: 'Términos & Condiciones',
              tituloSiguiente: 'Vista Previa',
            ),

            //* Contenido principal
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    //* Card principal
                    _sectionHeader(Icons.security, 'Politicas de Uso'),
                    Card(
                      elevation: 12,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      shadowColor: govBlue.withOpacity(0.25),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            //* Título enriquecido
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: govBlue.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.gavel,
                                      color: govBlue, size: 32),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Términos y Condiciones',
                                  style: TextStyle(
                                    color: govBlue,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            //? Texto descriptivo
                            const Text(
                              'Lee detenidamente los siguientes puntos antes de continuar. '
                              'Al aceptar, confirmas que la información proporcionada es correcta '
                              'y aceptas nuestras políticas de uso.',
                              style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.black87,
                                  height: 1.5),
                            ),

                            const SizedBox(height: 20),
                            //? Divider estilizado
                            Divider(
                                color: govBlue.withOpacity(0.3),
                                thickness: 1.2),

                            const SizedBox(height: 16),

                            //? Links a detalle
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                    color: Colors.black87, fontSize: 14),
                                children: [
                                  const TextSpan(
                                      text: 'Consulta nuestra completa '),
                                  TextSpan(
                                    text: 'Política de Privacidad',
                                    style: const TextStyle(
                                      color: govBlue,
                                      decoration: TextDecoration.underline,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () => Navigator.pushNamed(
                                          context, '/privacy'),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 32),

                            //? Checkbox animado
                            GestureDetector(
                              onTap: _toggleAccepted,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  //? Caja con animación de check
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: _accepted
                                          ? govBlue
                                          : Colors.transparent,
                                      border: Border.all(
                                          color: _accepted
                                              ? govBlue
                                              : Colors.black38,
                                          width: 2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: ScaleTransition(
                                      scale: Tween(begin: 0.0, end: 1.0)
                                          .animate(CurvedAnimation(
                                              parent: _checkAnim,
                                              curve: Curves.easeOutBack)),
                                      child: const Icon(Icons.check,
                                          color: Colors.white, size: 20),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'He leído y acepto los Términos & Condiciones',
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: _accepted
                                            ? Colors.black87
                                            : Colors.black54,
                                        fontWeight: _accepted
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // Botones de navegación con padding extra
      bottomNavigationBar: NavigationButtons(
        enabled: _accepted,
        onBack: () => Navigator.pop(context),
        onNext: _goNext,
      ),
    );
  }
}
