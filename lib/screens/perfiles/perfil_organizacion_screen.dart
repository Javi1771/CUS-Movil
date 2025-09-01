// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:cus_movil/widgets/alert_helper.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/usuario_cus.dart';
import '../../services/user_data_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/overflow_safe_widget.dart';

class PerfilOrganizacionScreen extends StatefulWidget {
  const PerfilOrganizacionScreen({super.key});

  @override
  State<PerfilOrganizacionScreen> createState() =>
      _PerfilOrganizacionScreenState();
}

class _PerfilOrganizacionScreenState extends State<PerfilOrganizacionScreen> {
  UsuarioCUS? usuario;
  File? _imageFile;
  bool _isLoading = true;
  String? _error;

  final Map<String, String> imagenesIconos = {
    'business': 'assets/informacion laboral.png',
    'rfc': 'assets/rfc.png',
    'person': 'assets/informacion personal.png',
    'curp': 'assets/Curp.png',
    'telefono': 'assets/telefono.png',
    'email': 'assets/Correo Electronico.png',
    'direccion': 'assets/Direccion.png',
    'contact': 'assets/Informacion de contacto.png',
    'home': 'assets/Direccion.png',
    'id_card': 'assets/rfc.png',
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
          _error = 'No se pudo obtener la información de la organización.';
          _isLoading = false;
        });
        return;
      }
      // CORRECCIÓN: Forzar la pantalla a mostrar solo perfiles de organización.
      // Si el backend devuelve un perfil de ciudadano aquí, es un error de lógica del servidor.
      // if (user.tipoPerfil != TipoPerfilCUS.personaMoral && user.tipoPerfil != TipoPerfilCUS.organizacion) {
      //   setState(() {
      //     _error = 'El perfil obtenido no corresponde a una organización.';
      //     _isLoading = false;
      //   });
      //   return;
      // }

      setState(() {
        usuario = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al obtener datos de la organización: ${e.toString()}';
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
      if (mounted) {
        AlertHelper.showAlert(
          'Error al seleccionar imagen: ${e.toString()}',
          type: AlertType.error,
        );
      }
    }
  }

  String _getDisplayValue(dynamic value,
      [String defaultValue = 'No especificado']) {
    if (value == null || (value is String && value.isEmpty)) {
      return defaultValue;
    }
    return value.toString();
  }

  String _buildDireccion() {
    if (usuario == null) return 'No especificada';

    final partes = <String>[
      if (usuario!.calle?.isNotEmpty == true) usuario!.calle!,
      if (usuario!.asentamiento?.isNotEmpty == true) usuario!.asentamiento!,
      if (usuario!.estado?.isNotEmpty == true) usuario!.estado!,
      if (usuario!.codigoPostal?.isNotEmpty == true)
        'CP ${usuario!.codigoPostal!}',
    ];

    return partes.isNotEmpty ? partes.join(', ') : 'No especificada';
  }

  // CAMBIO: La función ahora prioriza el RFC para organizaciones.
  String _getIdentificadorUnico() {
    if (usuario == null) return 'Sin ID';

    // Prioridad para organizaciones: RFC, luego ID de usuario, luego folio.
    if (usuario!.rfc != null && usuario!.rfc!.isNotEmpty) {
      return usuario!.rfc!;
    }
    if (usuario!.usuarioId != null && usuario!.usuarioId!.isNotEmpty) {
      return usuario!.usuarioId!;
    }
    if (usuario!.folio != null && usuario!.folio!.isNotEmpty) {
      return usuario!.folio!;
    }
    return 'Sin ID';
  }

  // CAMBIO: Etiqueta más clara para el identificador.
  String _getEtiquetaIdentificador() {
    if (usuario == null) return 'ID';
    if (usuario!.rfc != null && usuario!.rfc!.isNotEmpty) return 'RFC';
    if (usuario!.usuarioId != null && usuario!.usuarioId!.isNotEmpty) {
      return 'ID de Registro';
    }
    if (usuario!.folio != null && usuario!.folio!.isNotEmpty) return 'Folio';
    return 'ID';
  }

  @override
  Widget build(BuildContext context) {
    const bgGray = Color(0xFFF5F7FA);

    final bool tieneDatosRepresentante = usuario != null &&
        ((usuario!.nombre_completo != null &&
                usuario!.nombre_completo!.isNotEmpty) ||
            (usuario!.nombre.isNotEmpty &&
                usuario!.nombre != 'Usuario Sin Nombre') ||
            (usuario!.curp.isNotEmpty && usuario!.curp != 'Sin CURP'));

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
                      Icon(Icons.error_outline,
                          size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _error!,
                          style:
                              const TextStyle(color: Colors.red, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _fetchUserData,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ))
                : usuario == null
                    ? const Center(
                        child: Text(
                            'No hay datos de la organización para mostrar'))
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
                                  _buildSection(
                                    title: 'Datos Generales de la Organización',
                                    iconPath: imagenesIconos['business']!,
                                    children: [
                                      _buildInfoCard(
                                        'Razón Social',
                                        _getDisplayValue(usuario!.razonSocial,
                                            'No especificada'),
                                        imagenesIconos['business']!,
                                        Icons.business,
                                      ),
                                      // CAMBIO: Muestra el identificador más relevante.
                                      if (_getIdentificadorUnico() != 'Sin ID')
                                        _buildInfoCard(
                                          _getEtiquetaIdentificador(),
                                          _getIdentificadorUnico(),
                                          imagenesIconos['rfc']!,
                                          Icons.badge,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  if (tieneDatosRepresentante)
                                    _buildSection(
                                      title: 'Datos del Representante Legal',
                                      iconPath: imagenesIconos['person']!,
                                      children: [
                                        _buildInfoCard(
                                          'Nombre del Representante',
                                          _getDisplayValue(
                                              usuario!.nombre_completo ??
                                                  usuario!.nombre),
                                          imagenesIconos['person']!,
                                          Icons.person,
                                        ),
                                        if (usuario!.curp.isNotEmpty &&
                                            usuario!.curp != 'Sin CURP')
                                          _buildInfoCard(
                                            'CURP del Representante',
                                            _getDisplayValue(usuario!.curp),
                                            imagenesIconos['curp']!,
                                            Icons.badge,
                                          ),
                                      ],
                                    ),
                                  const SizedBox(height: 10),
                                  _buildSection(
                                    title: 'Información de Contacto',
                                    iconPath: imagenesIconos['contact']!,
                                    children: [
                                      _buildInfoCard(
                                        'Correo Electrónico',
                                        _getDisplayValue(usuario!.email),
                                        imagenesIconos['email']!,
                                        Icons.email,
                                      ),
                                      _buildInfoCard(
                                        'Teléfono',
                                        _getDisplayValue(usuario!.telefono),
                                        imagenesIconos['telefono']!,
                                        Icons.phone,
                                      ),
                                      _buildInfoCard(
                                        'Dirección Fiscal',
                                        _buildDireccion(),
                                        imagenesIconos['home']!,
                                        Icons.location_city,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 30),
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

    // CAMBIO: Lógica más robusta para mostrar el nombre correcto.
    final nombreOrganizacion =
        _getDisplayValue(userData.razonSocial, 'Organización sin Nombre');

    // CORRECCIÓN: Ahora userData.rfc tendrá el valor correcto desde el modelo.
    _getDisplayValue(userData.rfc, 'Sin RFC');

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
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 95),
            child: Column(
              children: [
                Text(
                  nombreOrganizacion,
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
                    'Organización',
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
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 2)
                    ],
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(width: 4, color: govBlue)),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          backgroundImage: _imageFile != null
                              ? FileImage(_imageFile!)
                              : null,
                          // CAMBIO: Icono más apropiado para organización
                          child: _imageFile == null
                              ? Icon(Icons.corporate_fare,
                                  size: 48, color: govBlue.withOpacity(0.8))
                              : null,
                        ),
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            decoration: const BoxDecoration(
                                shape: BoxShape.circle, color: Colors.white),
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
            Text(
              title,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B)),
            ),
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
    const textGray = Color(0xFF475569);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            imagePath,
            width: 36,
            height: 36,
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
                        color: textGray)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B)),
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
