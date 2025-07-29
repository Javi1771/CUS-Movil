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
        setState(() {
          _error = 'No se pudo obtener la información del trabajador.';
          _isLoading = false;
        });
        return;
      }

      // Verificar que sea un trabajador
      if (user.tipoPerfil != TipoPerfilCUS.trabajador) {
        setState(() {
          _error = 'Este perfil es solo para trabajadores.';
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
        _error = 'Error al obtener datos del trabajador: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() {
          _imageFile = File(picked.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar imagen: ${e.toString()}')),
      );
    }
  }

  String _getDisplayValue(dynamic value, String defaultValue) {
    if (value == null || (value is String && value.isEmpty)) {
      return defaultValue;
    }
    return value.toString();
  }

  String _buildDireccion() {
    if (usuario == null) return 'Sin dirección';

    final partes = <String>[];
    if (usuario!.calle?.isNotEmpty == true) partes.add(usuario!.calle!);
    if (usuario!.asentamiento?.isNotEmpty == true) {
      partes.add(usuario!.asentamiento!);
    }
    if (usuario!.codigoPostal?.isNotEmpty == true) {
      partes.add('CP ${usuario!.codigoPostal!}');
    }

    return partes.isNotEmpty ? partes.join(', ') : 'Sin dirección';
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
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error!,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchUserData,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  )
                : usuario == null
                    ? const Center(child: Text('No hay datos para mostrar'))
                    : SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildBannerHeader(usuario!),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Column(
                                children: [
                                  const SizedBox(height: 75),
                                  
                                  // Información Personal del Trabajador
                                  _buildSection(
                                    title: 'Información Personal',
                                    iconPath: imagenesIconos['person']!,
                                    children: [
                                      _buildInfoCard(
                                        'Nómina',
                                        _getDisplayValue(usuario!.nomina, 'Sin nómina'),
                                        imagenesIconos['badge']!,
                                        Icons.badge,
                                      ),
                                      _buildInfoCard(
                                        'CURP',
                                        _getDisplayValue(usuario!.curp, 'Sin CURP'),
                                        imagenesIconos['badge']!,
                                        Icons.badge,
                                      ),
                                      _buildInfoCard(
                                        'Fecha de Nacimiento',
                                        _getDisplayValue(
                                          usuario!.fechaNacimiento,
                                          'Sin fecha de nacimiento',
                                        ),
                                        imagenesIconos['cake']!,
                                        Icons.cake,
                                      ),
                                      _buildInfoCard(
                                        'Nacionalidad',
                                        _getDisplayValue(
                                          usuario!.nacionalidadDisplay,
                                          'Sin nacionalidad',
                                        ),
                                        imagenesIconos['flag']!,
                                        Icons.flag,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  
                                  // Información Laboral
                                  _buildSection(
                                    title: 'Información Laboral',
                                    iconPath: imagenesIconos['work']!,
                                    children: [
                                      _buildInfoCard(
                                        'Departamento',
                                        _getDisplayValue(usuario!.departamento, 'Sin departamento'),
                                        imagenesIconos['department']!,
                                        Icons.business,
                                      ),
                                      _buildInfoCard(
                                        'Puesto',
                                        _getDisplayValue(usuario!.puesto, 'Sin puesto'),
                                        imagenesIconos['position']!,
                                        Icons.work,
                                      ),
                                      _buildInfoCard(
                                        'Razón Social',
                                        _getDisplayValue(usuario!.razonSocial, 'Sin razón social'),
                                        imagenesIconos['work']!,
                                        Icons.business,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  
                                  // Información de Contacto
                                  _buildSection(
                                    title: 'Información de Contacto',
                                    iconPath: imagenesIconos['contact']!,
                                    children: [
                                      _buildInfoCard(
                                        'Correo Electrónico',
                                        _getDisplayValue(usuario!.email, 'Sin correo'),
                                        imagenesIconos['email']!,
                                        Icons.email,
                                      ),
                                      _buildInfoCard(
                                        'Teléfono',
                                        _getDisplayValue(usuario!.telefono, 'Sin teléfono'),
                                        imagenesIconos['phone']!,
                                        Icons.phone,
                                      ),
                                      _buildInfoCard(
                                        'Dirección',
                                        _buildDireccion(),
                                        imagenesIconos['home']!,
                                        Icons.home,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 30),
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
    final nombre = userData.nombreCompleto ?? userData.nombre;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF0B3B60),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(50),
          bottomRight: Radius.circular(50),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(0, 50, 0, 50),
            child: Column(
              children: [
                const SizedBox(height: 0),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    nombre,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.10,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Trabajador - Nómina: ${usuario!.nomina ?? "Sin nómina"}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Perfil de Trabajador",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
          Positioned(
            bottom: -65,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(width: 4, color: govBlue),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 46,
                            backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
                            backgroundColor: Colors.grey[300],
                            child: _imageFile == null
                                ? const Icon(Icons.work, size: 48, color: govBlue)
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            padding: const EdgeInsets.all(6),
                            child: const Icon(Icons.camera_alt, size: 18, color: govBlue),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String iconPath,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Image.asset(iconPath, width: 28, height: 28),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildInfoCard(
    String label,
    String value,
    String imagePath,
    IconData fallbackIcon,
  ) {
    const govBlue = Color(0xFF0B3B60);
    const textGray = Color(0xFF475569);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
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
            errorBuilder: (_, __, ___) => Icon(fallbackIcon, size: 36, color: govBlue),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: textGray,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
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
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Cerrar sesión"),
          content: const Text("¿Estás seguro de que deseas cerrar sesión?"),
          actions: [
            TextButton(
              child: const Text("Cancelar"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text("Cerrar sesión"),
              onPressed: () async {
                Navigator.of(context).pop();
                await AuthService('temp').logout();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/auth');
                }
              },
            ),
          ],
        );
      },
    );
  }
}