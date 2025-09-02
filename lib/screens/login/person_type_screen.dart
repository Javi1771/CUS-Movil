// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import '../../routes/slide_up_route.dart';
import '../moral_screens/moral_data_screen.dart';
import '../person_screens/fisica_data_screen.dart';
import '../work_screens/work_data_screen.dart';
import '../../widgets/steap_header.dart';

const Color govBlue = Color(0xFF0B3B60);

class PersonTypeScreen extends StatefulWidget {
  const PersonTypeScreen({super.key});

  @override
  State<PersonTypeScreen> createState() => _PersonTypeScreenState();
}

class _PersonTypeScreenState extends State<PersonTypeScreen> {
  String? selectedType;

  // Navegación protegida
  void _navigate() {
    if (selectedType == null) return;

    final nextPage = switch (selectedType) {
      'fisica' => const FisicaDataScreen(),
      'moral' => const MoralDataScreen(),
      'trabajador' => const WorkDataScreen(),
      _ => null,
    };

    if (nextPage != null) {
      Navigator.of(context).push(SlideUpRoute(page: nextPage));
    }
  }

  // Diálogo separado para claridad
  void _showInfoAndSelect({
    required String type,
    required String title,
    required String content,
    required IconData icon,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _InfoDialog(
        title: title,
        content: content,
        icon: icon,
        onSelect: () {
          setState(() => selectedType = type);
          Navigator.of(ctx).pop();
        },
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
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _showInfoAndSelect(
        type: type,
        title: title,
        content: infoText,
        icon: icon,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
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
                              'Una persona física es cualquier individuo con derechos y obligaciones.',
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
                              'Una persona moral es una entidad legal conformada por una o más personas físicas.',
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
                              'Un trabajador es una persona física que presta un servicio personal subordinado.',
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
                    Center(
                      child: SizedBox(
                        width: 350, //* Ancho aumentado de 300 a 350
                        height: 55, //* Altura aumentada de 45 a 55 (cerca del original de 60)
                        child: ElevatedButton(
                          onPressed: _navigate,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selectedType != null
                                ? govBlue
                                : govBlue.withOpacity(0.4),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), //* Padding más compacto
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Continuar',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 8), //* Espacio entre texto e icono
                              Icon(
                                selectedType != null 
                                    ? Icons.arrow_downward 
                                    : Icons.arrow_forward_rounded, 
                                size: 24, //* Tamaño del icono aumentado de 20 a 24
                              ), //* Flecha cambia según el estado
                            ],
                          ),
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

// Widget separado para el diálogo
class _InfoDialog extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;
  final VoidCallback onSelect;

  const _InfoDialog({
    required this.title,
    required this.content,
    required this.icon,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: govBlue,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
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
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
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
                    side: const BorderSide(color: govBlue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
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
                  onPressed: onSelect,
                  child: const Text('Seleccionar'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
