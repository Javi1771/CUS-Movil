import 'package:cus_movil/widgets/alert_helper.dart';
import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:cus_movil/screens/perfil_usuario_screen.dart';
import 'package:cus_movil/screens/mis_documentos_screen.dart';
import 'package:cus_movil/screens/tramites_screen.dart';
import 'package:cus_movil/services/weather_service.dart';
import 'package:cus_movil/services/location_service.dart';
import 'package:cus_movil/services/user_data_service.dart';
import 'package:cus_movil/services/tramites_service.dart';
import 'package:cus_movil/models/usuario_cus.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:cus_movil/models/weather_data.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:cus_movil/widgets/weather_card.dart';
import 'secretarias_screen.dart';
import '../models/secretaria.dart';
import 'components/help_button.dart';

//* Configuración global de caché para imágenes
final imageCacheManager = CacheManager(
  Config(
    'customCacheKey',
    stalePeriod: const Duration(days: 7),
    maxNrOfCacheObjects: 100,
  ),
);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class ActividadReciente {
  final String titulo;
  final String descripcion;
  final DateTime fecha;
  final String estado;
  final IconData icono;
  final Color color;

  ActividadReciente({
    required this.titulo,
    required this.descripcion,
    required this.fecha,
    required this.estado,
    required this.icono,
    required this.color,
  });
}

class EstadisticasActividad {
  final int tramitesActivos;
  final int pendientes;
  final double porcentajeCompletados;

  EstadisticasActividad({
    required this.tramitesActivos,
    required this.pendientes,
    required this.porcentajeCompletados,
  });
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _page = 0;
  UsuarioCUS? _usuario;
  WeatherData? _weatherData;
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late AnimationController _fadeController;
  final LocationService _locationService = LocationService();
  bool _isLoadingWeather = false;
  bool _isLoadingStats = false;
  bool _isLoadingActivity = false;

  StreamSubscription<Position>? _posSub;
  Timer? _weatherDebounce;

  EstadisticasActividad? _estadisticas;
  List<ActividadReciente> _actividadReciente = [];
  List<Secretaria> _secretarias = [];

  Animation<double>? _pulseAnimation;
  Animation<Offset>? _slideAnimation;
  Animation<double>? _fadeAnimation;

