// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../widgets/steap_header.dart';
import '../widgets/navigation_buttons.dart';

class PreviewScreen extends StatelessWidget {
  static const govBlue = Color(0xFF0B3B60);

  const PreviewScreen({super.key});

  Widget _sectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: govBlue, size: 28),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: govBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(2, 2),
              blurRadius: 4,
            ),
          ],
        ),
        child: ListTile(
          leading: Icon(icon, color: govBlue),
          title: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            value.isNotEmpty ? value : '—',
            style: const TextStyle(color: Colors.black87),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    //* 🔹 Recibimos el arreglo completo desde la navegación
    final List<String> datosFinales =
        ModalRoute.of(context)!.settings.arguments as List<String>;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F4F8),
      body: Column(
        children: [
          const PasoHeader(
            pasoActual: 6,
            tituloPaso: 'Vista Previa',
            tituloSiguiente: 'Confirmación',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //* 🔹 Representante Legal
                  _sectionHeader(Icons.folder_shared, 'Persona Física'),
                  Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    shadowColor: govBlue.withOpacity(0.2),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildItem(
                              Icons.credit_card, 'CURP', datosFinales[0]),
                          _buildItem(
                              Icons.account_circle, 'Nombre', datosFinales[2]),
                          _buildItem(
                              Icons.badge, 'Apellido Paterno', datosFinales[3]),
                          _buildItem(
                              Icons.badge, 'Apellido Materno', datosFinales[4]),
                          _buildItem(Icons.cake, 'Fecha de Nacimiento',
                              datosFinales[5]),
                          _buildItem(
                              Icons.transgender, 'Género', datosFinales[6]),
                          _buildItem(
                              Icons.map, 'Estado Nacimiento', datosFinales[7]),
                        ],
                      ),
                    ),
                  ),

                  //* 🔹 Dirección
                  _sectionHeader(Icons.home, 'Dirección del Ciudadano'),
                  Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    shadowColor: govBlue.withOpacity(0.2),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildItem(Icons.markunread_mailbox, 'Código Postal',
                              datosFinales[10]),
                          _buildItem(
                              Icons.location_city, 'Colonia', datosFinales[11]),
                          _buildItem(
                              Icons.streetview, 'Calle', datosFinales[12]),
                          _buildItem(Icons.location_on, 'Número Ext.',
                              datosFinales[13]),
                          _buildItem(
                              Icons.pin_drop, 'Número Int.', datosFinales[14]),
                          // _buildItem(Icons.location_on, 'Latitud', datosFinales[15]),
                          // _buildItem(Icons.location_on, 'Longitud', datosFinales[16]),
                        ],
                      ),
                    ),
                  ),

                  //* 🔹 Contacto
                  _sectionHeader(Icons.contact_mail, 'Contacto del Ciudadano'),
                  Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    shadowColor: govBlue.withOpacity(0.2),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildItem(Icons.email, 'Correo', datosFinales[17]),
                          _buildItem(Icons.phone, 'Teléfono', datosFinales[19]),
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
      bottomNavigationBar: NavigationButtons(
        enabled: true,
        onBack: () => Navigator.pop(context),
        onNext: () => Navigator.pushNamed(context, '/confirm-data',
            arguments: datosFinales),
      ),
    );
  }
}
