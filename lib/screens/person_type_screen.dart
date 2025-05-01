import 'package:flutter/material.dart';

class PersonTypeScreen extends StatefulWidget {
  const PersonTypeScreen({super.key});

  @override
  State<PersonTypeScreen> createState() => _PersonTypeScreenState();
}

class _PersonTypeScreenState extends State<PersonTypeScreen> {
  String? selectedType;

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
    bool isSelected = selectedType == type;
    const Color govBlue = Color(0xFF0b3b60);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedType = type;
          });
          Future.delayed(const Duration(milliseconds: 180), _navigate);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
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
              Icon(
                icon,
                size: 50,
                color: isSelected ? Colors.white : govBlue,
              ),
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
    const Color govBlue = Color(0xFF0b3b60);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Paso 1: Tipo de Persona',
          style: TextStyle(color: govBlue, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: govBlue),
      ),
      body: Stack(
        children: [
          // Fondo decorativo minimalista con curvas
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
          // Contenido principal
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  '¿Qué tipo de persona deseas registrar?',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
              const SizedBox(height: 48),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Esta información nos permite ofrecerte un proceso adecuado para tu tipo de registro.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: govBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: selectedType != null ? _navigate : null,
                    icon: const Icon(Icons.arrow_forward_ios_rounded),
                    label: const Text(
                      'Continuar',
                      style: TextStyle(fontWeight: FontWeight.bold),
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