  double? _currentLat;
  double? _currentLon;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeBasics();
    _initWeather();
    _loadResumenGeneral();
    _loadSecretarias();
  }

  void _loadSecretarias() {
    _secretarias = SecretariasData.getSecretariasEjemplo();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _pulseController.repeat(reverse: true);
    _slideController.forward();
    _fadeController.forward();
  }

  void _initializeBasics() async {
    try {
      _usuario = await UserDataService.getUserData();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      _usuario = UsuarioCUS(
        nombre: 'Usuario',
        email: 'usuario@ejemplo.com',
        curp: 'Sin CURP',
        usuarioId: 'temp-id',
        tipoPerfil: TipoPerfilCUS.ciudadano,
      );
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<bool> solicitarPermisosUbicacion() async {
    LocationPermission permission = await Geolocator.checkPermission();

    // !Si el permiso está denegado, lo solicitamos
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    //! Si fue denegado para siempre, mostramos una alerta
    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    //* Permitido
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<void> _loadResumenGeneral() async {
    if (!mounted) return;

    setState(() {
      _isLoadingStats = true;
      _isLoadingActivity = true;
    });

    try {
      final tramitesResponse = await TramitesService.getTramitesEstados();
      final tramites = tramitesResponse.data;

      final tramitesActivos = tramites.length;
      final pendientes = tramites
          .where((t) =>
              t.nombreEstado.toUpperCase() == 'POR REVISAR' ||
              t.nombreEstado.toUpperCase() == 'CORREGIR' ||
              t.nombreEstado.toUpperCase() == 'REQUIERE PAGO' ||
              t.nombreEstado.toUpperCase() == 'ENVIADO PARA FIRMAR')
          .length;

      final completados = tramites
          .where((t) => t.nombreEstado.toUpperCase() == 'FIRMADO')
          .length;

      final porcentajeCompletados =
          tramitesActivos > 0 ? (completados / tramitesActivos * 100) : 0.0;

      final stats = EstadisticasActividad(
        tramitesActivos: tramitesActivos,
        pendientes: pendientes,
        porcentajeCompletados: porcentajeCompletados,
      );

      final actividades = tramites
          .take(5)
          .map((tramite) => ActividadReciente(
                titulo: _formatTextWithCapitalization(tramite.nombreTramite),
                descripcion: tramite.descripcionEstado,
                fecha: tramite.ultimaFechaModificacion,
                estado: tramite.nombreEstado,
                icono: tramite.iconoEstado,
                color: tramite.colorEstado,
              ))
          .toList();

      actividades.sort((a, b) => b.fecha.compareTo(a.fecha));

      if (mounted) {
        setState(() {
          _estadisticas = stats;
          _actividadReciente = actividades;
        });

        _slideController.reset();
        _fadeController.reset();
        _slideController.forward();
        _fadeController.forward();
      }
    } catch (e) {
      debugPrint('[HomeScreen] Error cargando resumen general: $e');
      if (mounted) {
        setState(() {
          _estadisticas = EstadisticasActividad(
            tramitesActivos: 0,
            pendientes: 0,
            porcentajeCompletados: 0.0,
          );
          _actividadReciente = [];
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
          _isLoadingActivity = false;
        });
      }
    }
  }

  String _formatTextWithCapitalization(String text) {
    if (text.isEmpty) return text;

    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  Future<void> _fetchWeather(double lat, double lon) async {
    //! ← Si ya estamos cargando, no hacemos nada
    if (_isLoadingWeather || !mounted) return;

    _currentLat = lat;
    _currentLon = lon;

    setState(() => _isLoadingWeather = true);

    try {
      debugPrint('[HomeScreen] Obteniendo clima para: $lat,$lon');
      final data = await WeatherService.getByCoords(lat: lat, lon: lon);

      if (!mounted) return;

      debugPrint(
          '[HomeScreen] Datos climáticos recibidos: ${data.temperature}°C, ${data.description}');
      setState(() => _weatherData = data);
    } catch (e) {
      debugPrint('[HomeScreen] Error al obtener el clima: $e');

      //! Crear datos simulados en caso de error
      setState(() => _weatherData = null);
    } finally {
      if (mounted) setState(() => _isLoadingWeather = false);
    }
  }

  Future<void> _initWeather() async {
    if (_isLoadingWeather || !mounted) return;

    try {
      debugPrint('[HomeScreen] Inicializando servicio de ubicación');

      //* Verificamos permisos primero
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint(
            '[HomeScreen] Permisos denegados. Usando ubicación por defecto.');
        await _fetchWeather(20.389487, -99.996695); //* San Juan del Río
        return;
      }

      await _locationService.initialize();
      final isReady = await _locationService.isReady();
      debugPrint('[HomeScreen] Servicio de ubicación listo: $isReady');

      double lat = 20.389487; //* Ubicación por defecto
      double lon = -99.996695;

      if (isReady) {
        final currentLocation = await _locationService.getCurrentLocation(
          timeout: const Duration(seconds: 8),
        );

        if (currentLocation != null) {
          lat = currentLocation.latitude;
          lon = currentLocation.longitude;
          debugPrint('[HomeScreen] Ubicación obtenida: $lat, $lon');
        }
      }

      await _fetchWeather(lat, lon);

      //* Iniciar stream si está listo
      if (isReady && mounted) {
        _posSub?.cancel();
        _posSub = _locationService
            .getPositionStream(distanceFilter: 300)
            .listen((pos) {
          if (!mounted) return;
          //* Cada vez que llegue una nueva posición, reinicia el timer
          _weatherDebounce?.cancel();
          _weatherDebounce = Timer(const Duration(seconds: 5), () {
            _fetchWeather(pos.latitude, pos.longitude);
          });
        });
      }
    } catch (e) {
      debugPrint('[HomeScreen] Error al inicializar clima: $e');
      await _fetchWeather(20.389487, -99.996695);
    }
  }

  Future<void> _refreshWeather() async {
    try {
      debugPrint('[HomeScreen] Verificando permisos de ubicación');

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Permisos requeridos'),
              content: const Text(
                'Los permisos de ubicación están permanentemente bloqueados. '
                'Por favor actívalos manualmente desde Configuración.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Geolocator.openAppSettings();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Abrir Configuración'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          );
        }
        return;
      }

      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        if (mounted) {
          AlertHelper.showAlert(
            'Por favor, otorga permisos de ubicación para actualizar el clima.',
            type: AlertType.error,
          );
        }
        return;
      }

      final currentLocation = await _locationService.getCurrentLocation(
        timeout: const Duration(seconds: 8),
      );

      //* NUEVA UBICACIÓN POR DEFECTO: San Juan del Río
      double lat = 20.389487;
      double lon = -99.996695;

      if (currentLocation != null) {
        debugPrint(
          '[HomeScreen] Ubicación obtenida: ${currentLocation.latitude}, ${currentLocation.longitude}',
        );
        lat = currentLocation.latitude;
        lon = currentLocation.longitude;
      } else {
        debugPrint(
            '[HomeScreen] Ubicación nula. Usando ubicación por defecto (San Juan del Río).');
      }

      await _fetchWeather(lat, lon);
    } catch (e) {
      debugPrint('[HomeScreen] Error al refrescar clima: $e');
      await _fetchWeather(
          20.389487, -99.996695); //* ← nueva ubicación por defecto
    }
  }

  Future<void> _refreshData() async {
    if (!mounted) return;

    debugPrint('[HomeScreen] Refrescando todos los datos');
    _slideController.reset();
    _fadeController.reset();

    await Future.wait([
      _refreshWeather(),
      _loadResumenGeneral(),
    ]);

    if (!mounted) return;

    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    _posSub?.cancel();
    _weatherDebounce?.cancel();
    super.dispose();
  }

  Widget _getPageAtIndex(int index) {
    switch (index) {
      case 0:
        return _buildHomePage();
      case 1:
        return const MisDocumentosScreen();
      case 2:
        return const TramitesScreen();
      case 3:
        return const SecretariasScreen();
      case 4:
        return const PerfilUsuarioScreen();
      default:
        return _buildHomePage();
    }
  }

  Widget _buildHomePage() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          color: const Color(0xFF0B3B60),
          backgroundColor: Colors.white,
          child: ListView(
            padding: EdgeInsets.zero,
            physics: const BouncingScrollPhysics(),
            children: [
              _buildNewHeader(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAnimatedStatsCards(),
                    const SizedBox(height: 24),
                    _buildSecretariasSection(),
                    const SizedBox(height: 24),
                    _buildAnimatedRecentActivity(),
                    const SizedBox(height: 24),
                    _buildHelpSection(),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHelpSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.support_agent, color: Color(0xFF0B3B60)),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¿Necesitas ayuda?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Contáctanos o revisa las preguntas frecuentes.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          HelpButton(
            supportEmail: 'sistemas@sanjuandelrio.gob.mx',
            emailSubject: 'Soporte CUS',
            faqUrl: 'https://sanjuandelrio.gob.mx/faqs',
          ),
        ],
      ),
    );
  }

  Widget _buildSecretariasSection() {
    if (_slideAnimation == null || _fadeAnimation == null) {
      return _buildSecretariasSectionWithoutAnimation();
    }

    return SlideTransition(
      position: _slideAnimation!,
      child: FadeTransition(
        opacity: _fadeAnimation!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Secretarías de Municipio',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _page = 3),
                  child: const Text(
                    'Ver todas',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0B3B60),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180, // Aumentada para acomodar el contenido flexible
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                itemCount: _secretarias.take(4).length,
                itemBuilder: (context, index) {
                  final secretaria = _secretarias[index];
                  return _buildSecretariaCard(secretaria, index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecretariasSectionWithoutAnimation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Secretarías de Municipio',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _page = 3),
              child: const Text(
                'Ver todas',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0B3B60),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            itemCount: _secretarias.take(4).length,
            itemBuilder: (context, index) {
              final secretaria = _secretarias[index];
              return _buildSecretariaCard(secretaria, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSecretariaCard(Secretaria secretaria, int index) {
    // Color azul más bajo y suave
    const primaryBlue = Color(0xFF4A90E2);

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + (index * 150)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(30 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        width: 180,
        // REMOVIDA altura fija para evitar overflow
        constraints: const BoxConstraints(
          minHeight: 160,
          maxHeight: 200, // Altura máxima flexible
        ),
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: primaryBlue,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: primaryBlue.withOpacity(0.25),
              blurRadius: 15,
              offset: const Offset(0, 6),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => setState(() => _page = 3),
            splashColor: Colors.white.withOpacity(0.15),
            highlightColor: Colors.white.withOpacity(0.08),
            child: Padding(
              padding: const EdgeInsets.all(14), // Padding reducido
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize:
                    MainAxisSize.min, // Importante para evitar overflow
                children: [
                  // Header con icono y número - MEJORADO
                  SizedBox(
                    height: 36, // Altura fija para el header
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.account_balance,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const Spacer(),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${secretaria.servicios.length}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: primaryBlue,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Nombre de la secretaría - ANTI-OVERFLOW
                  Flexible(
                    flex: 3, // Toma la mayor parte del espacio disponible
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Título con FittedBox para ajuste automático
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: 150, // Ancho máximo del texto
                              ),
                              child: Text(
                                secretaria.nombre,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1.1,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 6),

                        // Descripción sutil - PROTEGIDA CONTRA OVERFLOW
                        Flexible(
                          child: Text(
                            '${secretaria.servicios.length} servicios',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white.withOpacity(0.85),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Botón "Ver detalles" - SIEMPRE VISIBLE
                  Container(
                    width: double.infinity,
                    height: 32, // Altura fija para consistencia
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 12,
                          color: primaryBlue,
                        ),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Ver detalles',
                            style: TextStyle(
                              fontSize: 10,
                              color: primaryBlue,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Resto de métodos sin cambios...
  // Saludo dinámico por tipo de perfil
  String _saludoPorPerfil() {
    final tipo = _usuario?.tipoPerfil;
    switch (tipo) {
      case TipoPerfilCUS.trabajador:
        return 'Hola Trabajador!';
      case TipoPerfilCUS.personaMoral:
      case TipoPerfilCUS.organizacion:
        return 'Hola Organización!';
      case TipoPerfilCUS.ciudadano:
        return 'Hola Ciudadano!';
      case TipoPerfilCUS.usuario:
      default:
        return 'Hola!';
    }
  }

  Widget _buildNewHeader() {
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 80 + statusBarHeight, //* Altura de la barra de estado
          //* Padding para desplazar el contenido debajo de la barra de estado
          padding: const EdgeInsets.only(
            top: 10,
            left: 20,
            right: 20,
            bottom: 16,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF0B3B60),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(40),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'assets/logo_claveunica.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.person_rounded,
                        color: Color.fromARGB(255, 81, 73, 197),
                        size: 28,
                      );
                    },
                  ),
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    final h = constraints.maxHeight;
                    final titleFontSize = w * 0.05; //* 5% del ancho
                    final nameFontSize = w * 0.06; //* 6% del ancho
                    final verticalGap = h * 0.02; //* 2% de la altura

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _saludoPorPerfil(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: titleFontSize.clamp(
                                20, 45), //* mínimo 12, máximo 24
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: verticalGap),
                        Text(
                          (_usuario?.nombre.toUpperCase() ?? 'USUARIO'),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: nameFontSize.clamp(
                                14, 50), //* mínimo 14, máximo 28
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        WeatherCard(
          weatherData: _weatherData,
          isLoading: _isLoadingWeather,
          onRefresh: _refreshWeather,
          latitude: _currentLat,
          longitude: _currentLon,
        ),
        const SizedBox(height: 16),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildAnimatedStatsCards() {
    if (_slideAnimation == null || _fadeAnimation == null) {
      return _buildStatsCardsWithoutAnimation();
    }

    return SlideTransition(
      position: _slideAnimation!,
      child: FadeTransition(
        opacity: _fadeAnimation!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumen de Actividad',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 12),
            _isLoadingStats
                ? _buildLoadingStatsCards()
                : Row(
                    children: [
                      Expanded(
                        child: _buildAnimatedStatCard(
                          '${_estadisticas?.tramitesActivos ?? 0}',
                          'Trámites Activos',
                          Icons.description,
                          const Color(0xFF0B3B60),
                          0,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildAnimatedStatCard(
                          '${_estadisticas?.pendientes ?? 0}',
                          'Pendientes',
                          Icons.schedule,
                          const Color(0xFFD97706),
                          1,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildAnimatedStatCard(
                          '${(_estadisticas?.porcentajeCompletados ?? 0).toStringAsFixed(0)}%',
                          'Completados',
                          Icons.check_circle,
                          const Color(0xFF059669),
                          2,
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCardsWithoutAnimation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Resumen de Actividad',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),
        _isLoadingStats
            ? _buildLoadingStatsCards()
            : Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      '${_estadisticas?.tramitesActivos ?? 0}',
                      'Trámites Activos',
                      Icons.description,
                      const Color(0xFF0B3B60),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      '${_estadisticas?.pendientes ?? 0}',
                      'Pendientes',
                      Icons.schedule,
                      const Color(0xFFD97706),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      '${(_estadisticas?.porcentajeCompletados ?? 0).toStringAsFixed(0)}%',
                      'Completados',
                      Icons.check_circle,
                      const Color(0xFF059669),
                    ),
                  ),
                ],
              ),
      ],
    );
  }

  Widget _buildStatCard(
      String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
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
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedStatCard(
      String value, String label, IconData icon, Color color, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + (index * 200)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, animationValue, child) {
        final safeAnimationValue = animationValue.clamp(0.0, 1.0);

        return Transform.scale(
          scale: safeAnimationValue,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - safeAnimationValue)),
            child: Opacity(
              opacity: safeAnimationValue,
              child: GestureDetector(
                onTap: () {
                  _showStatDetails(label, value);
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: color.withOpacity(0.2),
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
                    children: [
                      Hero(
                        tag: 'stat_icon_$index',
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            icon,
                            color: color,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TweenAnimationBuilder<double>(
                        duration: Duration(milliseconds: 1000 + (index * 200)),
                        tween: Tween(
                            begin: 0.0,
                            end: double.tryParse(value.replaceAll('%', '')) ??
                                0.0),
                        builder: (context, animatedValue, child) {
                          return Text(
                            value.contains('%')
                                ? '${animatedValue.toInt()}%'
                                : '${animatedValue.toInt()}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: color,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showStatDetails(String label, String value) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.analytics,
                size: 48,
                color: Color(0xFF0B3B60),
              ),
              const SizedBox(height: 16),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Valor actual: $value',
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B3B60),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingStatsCards() {
    return Row(
      children: [
        Expanded(child: _buildShimmerStatCard()),
        const SizedBox(width: 12),
        Expanded(child: _buildShimmerStatCard()),
        const SizedBox(width: 12),
        Expanded(child: _buildShimmerStatCard()),
      ],
    );
  }

  Widget _buildShimmerStatCard() {
    if (_pulseAnimation == null) {
      return _buildStaticLoadingCard();
    }

    return AnimatedBuilder(
      animation: _pulseAnimation!,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation!.value,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.withOpacity(0.2),
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
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF0B3B60)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 30,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 60,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStaticLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
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
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0B3B60)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 30,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 60,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedRecentActivity() {
    if (_slideAnimation == null || _fadeAnimation == null) {
      return _buildRecentActivityWithoutAnimation();
    }

    return SlideTransition(
      position: _slideAnimation!,
      child: FadeTransition(
        opacity: _fadeAnimation!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Actividad Reciente',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _page = 2),
                  child: const Text(
                    'Ver todo',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0B3B60),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _isLoadingActivity
                  ? _buildLoadingActivity()
                  : _actividadReciente.isEmpty
                      ? _buildEmptyActivity()
                      : Column(
                          children: _actividadReciente.take(3).map((actividad) {
                            final index = _actividadReciente.indexOf(actividad);
                            return _buildAnimatedActivityItem(actividad, index);
                          }).toList(),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityWithoutAnimation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Actividad Reciente',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _page = 2),
              child: const Text(
                'Ver todo',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0B3B60),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _isLoadingActivity
              ? _buildLoadingActivity()
              : _actividadReciente.isEmpty
                  ? _buildEmptyActivity()
                  : Column(
                      children: _actividadReciente.take(3).map((actividad) {
                        return _buildActivityItem(actividad);
                      }).toList(),
                    ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(ActividadReciente actividad) {
    final index = _actividadReciente.indexOf(actividad);
    final isLast = index == 2 || index == _actividadReciente.length - 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(
                  color: Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: actividad.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              actividad.icono,
              color: actividad.color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  actividad.titulo,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  actividad.descripcion,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatearFecha(actividad.fecha),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: actividad.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              actividad.estado,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: actividad.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedActivityItem(ActividadReciente actividad, int index) {
    final isLast = index == 2 || index == _actividadReciente.length - 1;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + (index * 150)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, animationValue, child) {
        final safeAnimationValue = animationValue.clamp(0.0, 1.0);

        return Transform.translate(
          offset: Offset(50 * (1 - safeAnimationValue), 0),
          child: Opacity(
            opacity: safeAnimationValue,
            child: GestureDetector(
              onTap: () => _showActivityDetails(actividad),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: isLast
                      ? null
                      : const Border(
                          bottom: BorderSide(
                            color: Color(0xFFE5E7EB),
                            width: 1,
                          ),
                        ),
                ),
                child: Row(
                  children: [
                    Hero(
                      tag: 'activity_icon_$index',
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: actividad.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          actividad.icono,
                          color: actividad.color,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            actividad.titulo,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            actividad.descripcion,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatearFecha(actividad.fecha),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: actividad.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        actividad.estado,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: actividad.color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showActivityDetails(ActividadReciente actividad) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                actividad.icono,
                size: 48,
                color: actividad.color,
              ),
              const SizedBox(height: 16),
              Text(
                actividad.titulo,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                actividad.descripcion,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: actividad.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Estado: ${actividad.estado}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: actividad.color,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: actividad.color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingActivity() {
    return Column(
      children: List.generate(3, (index) {
        if (_pulseAnimation == null) {
          return _buildStaticLoadingActivityItem(index);
        }

        return AnimatedBuilder(
          animation: _pulseAnimation!,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation!.value,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: index < 2
                      ? const Border(
                          bottom: BorderSide(
                            color: Color(0xFFE5E7EB),
                            width: 1,
                          ),
                        )
                      : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF0B3B60)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 120,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 180,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 80,
                            height: 11,
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 60,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildStaticLoadingActivityItem(int index) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: index < 2
            ? const Border(
                bottom: BorderSide(
                  color: Color(0xFFE5E7EB),
                  width: 1,
                ),
              )
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0B3B60)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 180,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 80,
                  height: 11,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 60,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyActivity() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, animationValue, child) {
        final safeAnimationValue = animationValue.clamp(0.0, 1.0);

        return Transform.scale(
          scale: safeAnimationValue,
          child: Container(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 48,
                  color: Colors.grey.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No hay actividad reciente',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Cuando realices trámites aparecerán aquí',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF9CA3AF),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatearFecha(DateTime fecha) {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(fecha);

    if (diferencia.inMinutes < 60) {
      return 'Hace ${diferencia.inMinutes} min';
    } else if (diferencia.inHours < 24) {
      return 'Hace ${diferencia.inHours} h';
    } else if (diferencia.inDays < 7) {
      return 'Hace ${diferencia.inDays} días';
    } else {
      return '${fecha.day}/${fecha.month}/${fecha.year}';
    }
  }

  // Construye los íconos de navegación, usando variantes rellenas cuando están seleccionados
  List<Widget> _buildNavItems() {
    const color = Colors.white;
    return [
      Icon(_page == 0 ? Icons.home : Icons.home_outlined, size: 24, color: color),
      Icon(_page == 1 ? Icons.folder : Icons.folder_outlined, size: 24, color: color),
      Icon(_page == 2 ? Icons.description : Icons.description_outlined, size: 24, color: color),
      Icon(_page == 3 ? Icons.account_balance : Icons.account_balance_outlined, size: 24, color: color),
      Icon(_page == 4 ? Icons.person : Icons.person_outline, size: 24, color: color),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _getPageAtIndex(_page),
      bottomNavigationBar: CurvedNavigationBar(
        key: ValueKey<int>(_page),
        index: _page,
        height: 60.0,
        items: _buildNavItems(),
        color: const Color(0xFF0B3B60),
        buttonBackgroundColor: const Color(0xFF0B3B60),
        backgroundColor: Colors.transparent,
        animationDuration: const Duration(milliseconds: 200),
        onTap: (index) => setState(() => _page = index),
      ),
    );
  }
}
