import 'package:cus_movil/screens/moral_screens/moral_contact_screen.dart';
import 'package:cus_movil/screens/person_screens/contact_data_screen.dart';
import 'package:cus_movil/screens/work_screens/work_contact_screen.dart';
import 'package:flutter/material.dart';

class PerfilUsuarioScreen extends StatelessWidget {
  final Map<String, dynamic> userData;

  const PerfilUsuarioScreen({
    super.key,
    required this.userData,
  });

  // Muestra el widget correspondiente al tipo de usuario
  Widget _buildPerfilPreview(String tipo) {
    switch (tipo) {
      case 'moral':
        return ContactMoralScreen(
          userData: userData,
          modoPerfil: true,
        );
      case 'trabajador':
        return ContactWorkScreen(
          userData: userData,
          modoPerfil: true,
        );
      case 'fisica':
      default:
        return ContactDataScreen(
          userData: userData,
          modoPerfil: true,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final nombre = userData['nombre'] ?? 'Nombre no disponible';
    final correo = userData['correo'] ?? 'Correo no disponible';
    final telefono = userData['telefono'] ?? 'Teléfono no disponible';
    final tipo = userData['tipo'] ?? 'fisica';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        backgroundColor: const Color(0xFF0B3B60),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Icon(Icons.account_circle, size: 100, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Text('Nombre: $nombre',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('Correo: $correo', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            Text('Teléfono: $telefono', style: const TextStyle(fontSize: 16)),
            const Divider(height: 40),
            _buildPerfilPreview(tipo),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/auth');
                },
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesión'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B3B60),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
