// DEBUG VERSION - Vista previa con logs detallados

import 'package:flutter/material.dart';
import '../../widgets/steap_header.dart';
import '../../widgets/navigation_buttons.dart';

class PreviewWorkScreenDebug extends StatelessWidget {
  static const govBlue = Color(0xFF0B3B60);

  const PreviewWorkScreenDebug({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> datosFinales =
        ModalRoute.of(context)!.settings.arguments as List<String>;

    // LOGS DETALLADOS
    debugPrint('=== PREVIEW DEBUG - ANÁLISIS COMPLETO ===');
    debugPrint('Total elementos recibidos: ${datosFinales.length}');
    
    for (int i = 0; i < datosFinales.length; i++) {
      String expectedLabel = '';
      switch (i) {
        case 0: expectedLabel = 'NÓMINA'; break;
        case 1: expectedLabel = 'PUESTO'; break;
        case 2: expectedLabel = 'DEPARTAMENTO'; break;
        case 3: expectedLabel = 'CURP'; break;
        case 4: expectedLabel = 'CURP_VERIFY'; break;
        case 5: expectedLabel = 'NOMBRE'; break;
        case 6: expectedLabel = 'APELLIDO_P'; break;
        case 7: expectedLabel = 'APELLIDO_M'; break;
        case 8: expectedLabel = 'FECHA_NAC'; break;
        case 9: expectedLabel = 'GÉNERO'; break;
        case 10: expectedLabel = 'ESTADO_NAC'; break;
        case 11: expectedLabel = 'PASSWORD'; break;
        case 12: expectedLabel = 'CONFIRM_PASS'; break;
        case 13: expectedLabel = 'CP'; break;
        case 14: expectedLabel = 'COLONIA'; break;
        case 15: expectedLabel = 'CALLE'; break;
        case 16: expectedLabel = 'NUM_EXT'; break;
        case 17: expectedLabel = 'NUM_INT'; break;
        case 18: expectedLabel = 'LATITUD'; break;
        case 19: expectedLabel = 'LONGITUD'; break;
        case 20: expectedLabel = 'EMAIL'; break;
        case 21: expectedLabel = 'EMAIL_VERIFY'; break;
        case 22: expectedLabel = 'TELÉFONO'; break;
        case 23: expectedLabel = 'PHONE_VERIFY'; break;
        case 24: expectedLabel = 'SMS_CODE'; break;
        default: expectedLabel = 'EXTRA_$i'; break;
      }
      debugPrint('[$i] $expectedLabel: "${datosFinales[i]}"');
    }
    debugPrint('=========================================');

    return Scaffold(
      backgroundColor: const Color(0xFFF1F4F8),
      body: Column(
        children: [
          const PasoHeader(
            pasoActual: 6,
            tituloPaso: 'Vista Previa DEBUG',
            tituloSiguiente: 'Confirmación',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mostrar análisis visual
                  Card(
                    color: Colors.red[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ANÁLISIS DE DATOS (${datosFinales.length} elementos)',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...datosFinales.asMap().entries.map((entry) {
                            String expectedLabel = '';
                            Color bgColor = Colors.white;
                            
                            switch (entry.key) {
                              case 0: expectedLabel = 'NÓMINA'; bgColor = Colors.blue[100]!; break;
                              case 1: expectedLabel = 'PUESTO'; bgColor = Colors.blue[100]!; break;
                              case 2: expectedLabel = 'DEPARTAMENTO'; bgColor = Colors.blue[100]!; break;
                              case 3: expectedLabel = 'CURP'; bgColor = Colors.green[100]!; break;
                              case 4: expectedLabel = 'CURP_VERIFY'; bgColor = Colors.grey[200]!; break;
                              case 5: expectedLabel = 'NOMBRE'; bgColor = Colors.green[100]!; break;
                              case 6: expectedLabel = 'APELLIDO_P'; bgColor = Colors.green[100]!; break;
                              case 7: expectedLabel = 'APELLIDO_M'; bgColor = Colors.green[100]!; break;
                              case 8: expectedLabel = 'FECHA_NAC'; bgColor = Colors.green[100]!; break;
                              case 9: expectedLabel = 'GÉNERO'; bgColor = Colors.green[100]!; break;
                              case 10: expectedLabel = 'ESTADO_NAC'; bgColor = Colors.green[100]!; break;
                              case 11: expectedLabel = 'PASSWORD'; bgColor = Colors.grey[200]!; break;
                              case 12: expectedLabel = 'CONFIRM_PASS'; bgColor = Colors.grey[200]!; break;
                              case 13: expectedLabel = 'CP'; bgColor = Colors.orange[100]!; break;
                              case 14: expectedLabel = 'COLONIA'; bgColor = Colors.orange[100]!; break;
                              case 15: expectedLabel = 'CALLE'; bgColor = Colors.orange[100]!; break;
                              case 16: expectedLabel = 'NUM_EXT'; bgColor = Colors.orange[100]!; break;
                              case 17: expectedLabel = 'NUM_INT'; bgColor = Colors.orange[100]!; break;
                              case 18: expectedLabel = 'LATITUD'; bgColor = Colors.orange[100]!; break;
                              case 19: expectedLabel = 'LONGITUD'; bgColor = Colors.orange[100]!; break;
                              case 20: expectedLabel = 'EMAIL'; bgColor = Colors.purple[100]!; break;
                              case 21: expectedLabel = 'EMAIL_VERIFY'; bgColor = Colors.grey[200]!; break;
                              case 22: expectedLabel = 'TELÉFONO'; bgColor = Colors.purple[100]!; break;
                              case 23: expectedLabel = 'PHONE_VERIFY'; bgColor = Colors.grey[200]!; break;
                              case 24: expectedLabel = 'SMS_CODE'; bgColor = Colors.grey[200]!; break;
                              default: expectedLabel = 'EXTRA_${entry.key}'; bgColor = Colors.red[200]!; break;
                            }
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 4),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.grey),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 40,
                                    child: Text(
                                      '[${entry.key}]',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 120,
                                    child: Text(
                                      expectedLabel,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '"${entry.value}"',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          
                          const SizedBox(height: 16),
                          const Text(
                            'COLORES:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Text('🔵 Azul = Datos del Trabajador'),
                          const Text('🟢 Verde = Información Personal'),
                          const Text('🟠 Naranja = Dirección'),
                          const Text('🟣 Morado = Contacto'),
                          const Text('⚪ Gris = Campos de verificación'),
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