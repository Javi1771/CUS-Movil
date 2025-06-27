import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cus_movil/models/usuario_cus.dart';
import 'package:cus_movil/services/user_data_service.dart';
import 'package:cus_movil/services/auth_service.dart';

class PerfilUsuarioScreen extends StatefulWidget {
  const PerfilUsuarioScreen({super.key});

  @override
  State<PerfilUsuarioScreen> createState() => _PerfilUsuarioScreenState();
}

class _PerfilUsuarioScreenState extends State<PerfilUsuarioScreen> {
  UsuarioCUS? usuario;
  File? _imageFile;
  bool _isLoading = true;
  String? _error;

  final Map<String, String> imagenesIconos = {
    'person': 'assets/informacion_personal.png',
    'badge': 'assets/curp_icon.png',
    'cake': 'assets/fecha_nacimiento.png',
    'flag': 'assets/nacionalidad.png',
    'contact': 'assets/informacion_contacto.png',
    'email': 'assets/correo_electronico.png',
    'phone': 'assets/telefono.png',
    'home': 'assets/direccion.png',
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
        _error = 'Error al obtener datos: ${e.toString()}';
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
    if (usuario!.asentamiento?.isNotEmpty == true)
      partes.add(usuario!.asentamiento!);
    if (usuario!.codigoPostal?.isNotEmpty == true)
      partes.add('CP ${usuario!.codigoPostal!}');

    return partes.isNotEmpty ? partes.join(', ') : 'Sin dirección';
  }

  Widget _buildProfileIdentifier() {
    if (usuario == null) return const SizedBox();

    switch (usuario!.tipoPerfil) {
      case TipoPerfilCUS.ciudadano:
        return _buildInfoCard(
          'Folio',
          _getDisplayValue(usuario!.folio, 'Sin folio'),
          imagenesIconos['badge']!,
          Icons.confirmation_number,
        );
      case TipoPerfilCUS.trabajador:
        return _buildInfoCard(
          'Nómina',
          _getDisplayValue(usuario!.nomina, 'Sin nómina'),
          imagenesIconos['badge']!,
          Icons.badge,
        );
      case TipoPerfilCUS.personaMoral:
      case TipoPerfilCUS.usuario:
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgGray = Color(0xFFF5F7FA);

    return Scaffold(
      backgroundColor: bgGray,
      appBar: AppBar(
        title: const Text('Perfil de Usuario'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchUserData,
          ),
        ],
      ),
      body: _isLoading
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
                                const SizedBox(height: 20),
                                _buildSection(
                                  title: 'Información Personal',
                                  iconPath: imagenesIconos['person']!,
                                  children: [
                                    _buildProfileIdentifier(),
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
                                  ],
                                ),
                                const SizedBox(height: 30),
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
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildBannerHeader(UsuarioCUS userData) {
    const govBlue = Color(0xFF0B3B60);

    String? identificador;

    // Lógica específica para folio/nómina
    if (userData.tipoPerfil == TipoPerfilCUS.ciudadano) {
      identificador =
          userData.folio != null ? 'Folio: ${userData.folio}' : null;
    } else if (userData.tipoPerfil == TipoPerfilCUS.trabajador) {
      identificador =
          userData.nomina != null ? 'Nómina: ${userData.nomina}' : null;
    }

    final nombre = userData.nombreCompleto ?? 'Usuario';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 32, top: 32),
      decoration: const BoxDecoration(
        color: govBlue,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: CircleAvatar(
                    radius: 52,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 48,
                      backgroundImage:
                          _imageFile != null ? FileImage(_imageFile!) : null,
                      backgroundColor: Colors.grey[300],
                      child: _imageFile == null
                          ? const Icon(Icons.person, size: 50, color: govBlue)
                          : null,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    padding: const EdgeInsets.all(4),
                    child:
                        const Icon(Icons.camera_alt, size: 20, color: govBlue),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            nombre,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          if (identificador != null)
            Text(
              identificador,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFFD1D5DB),
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
              userData.tipoPerfilDisplay,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
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
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
            ),
          ],
        );
      },
    );
  }
}
