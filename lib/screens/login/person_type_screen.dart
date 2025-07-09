// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import '../../routes/slide_up_route.dart';
import '../moral_screens/moral_data_screen.dart';
import '../person_screens/fisica_data_screen.dart';
import '../work_screens/work_data_screen.dart';
import '../widgets/steap_header.dart';

const Color govBlue = Color(0xFF0B3B60);

class PersonTypeScreen extends StatefulWidget {
  const PersonTypeScreen({super.key});

  @override
  State<PersonTypeScreen> createState() => _PersonTypeScreenState();
}

class _PersonTypeScreenState extends State<PersonTypeScreen> {
  String? selectedType;

  void _navigate() {
    Widget nextPage;

    switch (selectedType) {
      case 'fisica':
        nextPage = const FisicaDataScreen();
        break;
      case 'moral':
        nextPage = const MoralDataScreen();
        break;
      case 'trabajador':
        nextPage = const WorkDataScreen();
        break;
      default:
        return;
    }

    Navigator.of(context).push(SlideUpRoute(page: nextPage));
  }

  void _showInfoAndSelect(String type, String title, String content) {
    IconData icon;
    switch (type) {
      case 'fisica':
        icon = Icons.person_outline;
        break;
      case 'moral':
        icon = Icons.apartment_outlined;
        break;
      case 'trabajador':
        icon = Icons.engineering_outlined;
        break;
      default:
        icon = Icons.info_outline;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: govBlue,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Icon(icon, size: 48, color: Colors.white),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    content,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.only(bottom: 16, left: 12, right: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: govBlue,
                      side: BorderSide(color: govBlue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('CANCELAR'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: govBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      setState(() => selectedType = type);
                      Navigator.of(ctx).pop();
                    },
                    child: const Text('SELECCIONAR'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _option({
    required String title,
    required IconData icon,
    required String type,
    required String infoText,
  }) {
    final isSelected = selectedType == type;
    return GestureDetector(
      onTap: () => _showInfoAndSelect(type, title, infoText),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? govBlue : Colors.white,
          border: Border.all(color: govBlue, width: 2),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isSelected ? govBlue.withOpacity(0.4) : Colors.black12,
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 56, color: isSelected ? Colors.white : govBlue),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: isSelected ? Colors.white : govBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double cardWidth = MediaQuery.of(context).size.width * 0.38;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F4F8),
      body: Column(
        children: [
          const PasoHeader(
            pasoActual: 1,
            tituloPaso: 'Tipo de persona',
            tituloSiguiente: 'Datos personales',
          ),
          const SizedBox(height: 32),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '¿Qué tipo de persona deseas registrar?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: govBlue,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: cardWidth,
                        child: _option(
                          title: 'Persona Física',
                          icon: Icons.person_outline,
                          type: 'fisica',
                          infoText:
                              'Una persona física es cualquier individuo con derechos y obligaciones, es decir, cualquier persona capaz de actuar y responder ante la ley.',
                        ),
                      ),
                      const SizedBox(width: 24),
                      SizedBox(
                        width: cardWidth,
                        child: _option(
                          title: 'Persona Moral',
                          icon: Icons.apartment_outlined,
                          type: 'moral',
                          infoText:
                              'Una persona moral es una entidad legal conformada por una o más personas físicas, como empresas, asociaciones o instituciones, con personalidad jurídica propia.',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: cardWidth,
                        child: _option(
                          title: 'Trabajador',
                          icon: Icons.engineering_outlined,
                          type: 'trabajador',
                          infoText:
                              'Un trabajador es una persona física que presta un servicio personal subordinado a una persona o entidad a cambio de un salario.',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Selecciona una opción para habilitar el botón “Continuar”.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 72,
                    child: ElevatedButton(
                      onPressed: selectedType != null ? _navigate : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: govBlue,
                        disabledBackgroundColor: govBlue.withOpacity(0.4),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Continuar',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 28,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}