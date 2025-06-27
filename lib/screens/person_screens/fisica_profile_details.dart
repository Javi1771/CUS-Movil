// lib/screens/person_screens/fisica_profile_details.dart

import 'package:flutter/material.dart';

class FisicaProfileDetails extends StatelessWidget {
  final Map<String, dynamic> userData;

  const FisicaProfileDetails({
    super.key,
    required this.userData,
  });

  // Un widget reutilizable para mostrar cada línea de información
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF0B3B60)),
        title: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          value.isNotEmpty ? value : 'No proporcionado',
          style: const TextStyle(fontSize: 15, color: Colors.black87),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Usamos una Card para agrupar visualmente la información
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detalles de Persona Física',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0B3B60),
              ),
            ),
            const Divider(height: 24, thickness: 1),
            // Mostramos los datos específicos que tenemos
            _buildInfoRow(
              Icons.credit_card,
              'CURP',
              userData['curp'] ?? '',
            ),
            _buildInfoRow(
              Icons.cake,
              'Fecha de Nacimiento',
              userData['fechaNacimiento'] ?? userData['fecha_nacimiento'] ?? '',
            ),
            _buildInfoRow(
              Icons.favorite,
              'Estado Civil',
              userData['estadoCivil'] ?? userData['estado_civil'] ?? '',
            ),
            _buildInfoRow(
              Icons.flag,
              'Nacionalidad',
              userData['nacionalidad'] ?? 'Mexicana',
            ),
            _buildInfoRow(
              Icons.work,
              'Ocupación',
              userData['ocupacion'] ?? userData['trabajo'] ?? userData['profesion'] ?? '',
            ),
            _buildInfoRow(
              Icons.business,
              'Razón Social/Empresa',
              userData['razonSocial'] ?? userData['razon_social'] ?? userData['empresa'] ?? '',
            ),
          ],
        ),
      ),
    );
  }
}
