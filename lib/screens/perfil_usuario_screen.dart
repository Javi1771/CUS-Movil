// screens/perfil_usuario_screen.dart

import 'package:flutter/material.dart';
import '../models/usuario_cus.dart';
import '../services/user_data_service.dart';
import 'perfiles/perfil_ciudadano_screen.dart';
import 'perfiles/perfil_trabajador_screen.dart';
import 'perfiles/perfil_organizacion_screen.dart';

class PerfilUsuarioScreen extends StatefulWidget {
  const PerfilUsuarioScreen({super.key});

  @override
  State<PerfilUsuarioScreen> createState() => _PerfilUsuarioScreenState();
}

class _PerfilUsuarioScreenState extends State<PerfilUsuarioScreen> {
  UsuarioCUS? usuario;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = await UserDataService.getUserData();
      if (user == null) {
        setState(() {
          _error = 'No se pudo obtener la información del usuario.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        usuario = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al obtener datos del usuario: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Widget _buildProfileBasedOnType() {
    if (usuario == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    // Determinar qué perfil mostrar basado en el tipo de usuario
    switch (usuario!.tipoPerfil) {
      case TipoPerfilCUS.ciudadano:
        return const PerfilCiudadanoScreen();

      case TipoPerfilCUS.trabajador:
        return const PerfilTrabajadorScreen();

      case TipoPerfilCUS.personaMoral:
        return const PerfilOrganizacionScreen();

      case TipoPerfilCUS.usuario:
      default:
        // Para usuarios genéricos, mostrar perfil de ciudadano por defecto
        return const PerfilCiudadanoScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: _isLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : (_error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Color.fromARGB(255, 0, 0, 0),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: const TextStyle(
                            color: Color.fromARGB(255, 5, 5, 5),
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _fetchUserData,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0B3B60),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : _buildProfileBasedOnType()),
    );
  }
}
