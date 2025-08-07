import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/alert_helper.dart';

class PhoneEditDialog {
  static void show(
    BuildContext context, {
    required String currentPhone,
    required Function(String) onPhoneUpdated,
  }) {
    final TextEditingController phoneController = TextEditingController();
    phoneController.text = currentPhone;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0b3b60).withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icono
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0b3b60).withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF0b3b60).withOpacity(0.2),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.phone,
                      color: Color(0xFF0b3b60),
                      size: 28,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Título
                  const Text(
                    "Editar Tel��fono",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0b3b60),
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Descripción
                  Text(
                    "Actualiza tu número de teléfono de contacto",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Campo de texto
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Número de teléfono',
                      hintText: 'Ej: 777 123 4567',
                      prefixIcon: const Icon(
                        Icons.phone,
                        color: Color(0xFF0b3b60),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF0b3b60),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Botones
                  Row(
                    children: [
                      // Cancelar
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            icon: Icon(Icons.close_rounded,
                                size: 18, color: Colors.grey[600]),
                            label: Text(
                              "Cancelar",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              side: BorderSide(
                                  color: Colors.grey[300]!, width: 1.5),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Guardar
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final newPhone = phoneController.text.trim();
                              if (newPhone.isEmpty) {
                                AlertHelper.showAlert(
                                  'Por favor ingresa un número de teléfono',
                                  type: AlertType.warning,
                                );
                                return;
                              }

                              if (newPhone.length < 10) {
                                AlertHelper.showAlert(
                                  'El número debe tener al menos 10 dígitos',
                                  type: AlertType.warning,
                                );
                                return;
                              }

                              Navigator.of(dialogContext).pop();
                              
                              // Mostrar loading
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (_) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );

                              try {
                                // Aquí iría la llamada al servicio para actualizar el teléfono
                                // await UserDataService.updatePhone(newPhone);
                                
                                // Simular delay de red
                                await Future.delayed(const Duration(seconds: 1));
                                
                                // Llamar al callback para actualizar el teléfono
                                onPhoneUpdated(newPhone);

                                Navigator.of(context).pop(); // Cerrar loading
                                AlertHelper.showAlert(
                                  'Teléfono actualizado correctamente',
                                  type: AlertType.success,
                                );
                              } catch (e) {
                                Navigator.of(context).pop(); // Cerrar loading
                                AlertHelper.showAlert(
                                  'Error al actualizar el teléfono: $e',
                                  type: AlertType.error,
                                );
                              }
                            },
                            icon: const Icon(Icons.save,
                                size: 18, color: Colors.white),
                            label: const Text(
                              "Guardar",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0b3b60),
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
            ),
          ),
        );
      },
    );
  }
}