// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import '../routes/slide_up_route.dart';
import 'moral_screens/moral_data_screen.dart';
import 'person_screens/fisica_data_screen.dart';
import 'widgets/steap_header.dart';

class PersonTypeScreen extends StatefulWidget {
  const PersonTypeScreen({super.key});

  @override
  State<PersonTypeScreen> createState() => _PersonTypeScreenState();
}

class _PersonTypeScreenState extends State<PersonTypeScreen> {
  String? selectedType;
  static const Color govBlue = Color(0xFF0B3B60);

  void _navigate() {
    final nextPage = selectedType == 'fisica'
        ? const FisicaDataScreen()
        : const MoralDataScreen();

    Navigator.of(context).push(
      SlideUpRoute(page: nextPage),
    );
  }

  Widget _option({
    required String title,
    required IconData icon,
    required String type,
  }) {
    final isSelected = selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    children: [
                      _option(
                        title: 'Persona Física',
                        icon: Icons.person_outline,
                        type: 'fisica',
                      ),
                      _option(
                        title: 'Persona Moral',
                        icon: Icons.apartment_outlined,
                        type: 'moral',
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
                  const SizedBox(height: 150),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: selectedType != null ? _navigate : null,
                      icon: AnimatedRotation(
                        duration: const Duration(milliseconds: 300),
                        turns: selectedType != null ? 0.25 : 0,
                        child: const Icon(Icons.arrow_forward_rounded),
                      ),
                      label: const Text(
                        'Continuar',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: govBlue,
                        disabledBackgroundColor: govBlue.withOpacity(0.4),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
