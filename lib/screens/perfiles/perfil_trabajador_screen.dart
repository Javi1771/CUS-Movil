// screens/perfiles/perfil_trabajador_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/usuario_cus.dart';
import '../../services/user_data_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/overflow_safe_widget.dart';

class PerfilTrabajadorScreen extends StatefulWidget {
  const PerfilTrabajadorScreen({super.key});

  @override
  State<PerfilTrabajadorScreen> createState() => _PerfilTrabajadorScreenState();
}

class _PerfilTrabajadorScreenState extends State<PerfilTrabajadorScreen> {
  UsuarioCUS? usuario;
  File? _imageFile;
  bool _isLoading = true;
  String? _error;

  final Map<String, String> imagenesIconos = {
    'person': 'assets/informacion personal.png',
    'badge': 'assets/Curp.png',
    'cake': 'assets/Fecha de Nacimiento.png',
    'flag': 'assets/Nacionalidad.png',
    'contact': 'assets/Informacion de contacto.png',
    'email': 'assets/Correo Electronico.png',
    'phone': 'assets/telefono.png',
    'home': 'assets/Direccion.png',
    'work': 'assets/informacion laboral.png',
    'department': 'assets/Departamento.png',
    'position': 'assets/Puesto.png',
  };

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
        throw Exception('La información del usuario es nula.');
      }

      // ******** BLINDAJE PRINCIPAL ********
      // Verifica explícitamente que el perfil sea de un TRABAJADOR.
      if (user.tipoPerfil != TipoPerfilCUS.trabajador) {
        throw Exception(
            'Error de Acceso: Se esperaba un perfil de Trabajador, pero se recibió un perfil de tipo "${user.tipoPerfil.toString().split('.').last}". Este error es intencional para prevenir la carga de datos incorrectos.');
      }

      setState(() {
        usuario = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al Cargar Perfil: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (picked != null) {
        setState(() {
          _imageFile = File(picked.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error al seleccionar imagen: ${e.toString()}')),
        );
      }
    }
  }

  String _getDisplayValue(dynamic value, {String defaultValue = 'No especificado'}) {
    if (value == null || (value is String && value.trim().isEmpty)) {
      return defaultValue;
    }
    return value.toString();
  }

  String _buildDireccion() {
    if (usuario == null) return 'No especificada';
    final parts = [
      usuario!.calle,
      usuario!.asentamiento,
      if (usuario!.codigoPostal?.isNotEmpty == true)
        'C.P. ${usuario!.codigoPostal}'
    ].where((p) => p != null && p.isNotEmpty).toList();
    return parts.isEmpty ? 'No especificada' : parts.join(', ');
  }

  String _getIdGeneral() {
    if (usuario == null) return 'Sin ID';
    if (usuario!.nomina != null && usuario!.nomina!.isNotEmpty)
      return usuario!.nomina!;
    if (usuario!.usuarioId != null && usuario!.usuarioId!.isNotEmpty)
      return usuario!.usuarioId!;
    if (usuario!.folio != null && usuario!.folio!.isNotEmpty)
      return usuario!.folio!;
    return 'Sin ID';
  }

  @override
  Widget build(BuildContext context) {
    const bgGray = Color(0xFFF5F7FA);

    return Scaffold(
      backgroundColor: bgGray,
      body: OverflowSafeWidget(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildErrorWidget(_error!)
                : usuario == null
                    ? _buildErrorWidget(
                        'No hay datos del trabajador para mostrar.')
                    : SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildBannerHeader(usuario!),
                            const SizedBox(height: 75),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Column(
                                children: [
                                  // --- SECCIONES ESPECÍFICAS DE TRABAJADOR ---
                                  _buildSection(
                                    title: 'Información Personal',
                                    iconPath: imagenesIconos['person']!,
                                    children: [
                                      _buildInfoCard(
                                          'ID General',
                                          _getIdGeneral(),
                                          imagenesIconos['badge']!,
                                          Icons.person_pin),
                                      _buildInfoCard(
                                          'Nómina',
                                          _getDisplayValue(usuario!.nomina),
                                          imagenesIconos['badge']!,
                                          Icons.badge),
                                      _buildInfoCard(
                                          'CURP',
                                          _getDisplayValue(usuario!.curp),
                                          imagenesIconos['badge']!,
                                          Icons.badge),
                                      _buildInfoCard(
                                          'Fecha de Nacimiento',
                                          _getDisplayValue(
                                              usuario!.fechaNacimiento),
                                          imagenesIconos['cake']!,
                                          Icons.cake),
                                      _buildInfoCard(
                                          'Nacionalidad',
                                          _getDisplayValue(
                                              usuario!.nacionalidadDisplay),
                                          imagenesIconos['flag']!,
                                          Icons.flag),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  
                                  // Información Laboral
                                  _buildSection(
                                    title: 'Información Laboral',
                                    iconPath: imagenesIconos['work']!,
                                    children: [
                                      _buildInfoCard(
                                          'Departamento',
                                          _getDisplayValue(usuario!.departamento),
                                          imagenesIconos['department']!,
                                          Icons.business),
                                      _buildInfoCard(
                                          'Puesto',
                                          _getDisplayValue(usuario!.puesto),
                                          imagenesIconos['position']!,
                                          Icons.work),
                                      _buildInfoCard(
                                          'Razón Social',
                                          _getDisplayValue(usuario!.razonSocial),
                                          imagenesIconos['work']!,
                                          Icons.business),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  
                                  // Información de Contacto
                                  _buildSection(
                                    title: 'Información de Contacto',
                                    iconPath: imagenesIconos['contact']!,
                                    children: [
                                      _buildInfoCard(
                                          'Correo Electrónico',
                                          _getDisplayValue(usuario!.email),
                                          imagenesIconos['email']!,
                                          Icons.email),
                                      _buildInfoCard(
                                          'Teléfono',
                                          _getDisplayValue(usuario!.telefono),
                                          imagenesIconos['phone']!,
                                          Icons.phone),
                                      _buildInfoCard(
                                          'Dirección',
                                          _buildDireccion(),
                                          imagenesIconos['home']!,
                                          Icons.home),
                                    ],
                                  ),
                                  const SizedBox(height: 40),
                                  _buildLogoutButton(context),
                                  const SizedBox(height: 50),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
      ),
    );
  }

  Widget _buildBannerHeader(UsuarioCUS userData) {
    const govBlue = Color(0xFF0B3B60);
    final nombre = _getDisplayValue(userData.nombreCompleto ?? userData.nombre,
        defaultValue: "Trabajador");

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: govBlue,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(50),
          bottomRight: Radius.circular(50),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 95),
            child: Column(
              children: [
                Text(
                  nombre,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20)),
                  child: const Text(
                    'Trabajador',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: -65,
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: govBlue, width: 4),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 10)
                  ],
                ),
                child: CircleAvatar(
                  radius: 61,
                  backgroundColor: Colors.grey[200],
                  backgroundImage:
                      _imageFile != null ? FileImage(_imageFile!) : null,
                  child: _imageFile == null
                      ? Icon(Icons.work,
                          size: 70, color: govBlue.withOpacity(0.8))
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
      {required String title,
      required String iconPath,
      required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Image.asset(iconPath,
                width: 28,
                height: 28,
                errorBuilder: (_, __, ___) => const Icon(Icons.info, size: 28)),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B))),
          ],
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildInfoCard(
      String label, String value, String imagePath, IconData fallbackIcon) {
    const govBlue = Color(0xFF0B3B60);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            imagePath,
            width: 40,
            height: 40,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                Icon(fallbackIcon, size: 36, color: govBlue),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54)),
                const SizedBox(height: 4),
                Text(value,
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String errorMsg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            const Text('Ocurrió un Problema',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(errorMsg,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[700])),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchUserData,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _showLogoutDialog(context),
      icon: const Icon(Icons.logout),
      label: const Text("Cerrar sesión"),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        elevation: 2,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text("Cerrar sesión"),
          content: const Text("¿Estás seguro de que deseas cerrar sesión?"),
          actions: [
            TextButton(
              child: const Text("Cancelar"),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            ElevatedButton(
              child: const Text("Cerrar sesión"),
              onPressed: () async {
                Navigator.of(ctx).pop();
                await AuthService('temp').logout();
                if (mounted) {
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/auth', (route) => false);
                }
              },
            ),
          ],
        );
      },
    );
  }
}