// screens/perfiles/perfil_trabajador_screen.dart

// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:cus_movil/widgets/alert_helper.dart';
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
      final picked =
          await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (picked != null) {
        setState(() {
          _imageFile = File(picked.path);
        });
      }
    } catch (e) {
      if (mounted) {
        AlertHelper.showAlert(
          'Error al seleccionar imagen: ${e.toString()}',
          type: AlertType.error,
        );
      }
    }
  }

  String _getDisplayValue(dynamic value,
      {String defaultValue = 'No especificado'}) {
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
                                          _getDisplayValue(
                                              usuario!.departamento),
                                          imagenesIconos['department']!,
                                          Icons.business),
                                      _buildInfoCard(
                                          'Puesto',
                                          _getDisplayValue(usuario!.puesto),
                                          imagenesIconos['position']!,
                                          Icons.work),
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
                                  const SizedBox(height: 100),
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
    final nombre = _getDisplayValue(userData.nombre_completo ?? userData.nombre,
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
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showLogoutDialog(context),
        icon: const Icon(Icons.logout_rounded, size: 20),
        label: const Text(
          "Cerrar sesión",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 22, 44, 146),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          shadowColor: Colors.black.withOpacity(0.25),
        ).copyWith(
          overlayColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.pressed)) {
              return const Color.fromARGB(255, 22, 44, 146);
            }
            return null;
          }),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 340),
            margin: const EdgeInsets.all(2),
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
                BoxShadow(
                  color: const Color(0xFF0b3b60).withOpacity(0.08),
                  blurRadius: 40,
                  offset: const Offset(0, 15),
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  //? Icono principal
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
                      Icons.power_settings_new_rounded,
                      color: Color(0xFF0b3b60),
                      size: 28,
                    ),
                  ),

                  const SizedBox(height: 20),

                  //? Título
                  const Text(
                    "Cerrar Sesión",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0b3b60),
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 12),

                  //* Contenido
                  Text(
                    "¿Estás seguro de que deseas cerrar sesión?\nPerderás el acceso hasta volver a iniciar sesión.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const SizedBox(height: 24),

                  //* Botones
                  Row(
                    children: [
                      //! Cancelar
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            icon: Icon(Icons.close_rounded,
                                size: 16, color: Colors.grey[600]),
                            label: Text(
                              "Cancelar",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              side: BorderSide(
                                  color: Colors.grey[300]!, width: 1.5),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              minimumSize: const Size.fromHeight(44),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      //? Confirmar
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0B3B60), Color(0xFF0B3B60)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                Navigator.of(dialogContext).pop();
                                //? Loading
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (_) => const Center(
                                      child: CircularProgressIndicator()),
                                );
                                try {
                                  await AuthService('temp').logout();
                                  if (mounted) {
                                    Navigator.of(context)
                                        .pop(); //! cierra loading
                                    AlertHelper.showAlert(
                                      'Sesión cerrada',
                                      type: AlertType.success,
                                    );
                                    //* Dale un pequeño delay para que la alerta se muestre
                                    await Future.delayed(
                                        const Duration(milliseconds: 500));
                                    Navigator.pushReplacementNamed(
                                        context, '/auth');
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    Navigator.of(context).pop();
                                    AlertHelper.showAlert(
                                      'Error al cerrar sesión: $e',
                                      type: AlertType.error,
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.logout_rounded,
                                  size: 16, color: Colors.white),
                              label: const Text(
                                "Aceptar",
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                minimumSize: const Size.fromHeight(44),
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
