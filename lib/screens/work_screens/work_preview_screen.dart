// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../widgets/steap_header.dart';
import '../../widgets/navigation_buttons.dart';

class PreviewWorkScreen extends StatelessWidget {
  static const govBlue = Color(0xFF0B3B60);

  const PreviewWorkScreen({super.key});

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
    //? 🔹 Recibimos el arreglo completo desde la navegación
    final List<String> datosFinales =
        ModalRoute.of(context)!.settings.arguments as List<String>;

    // Debug simplificado en consola
    debugPrint('=== DATOS FINALES EN PREVIEW ===');
    debugPrint('Total: ${datosFinales.length}');
    for (int i = 0; i < datosFinales.length && i < 25; i++) {
      String label = '';
      switch (i) {
        case 0: label = 'NÓMINA'; break;
        case 1: label = 'PUESTO'; break;
        case 2: label = 'DEPARTAMENTO'; break;
        case 3: label = 'CURP'; break;
        case 4: label = 'CURP_VERIFY'; break;
        case 5: label = 'NOMBRE'; break;
        case 6: label = 'APELLIDO_P'; break;
        case 7: label = 'APELLIDO_M'; break;
        case 8: label = 'FECHA_NAC'; break;
        case 9: label = 'GÉNERO'; break;
        case 10: label = 'ESTADO_NAC'; break;
        case 11: label = 'PASSWORD'; break;
        case 12: label = 'CONFIRM_PASS'; break;
        case 13: label = 'CP'; break;
        case 14: label = 'COLONIA'; break;
        case 15: label = 'CALLE'; break;
        case 16: label = 'NUM_EXT'; break;
        case 17: label = 'NUM_INT'; break;
        case 18: label = 'LATITUD'; break;
        case 19: label = 'LONGITUD'; break;
        case 20: label = 'EMAIL'; break;
        case 21: label = 'EMAIL_VERIFY'; break;
        case 22: label = 'TELÉFONO'; break;
        case 23: label = 'PHONE_VERIFY'; break;
        case 24: label = 'SMS_CODE'; break;
      }
      debugPrint('[$i] $label: "${datosFinales[i]}"');
    }
    debugPrint('================================');

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
                  //* 🔹 Datos del Trabajador
                  _sectionHeader(Icons.work, 'Datos del Trabajador'),
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
                            Icons.badge,
                            'Nómina',
                            datosFinales.isNotEmpty ? datosFinales[0] : '—',
                          ),
                          _buildItem(
                            Icons.work,
                            'Puesto',
                            datosFinales.length > 1 ? datosFinales[1] : '—',
                          ),
                          _buildItem(
                            Icons.apartment,
                            'Departamento',
                            datosFinales.length > 2 ? datosFinales[2] : '—',
                          ),
                        ],
                      ),
                    ),
                  ),

                  //* 🔹 Información Personal
                  _sectionHeader(Icons.person, 'Información Personal'),
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
                            Icons.credit_card,
                            'CURP',
                            datosFinales.length > 3 ? datosFinales[3] : '—',
                          ),
                          _buildItem(
                            Icons.account_circle,
                            'Nombre',
                            datosFinales.length > 5 ? datosFinales[5] : '—',
                          ),
                          _buildItem(
                            Icons.person,
                            'Apellido Paterno',
                            datosFinales.length > 6 ? datosFinales[6] : '—',
                          ),
                          _buildItem(
                            Icons.person_outline,
                            'Apellido Materno',
                            datosFinales.length > 7 ? datosFinales[7] : '—',
                          ),
                          _buildItem(
                            Icons.cake,
                            'Fecha de Nacimiento',
                            datosFinales.length > 8 ? datosFinales[8] : '—',
                          ),
                          _buildItem(
                            Icons.wc,
                            'Género',
                            datosFinales.length > 9 ? datosFinales[9] : '—',
                          ),
                          _buildItem(
                            Icons.map,
                            'Estado de Nacimiento',
                            datosFinales.length > 10 ? datosFinales[10] : '—',
                          ),
                        ],
                      ),
                    ),
                  ),

                  //* 🔹 Dirección
                  _sectionHeader(Icons.home, 'Dirección'),
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
                            Icons.markunread_mailbox,
                            'Código Postal',
                            datosFinales.length > 13 ? datosFinales[13] : '—',
                          ),
                          _buildItem(
                            Icons.location_city,
                            'Colonia',
                            datosFinales.length > 14 ? datosFinales[14] : '—',
                          ),
                          _buildItem(
                            Icons.streetview,
                            'Calle',
                            datosFinales.length > 15 ? datosFinales[15] : '—',
                          ),
                          _buildItem(
                            Icons.location_on,
                            'Número Exterior',
                            datosFinales.length > 16 ? datosFinales[16] : '—',
                          ),
                          _buildItem(
                            Icons.pin_drop,
                            'Número Interior',
                            datosFinales.length > 17 ? datosFinales[17] : '—',
                          ),
                        ],
                      ),
                    ),
                  ),

                  //* 🔹 Contacto
                  _sectionHeader(Icons.contact_mail, 'Información de Contacto'),
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
                            Icons.email,
                            'Correo Electrónico',
                            datosFinales.length > 20 ? datosFinales[20] : '—',
                          ),
                          _buildItem(
                            Icons.phone_android,
                            'Teléfono',
                            datosFinales.length > 22 ? datosFinales[22] : '—',
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
      bottomNavigationBar: NavigationButtons(
        enabled: true,
        onBack: () => Navigator.pop(context),
        onNext: () => Navigator.pushNamed(
          context,
          '/work-confirmation',
          arguments: datosFinales,
        ),
      ),
    );
  }
}