// screens/perfiles/perfil_ciudadano_screen.dart

// ignore_for_file: avoid_print, use_build_context_synchronously

import 'dart:io';
import 'package:cus_movil/widgets/alert_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _PerfilCiudadanoScreenState extends State<PerfilCiudadanoScreen>
    with TickerProviderStateMixin {
  UsuarioCUS? usuario;
  File? _imageFile;
  bool _isLoading = true;
  String? _error;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
    _setupAnimations();
    _fetchUserData();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
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

      // Iniciar animaciones
      _animationController.forward();

      // DIAGNÓSTICO: Verificar datos del usuario
      print(
          '[PerfilCiudadano] 🎂 Fecha de nacimiento: ${user.fechaNacimiento}');
      print('[PerfilCiudadano] 👤 Nombre: ${user.nombre}');
      print('[PerfilCiudadano] 👤 Nombre completo: ${user.nombre_completo}');
      print('[PerfilCiudadano] 🆔 Folio: ${user.folio}');
      print('[PerfilCiudadano] 🆔 ID Ciudadano: ${user.idCiudadano}');
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
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (picked != null) {
        setState(() {
          _imageFile = File(picked.path);
        });

        // Feedback háptico
        HapticFeedback.lightImpact();

        // Mostrar confirmación
        AlertHelper.showAlert(
          'Foto de perfil actualizada',
          type: AlertType.success,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      AlertHelper.showAlert(
        'Error al seleccionar imagen: ${e.toString()}',
        type: AlertType.error,
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

    print('[PerfilCiudadano] 🔍 CONSTRUYENDO NOMBRE COMPLETO:');
    print('[PerfilCiudadano] - nombre: ${usuario!.nombre}');
    print('[PerfilCiudadano] - nombre_completo: ${usuario!.nombre_completo}');

    // 1. Priorizar nombre_completo si existe y es diferente al nombre básico
    if (usuario!.nombre_completo != null &&
        usuario!.nombre_completo!.isNotEmpty &&
        usuario!.nombre_completo!.trim().length >
            usuario!.nombre.trim().length) {
      print(
          '[PerfilCiudadano] ✅ Usando nombre_completo: ${usuario!.nombre_completo}');
      return usuario!.nombre_completo!;
    }

    // 2. Si solo tenemos el nombre básico, verificar si parece incompleto
    String nombreFinal = usuario!.nombre;

    if (nombreFinal.isNotEmpty && nombreFinal != 'Usuario Sin Nombre') {
      // Si el nombre no contiene espacios, probablemente solo es el primer nombre
      if (!nombreFinal.contains(' ')) {
        print(
            '[PerfilCiudadano] ⚠️ Nombre parece incompleto (sin apellidos): $nombreFinal');
        // Mostrar advertencia de que faltan apellidos
        return '$nombreFinal [Apellidos no disponibles]';
      }

      // Si ya contiene espacios, probablemente es completo
      print('[PerfilCiudadano] ✅ Nombre parece completo: $nombreFinal');
      return nombreFinal;
    }

    print('[PerfilCiudadano] ❌ No hay nombre disponible');
    return 'Sin nombre completo';
  }

  String _buildDireccion() {
    if (usuario == null) return 'Sin dirección';

    final partes = <String>[];
    if (usuario!.calle?.isNotEmpty == true) partes.add(usuario!.calle!);
    if (usuario!.asentamiento?.isNotEmpty == true) {
      partes.add(usuario!.asentamiento!);
    }
    if (usuario!.estado?.isNotEmpty == true) {
      partes.add(usuario!.estado!);
    }
    if (usuario!.codigoPostal?.isNotEmpty == true) {
      partes.add('CP ${usuario!.codigoPostal!}');
    }

    return partes.isNotEmpty ? partes.join(', ') : 'Sin dirección registrada';
  }

  String _getIdentificadorPrincipal() {
    if (usuario == null) return '';

    // Usar el getter del modelo que ya tiene la lógica correcta
    final identificador = usuario!.identificadorPrincipal;
    if (identificador != null && identificador.isNotEmpty) {
      return identificador;
    }

    return 'Sin identificador';
  }

  String _getEtiquetaIdentificador() {
    if (usuario == null) return 'ID';

    // Usar el getter del modelo que ya tiene la lógica correcta
    return usuario!.etiquetaIdentificador;
  }

  String _formatearFecha(String? fecha) {
    if (fecha == null || fecha.isEmpty) return 'Sin fecha';

    try {
      final fechaDateTime = DateTime.parse(fecha);
      return '${fechaDateTime.day}/${fechaDateTime.month}/${fechaDateTime.year}';
    } catch (e) {
      // Si no se puede parsear, devolver tal como está
      return fecha;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bgGray = Color(0xFFF5F7FA);

    return Scaffold(
      backgroundColor: bgGray,
      body: OverflowSafeWidget(
        child: _isLoading
            ? _buildLoadingScreen()
            : _error != null
                ? _buildErrorScreen()
                : usuario == null
                    ? const Center(child: Text('No hay datos para mostrar'))
                    : _buildMainContent(),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0B3B60)),
          ),
          SizedBox(height: 16),
          Text(
            'Cargando perfil...',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
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
      ),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildBannerHeader(usuario!),
          SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
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

                        // Identificador principal (Folio o ID)
                        if (_getIdentificadorPrincipal().isNotEmpty &&
                            _getIdentificadorPrincipal() != 'Sin identificador')
                          _buildInfoCard(
                            _getEtiquetaIdentificador(),
                            _getIdentificadorPrincipal(),
                            imagenesIconos['badge']!,
                            Icons.confirmation_number,
                          ),

                        // CURP
                        _buildInfoCard(
                          'CURP',
                          _getDisplayValue(usuario!.curp, 'Sin CURP'),
                          imagenesIconos['badge']!,
                          Icons.badge,
                        ),

                        // Fecha de Nacimiento
                        _buildInfoCard(
                          'Fecha de Nacimiento',
                          _formatearFecha(usuario!.fechaNacimiento),
                          imagenesIconos['cake']!,
                          Icons.cake,
                        ),

                        // Nacionalidad
                        _buildInfoCard(
                          'Nacionalidad',
                          usuario!.nacionalidadDisplay,
                          imagenesIconos['flag']!,
                          Icons.flag,
                        ),

                        // Estado Civil (solo si existe)
                        if (usuario!.estadoCivil != null &&
                            usuario!.estadoCivil!.isNotEmpty)
                          _buildInfoCard(
                            'Estado Civil',
                            _getDisplayValue(
                                usuario!.estadoCivil, 'Sin estado civil'),
                            imagenesIconos['civil']!,
                            Icons.favorite,
                          ),

                        // Ocupación (solo si existe)
                        if (usuario!.ocupacion != null &&
                            usuario!.ocupacion!.isNotEmpty)
                          _buildInfoCard(
                            'Ocupación',
                            _getDisplayValue(
                                usuario!.ocupacion, 'Sin ocupación'),
                            imagenesIconos['occupation']!,
                            Icons.work_outline,
                          ),
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

                    const SizedBox(height: 20),

                    // Estado del perfil
                    _buildPerfilStatus(),

                    const SizedBox(height: 30),
                    _buildLogoutButton(context),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerfilStatus() {
    final isCompleto = usuario!.perfilCompleto;
    final camposFaltantes = usuario!.camposFaltantes;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleto
              ? Colors.green.withOpacity(0.3)
              : Colors.orange.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCompleto ? Icons.check_circle : Icons.warning,
                color: isCompleto ? Colors.green : Colors.orange,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                isCompleto ? 'Perfil Completo' : 'Perfil Incompleto',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isCompleto ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isCompleto
                ? 'Tu perfil está completo y verificado.'
                : 'Faltan algunos datos para completar tu perfil.',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
          if (!isCompleto && camposFaltantes.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Campos faltantes:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: camposFaltantes.map((campo) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    campo,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
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
                  child: Text(
                    userData.tipoPerfilDescripcion,
                    style: const TextStyle(
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
            Image.asset(
              iconPath,
              width: 28,
              height: 28,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.info,
                size: 28,
                color: Color(0xFF0B3B60),
              ),
            ),
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
          backgroundColor: const Color.fromARGB(255, 159, 7, 7),
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
              return Colors.red.shade800.withOpacity(0.2);
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
                                "Confirmar",
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
