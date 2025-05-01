// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class PersonTypeScreen extends StatefulWidget {
  const PersonTypeScreen({super.key});

  @override
  State<PersonTypeScreen> createState() => _PersonTypeScreenState();
}

class _PersonTypeScreenState extends State<PersonTypeScreen> {
  String? selectedType;
  static const Color govBlue = Color(0xFF0b3b60);

  void _navigate() {
    if (selectedType == 'fisica') {
      Navigator.pushNamed(context, '/fisica-data');
    } else if (selectedType == 'moral') {
      Navigator.pushNamed(context, '/moral-data');
    }
  }

  Widget _option({
    required String title,
    required IconData icon,
    required String type,
  }) {
    final isSelected = selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedType = type;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? govBlue : Colors.white,
            border: Border.all(color: govBlue, width: 2),
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
                ? [
                    const BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    )
                  ]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 50, color: isSelected ? Colors.white : govBlue),
              const SizedBox(height: 14),
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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 1,
        backgroundColor: Colors.white,
        title: const Text(
          'Registro Cívico',
          style: TextStyle(color: govBlue, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: govBlue),
      ),
      body: Stack(
        children: [
          // fondos decorativos
          Positioned(
            top: -80,
            left: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x110b3b60),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            right: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x220b3b60),
              ),
            ),
          ),

          // contenido principal
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  '¿Qué tipo de persona deseas registrar?',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: govBlue,
                      ),
                ),
              ),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
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
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Selecciona una opción para habilitar el botón “Continuar”.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.grey.shade700),
                ),
              ),
              const Spacer(),

              // BOTÓN CONTINUAR
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: selectedType != null ? _navigate : null,
                    icon: const Icon(Icons.arrow_forward_ios_rounded),
                    label: const Text(
                      'Continuar',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: govBlue,
                      disabledBackgroundColor: govBlue.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
