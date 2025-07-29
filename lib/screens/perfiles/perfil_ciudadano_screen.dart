// screens/perfiles/perfil_ciudadano_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/usuario_cus.dart';
import '../../services/user_data_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/overflow_safe_widget.dart';

class PerfilCiudadanoScreen extends StatefulWidget {
  const PerfilCiudadanoScreen({super.key});

  @override
  State<PerfilCiudadanoScreen> createState() => _PerfilCiudadanoScreenState();
}

class _PerfilCiudadanoScreenState extends State<PerfilCiudadanoScreen> {
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
    'civil': 'assets/Estado Civil.png',
    'occupation': 'assets/Ocupacion.png',
    'birth_certificate': 'assets/Acta_nacimiento.png',
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
          _error = 'No se pudo obtener la información del ciudadano.';
          _isLoading = false;
        });
        return;
      }

      // Verificar que sea un ciudadano
      if (user.tipoPerfil != TipoPerfilCUS.ciudadano) {
        setState(() {
          _error = 'Este perfil es solo para ciudadanos.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        usuario = user;
        _isLoading = false;
      });
      
      // DIAGNÓSTICO: Verificar fecha de nacimiento
      print('[PerfilCiudadano] 🎂 Fecha de nacimiento en usuario: ${user.fechaNacimiento}');
    } catch (e) {
      setState(() {
        _error = 'Error al obtener datos del ciudadano: ${e.toString()}';
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

  String _getNombreCompleto() {
    if (usuario == null) return 'Sin nombre';
    
    // Priorizar nombreCompleto si existe
    if (usuario!.nombreCompleto != null && usuario!.nombreCompleto!.isNotEmpty) {
      return usuario!.nombreCompleto!;
    }
    
    // Si no hay nombreCompleto, usar nombre
    if (usuario!.nombre.isNotEmpty && usuario!.nombre != 'Usuario Sin Nombre') {
      return usuario!.nombre;
    }
    
    return 'Sin nombre completo';
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

  String _getIdGeneral() {
    if (usuario == null) return '';

    // Prioridad 1: idCiudadano
    if (usuario!.idCiudadano != null && usuario!.idCiudadano!.isNotEmpty) {
      return usuario!.idCiudadano!;
    }

    return 'Sin ID General';
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
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Column(
                                children: [
                                  const SizedBox(height: 75),

                                  // Información Personal del Ciudadano
                                  _buildSection(
                                    title: 'Información Personal',
                                    iconPath: imagenesIconos['person']!,
                                    children: [
                                      // Nombre Completo
                                      _buildInfoCard(
                                        'Nombre Completo',
                                        _getNombreCompleto(),
                                        imagenesIconos['person']!,
                                        Icons.person,
                                      ),
                                      if (usuario!.folio != null &&
                                          usuario!.folio!.isNotEmpty)
                                        _buildInfoCard(
                                          'Folio',
                                          _getDisplayValue(
                                              usuario!.folio, 'Sin folio'),
                                          imagenesIconos['badge']!,
                                          Icons.confirmation_number,
                                        ),
                                      if (_getIdGeneral().isNotEmpty &&
                                          _getIdGeneral() != 'Sin ID General')
                                        _buildInfoCard(
                                          'ID General',
                                          _getIdGeneral(),
                                          imagenesIconos['badge']!,
                                          Icons.person_pin,
                                        ),
                                      _buildInfoCard(
                                        'CURP',
                                        _getDisplayValue(
                                            usuario!.curp, 'Sin CURP'),
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
                                      if (usuario!.estadoCivil != null &&
                                          usuario!.estadoCivil!.isNotEmpty)
                                        _buildInfoCard(
                                          'Estado Civil',
                                          _getDisplayValue(usuario!.estadoCivil,
                                              'Sin estado civil'),
                                          imagenesIconos['civil']!,
                                          Icons.favorite,
                                        ),
                                      if (usuario!.ocupacion != null &&
                                          usuario!.ocupacion!.isNotEmpty)
                                        _buildInfoCard(
                                          'Ocupación',
                                          _getDisplayValue(usuario!.ocupacion,
                                              'Sin ocupación'),
                                          imagenesIconos['occupation']!,
                                          Icons.work_outline,
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
                                        _getDisplayValue(
                                            usuario!.email, 'Sin correo'),
                                        imagenesIconos['email']!,
                                        Icons.email,
                                      ),
                                      _buildInfoCard(
                                        'Teléfono',
                                        _getDisplayValue(
                                            usuario!.telefono, 'Sin teléfono'),
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
    final nombre = _getNombreCompleto();

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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Ciudadano',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Perfil de Ciudadano",
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
                            backgroundImage: _imageFile != null
                                ? FileImage(_imageFile!)
                                : null,
                            backgroundColor: Colors.grey[300],
                            child: _imageFile == null
                                ? const Icon(Icons.person,
                                    size: 48, color: govBlue)
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
                            child: const Icon(Icons.camera_alt,
                                size: 18, color: govBlue),
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
            errorBuilder: (_, __, ___) =>
                Icon(fallbackIcon, size: 36, color: govBlue),
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
