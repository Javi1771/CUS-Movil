// screens/perfiles/perfil_ciudadano_screen.dart

// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'dart:typed_data';
import 'package:cus_movil/widgets/alert_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
// Guardado local
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../models/usuario_cus.dart';
import '../../services/user_data_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/overflow_safe_widget.dart';

class PerfilCiudadanoScreen extends StatefulWidget {
  const PerfilCiudadanoScreen({super.key});

  @override
  State<PerfilCiudadanoScreen> createState() => _PerfilCiudadanoScreenState();
}

class _PerfilCiudadanoScreenState extends State<PerfilCiudadanoScreen>
    with TickerProviderStateMixin {
  static const Color _govBlue = Color(0xFF0B3B60);
  static const Color _logoutButtonColor = Color.fromARGB(255, 22, 44, 146);
  static const Color _bgColor = Color(0xFFF5F7FA);
  static const Color _textColorPrimary = Color(0xFF1E293B);
  static const Color _textColorSecondary = Color(0xFF475569);

  static const Map<String, String> _assetIcons = {
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
  };

  UsuarioCUS? _usuario;
  Uint8List? _imageBytes;
  bool _isLoading = true;
  String? _error;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  static const String _profileImageFilename = 'profile_image.jpg';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadProfileImage();
    _fetchUserData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut);
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _animationController, curve: Curves.easeOutCubic));
  }

  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = await UserDataService.getUserData();
      if (!mounted) return;

      if (user == null) {
        throw Exception('No se pudo obtener la información del ciudadano.');
      }
      if (user.tipoPerfil != TipoPerfilCUS.ciudadano) {
        throw Exception('Este perfil es solo para ciudadanos.');
      }

      setState(() {
        _usuario = user;
      });
      _animationController.forward();
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst("Exception: ", ""));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Cargar imagen local
  Future<void> _loadProfileImage() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, _profileImageFilename));
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        if (mounted) {
          setState(() {
            _imageBytes = bytes;
          });
        }
      }
    } catch (e) {
      debugPrint("Error al cargar imagen local: $e");
    }
  }

  // Guardar imagen local
  Future<void> _saveImageLocally(Uint8List bytes) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, _profileImageFilename));
      await file.writeAsBytes(bytes);
    } catch (e) {
      AlertHelper.showAlert('No se pudo guardar la foto: $e',
          type: AlertType.error);
    }
  }

  // Menú para origen de imagen
  Future<void> _showImageSourceActionSheet() async {
    await showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tomar foto'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Seleccionar de la galería'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
    return;
  }

  // Selección de imagen
  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 800,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() => _imageBytes = bytes);
        await _saveImageLocally(bytes);

        HapticFeedback.lightImpact();
        AlertHelper.showAlert(
          'Foto de perfil actualizada',
          type: AlertType.success,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      AlertHelper.showAlert('Error al obtener imagen: $e',
          type: AlertType.error);
    }
  }

  String get _nombreCompleto {
    if (_usuario == null) return 'Sin nombre';
    if (_usuario!.nombre_completo != null &&
        _usuario!.nombre_completo!.trim().length >
            _usuario!.nombre.trim().length) {
      return _usuario!.nombre_completo!;
    }
    return _usuario!.nombre.isNotEmpty
        ? _usuario!.nombre
        : 'Sin nombre completo';
  }

  String get _direccionCompleta {
    if (_usuario == null) return 'Sin dirección';
    final parts = [
      _usuario!.calle,
      _usuario!.asentamiento,
      _usuario!.estado,
      if (_usuario!.codigoPostal?.isNotEmpty == true)
        'CP ${_usuario!.codigoPostal!}'
    ].where((p) => p != null && p.isNotEmpty).toList();
    return parts.isNotEmpty ? parts.join(', ') : 'Sin dirección registrada';
  }

  String _formatearFecha(String? fecha) {
    if (fecha == null || fecha.isEmpty) return 'Sin fecha';
    try {
      final dt = DateTime.parse(fecha);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (e) {
      return fecha;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: OverflowSafeWidget(
        child: _isLoading
            ? const _LoadingScreen()
            : _error != null
                ? _ErrorScreen(error: _error!, onRetry: _fetchUserData)
                : _usuario == null
                    ? const Center(child: Text('No hay datos para mostrar'))
                    : _buildMainContent(),
      ),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            children: [
              _BannerHeader(
                  nombre: _nombreCompleto,
                  tipoPerfil: _usuario!.tipoPerfilDescripcion),
              const SizedBox(height: 65),
              SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        _buildInfoSections(),
                        const SizedBox(height: 30),
                        // === MISMO CTA QUE ORGANIZACIÓN ===
                        _buildLogoutButton(context),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: 180,
            left: 0,
            right: 0,
            child: _ProfileAvatar(
                imageBytes: _imageBytes,
                onPickImage: _showImageSourceActionSheet),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSections() {
    final user = _usuario!;
    final identificadorPrincipal = user.identificadorPrincipal;

    return Column(
      children: [
        _InfoSection(
          title: 'Información Personal',
          iconPath: _assetIcons['person']!,
          children: [
            _InfoCard(
                label: 'Nombre Completo',
                value: _nombreCompleto,
                imagePath: _assetIcons['person']!,
                fallbackIcon: Icons.person),
            if (identificadorPrincipal != null &&
                identificadorPrincipal.isNotEmpty)
              _InfoCard(
                  label: user.etiquetaIdentificador,
                  value: identificadorPrincipal,
                  imagePath: _assetIcons['badge']!,
                  fallbackIcon: Icons.confirmation_number),
            _InfoCard(
                label: 'CURP',
                value: user.curp,
                imagePath: _assetIcons['badge']!,
                fallbackIcon: Icons.badge),
            _InfoCard(
                label: 'Fecha de Nacimiento',
                value: _formatearFecha(user.fechaNacimiento),
                imagePath: _assetIcons['cake']!,
                fallbackIcon: Icons.cake),
            _InfoCard(
                label: 'Nacionalidad',
                value: user.nacionalidadDisplay,
                imagePath: _assetIcons['flag']!,
                fallbackIcon: Icons.flag),
            if (user.estadoCivil?.isNotEmpty == true)
              _InfoCard(
                  label: 'Estado Civil',
                  value: user.estadoCivil!,
                  imagePath: _assetIcons['civil']!,
                  fallbackIcon: Icons.favorite),
            if (user.ocupacion?.isNotEmpty == true)
              _InfoCard(
                  label: 'Ocupación',
                  value: user.ocupacion!,
                  imagePath: _assetIcons['occupation']!,
                  fallbackIcon: Icons.work_outline),
          ],
        ),
        const SizedBox(height: 20),
        _InfoSection(
          title: 'Información de Contacto',
          iconPath: _assetIcons['contact']!,
          children: [
            _InfoCard(
                label: 'Correo Electrónico',
                value: user.email,
                imagePath: _assetIcons['email']!,
                fallbackIcon: Icons.email),
            _InfoCard(
                label: 'Teléfono',
                value: user.telefono ?? 'Sin teléfono',
                imagePath: _assetIcons['phone']!,
                fallbackIcon: Icons.phone),
            _InfoCard(
                label: 'Dirección',
                value: _direccionCompleta,
                imagePath: _assetIcons['home']!,
                fallbackIcon: Icons.home),
          ],
        ),
        const SizedBox(height: 20),
        _ProfileStatus(usuario: user),
      ],
    );
  }

  // =========================
  // === BOTÓN & DIÁLOGO  ===
  // ===   (igual org)    ===
  // =========================

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
          backgroundColor: _logoutButtonColor,
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
              return _logoutButtonColor;
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

// --- WIDGETS EXTRAÍDOS (Stateless) ---

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                  _PerfilCiudadanoScreenState._govBlue)),
          SizedBox(height: 16),
          Text('Cargando perfil...',
              style: TextStyle(fontSize: 16, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorScreen({required this.error, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(error,
                style: const TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _PerfilCiudadanoScreenState._govBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BannerHeader extends StatelessWidget {
  final String nombre;
  final String tipoPerfil;
  const _BannerHeader({required this.nombre, required this.tipoPerfil});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 245,
      decoration: const BoxDecoration(
        color: _PerfilCiudadanoScreenState._govBlue,
        borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(50), bottomRight: Radius.circular(50)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              nombre,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800),
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
                borderRadius: BorderRadius.circular(20)),
            child: Text(tipoPerfil,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
          ),
          const SizedBox(height: 65),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final Uint8List? imageBytes;
  final VoidCallback onPickImage;
  const _ProfileAvatar({this.imageBytes, required this.onPickImage});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onPickImage,
        child: Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                  color: _PerfilCiudadanoScreenState._govBlue, width: 4)),
          padding: const EdgeInsets.all(4),
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircleAvatar(
                radius: 61,
                backgroundImage:
                    imageBytes != null ? MemoryImage(imageBytes!) : null,
                backgroundColor: Colors.grey[200],
                child: imageBytes == null
                    ? const Icon(Icons.person,
                        size: 48, color: _PerfilCiudadanoScreenState._govBlue)
                    : null,
              ),
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt,
                      size: 18, color: _PerfilCiudadanoScreenState._govBlue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final String iconPath;
  final List<Widget> children;
  const _InfoSection(
      {required this.title, required this.iconPath, required this.children});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Image.asset(iconPath,
                width: 28,
                height: 28,
                errorBuilder: (_, __, ___) => const Icon(Icons.info,
                    size: 28, color: _PerfilCiudadanoScreenState._govBlue)),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _PerfilCiudadanoScreenState._textColorPrimary)),
          ],
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String label;
  final String value;
  final String imagePath;
  final IconData fallbackIcon;
  const _InfoCard(
      {required this.label,
      required this.value,
      required this.imagePath,
      required this.fallbackIcon});
  @override
  Widget build(BuildContext context) {
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
              offset: const Offset(0, 3))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(imagePath,
              width: 40,
              height: 40,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(fallbackIcon,
                  size: 36, color: _PerfilCiudadanoScreenState._govBlue)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color:
                            _PerfilCiudadanoScreenState._textColorSecondary)),
                const SizedBox(height: 6),
                Text(value,
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: _PerfilCiudadanoScreenState._textColorPrimary),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStatus extends StatelessWidget {
  final UsuarioCUS usuario;
  const _ProfileStatus({required this.usuario});
  @override
  Widget build(BuildContext context) {
    final isCompleto = usuario.perfilCompleto;
    final statusColor = isCompleto ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isCompleto ? Icons.check_circle : Icons.warning,
                  color: statusColor, size: 24),
              const SizedBox(width: 12),
              Text(isCompleto ? 'Perfil Completo' : 'Perfil Incompleto',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: statusColor)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
              isCompleto
                  ? 'Tu perfil está completo y verificado.'
                  : 'Faltan algunos datos para completar tu perfil.',
              style: const TextStyle(
                  fontSize: 14,
                  color: _PerfilCiudadanoScreenState._textColorSecondary)),
          if (!isCompleto && usuario.camposFaltantes.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Campos faltantes:',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _PerfilCiudadanoScreenState._textColorSecondary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: usuario.camposFaltantes
                  .map((campo) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.orange.withOpacity(0.3))),
                        child: Text(campo,
                            style: const TextStyle(
                                fontSize: 11,
                                color: Colors.orange,
                                fontWeight: FontWeight.w600)),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}
