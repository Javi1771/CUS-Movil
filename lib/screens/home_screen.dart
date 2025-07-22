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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// Modelo para actividad reciente
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

// Modelo para estadísticas de actividad
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

  // Datos dinámicos desde la API
  EstadisticasActividad? _estadisticas;
  List<ActividadReciente> _actividadReciente = [];

  // Animaciones - inicializadas como nullable para evitar LateInitializationError
  Animation<double>? _pulseAnimation;
  Animation<Offset>? _slideAnimation;
  Animation<double>? _fadeAnimation;
  Animation<double>? _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeBasics();
    _loadWeatherData();
    _loadResumenGeneral();
  }

  void _initializeAnimations() {
    // Controlador principal
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    // Controlador de pulso para elementos destacados
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Controlador de deslizamiento para entrada de elementos
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Controlador de fade para transiciones suaves
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Crear las animaciones
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

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.elasticOut,
    ));

    // Iniciar animaciones
    _pulseController.repeat(reverse: true);
    _slideController.forward();
    _fadeController.forward();
  }

  void _initializeBasics() async {
    try {
      // Cargar datos reales del usuario desde la API
      _usuario = await UserDataService.getUserData();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('[HomeScreen] Error cargando datos del usuario: $e');
      // En caso de error, usar datos mínimos
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

  Future<void> _loadResumenGeneral() async {
    setState(() {
      _isLoadingStats = true;
      _isLoadingActivity = true;
    });

    try {
      debugPrint('[HomeScreen] ===== CARGANDO DATOS REALES DE TRÁMITES =====');

      // Obtener datos reales de trámites desde la API
      final tramitesResponse = await TramitesService.getTramitesEstados();
      final tramites = tramitesResponse.data;

      debugPrint(
          '[HomeScreen] ✅ ${tramites.length} trámites obtenidos de la API');

      // Calcular estadísticas reales
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

      // Crear actividad reciente basada en trámites reales
      final actividades = tramites
          .take(5) // Tomar los primeros 5 trámites
          .map((tramite) => ActividadReciente(
                titulo: _formatTextWithCapitalization(tramite.nombreTramite),
                descripcion: tramite.descripcionEstado,
                fecha: tramite.ultimaFechaModificacion,
                estado: tramite.nombreEstado,
                icono: tramite.iconoEstado,
                color: tramite.colorEstado,
              ))
          .toList();

      // Ordenar por fecha más reciente
      actividades.sort((a, b) => b.fecha.compareTo(a.fecha));

      if (mounted) {
        setState(() {
          _estadisticas = stats;
          _actividadReciente = actividades;
        });

        debugPrint('[HomeScreen] ✅ Estadísticas calculadas:');
        debugPrint('  - Trámites activos: $tramitesActivos');
        debugPrint('  - Pendientes: $pendientes');
        debugPrint(
            '  - Completados: $completados (${porcentajeCompletados.toStringAsFixed(1)}%)');
        debugPrint('  - Actividades recientes: ${actividades.length}');

        // Reiniciar animaciones cuando se cargan los datos
        _slideController.reset();
        _fadeController.reset();
        _slideController.forward();
        _fadeController.forward();
      }
    } catch (e) {
      debugPrint('[HomeScreen] ❌ Error cargando datos de trámites: $e');

      // En caso de error, usar valores por defecto
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

  /// Formatea texto con capitalización adecuada
  String _formatTextWithCapitalization(String text) {
    if (text.isEmpty) return text;

    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  IconData _getIconoParaTipo(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'licencia':
        return Icons.drive_eta;
      case 'documento':
        return Icons.description;
      case 'constancia':
        return Icons.home;
      case 'permiso':
        return Icons.construction;
      default:
        return Icons.description;
    }
  }

  Color _getColorParaEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'completado':
        return const Color(0xFF059669);
      case 'en proceso':
      case 'pagado':
        return const Color(0xFF0B3B60);
      case 'pendiente':
        return const Color(0xFFD97706);
      default:
        return const Color(0xFF64748B);
    }
  }

  Future<void> _loadWeatherData() async {
    if (_isLoadingWeather) return;

    setState(() {
      _isLoadingWeather = true;
    });

    try {
      debugPrint('[HomeScreen] ===== INICIANDO CARGA DE CLIMA =====');

      WeatherData weatherData;

      // Inicializar servicio de ubicación
      await _locationService.initialize();

      // Verificar si el servicio está listo
      final isReady = await _locationService.isReady();

      if (isReady) {
        debugPrint(
            '[HomeScreen] ✅ Servicio de ubicación listo, obteniendo ubicación actual...');

        // Intentar obtener ubicación actual
        final currentLocation = await _locationService.getCurrentLocation(
          timeout: const Duration(seconds: 8),
        );

        if (currentLocation != null) {
          debugPrint(
              '[HomeScreen] ✅ Ubicación obtenida: ${currentLocation.latitude}, ${currentLocation.longitude}');

          // Obtener clima por coordenadas
          weatherData = await WeatherService.getWeatherByCoordinates(
            lat: currentLocation.latitude,
            lon: currentLocation.longitude,
          );

          debugPrint(
              '[HomeScreen] ✅ Clima obtenido por coordenadas: ${weatherData.city}, ${weatherData.temperatureString}');
        } else {
          debugPrint(
              '[HomeScreen] ⚠️ No se pudo obtener ubicación, usando ciudad por defecto');
          weatherData = await _getDefaultWeather();
        }
      } else {
        debugPrint(
            '[HomeScreen] ⚠️ Servicio de ubicación no disponible, usando ciudad por defecto');
        weatherData = await _getDefaultWeather();
      }

      // Actualizar UI con los datos del clima
      if (mounted) {
        setState(() {
          _weatherData = weatherData;
        });
        debugPrint('[HomeScreen] ✅ UI actualizada con datos del clima');
      }
    } catch (e) {
      debugPrint('[HomeScreen] ❌ Error cargando datos del clima: $e');

      // En caso de error, intentar obtener clima por defecto
      try {
        final fallbackWeather = await _getDefaultWeather();
        if (mounted) {
          setState(() {
            _weatherData = fallbackWeather;
          });
        }
      } catch (fallbackError) {
        debugPrint('[HomeScreen] ❌ Error en fallback: $fallbackError');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingWeather = false;
        });
      }
    }
  }

  Future<WeatherData> _getDefaultWeather() async {
    return await WeatherService.getCurrentWeather(
      city: 'San Juan del Río',
      country: 'MX',
    );
  }

  Future<void> _refreshData() async {
    // Animación de refresh
    _slideController.reset();
    _fadeController.reset();

    await Future.wait([
      _loadWeatherData(),
      _loadResumenGeneral(),
    ]);

    // Reiniciar animaciones después del refresh
    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  String _getFirstName() {
    if (_usuario?.nombre.isNotEmpty == true) {
      final firstName = _usuario!.nombre.split(' ')[0];
      return firstName.isNotEmpty ? firstName : 'Ciudadano';
    }
    return 'Ciudadano';
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
            physics: const BouncingScrollPhysics(), // Scroll más suave
            children: [
              _buildNewHeader(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAnimatedStatsCards(),
                    const SizedBox(height: 24),
                    const SizedBox(height: 24),
                    _buildAnimatedRecentActivity(),
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

  Widget _buildNewHeader() {
    final now = DateTime.now();
    final monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];

    return Column(
      children: [
        // BLOQUE SUPERIOR: CABECERA DE USUARIO - ANCHO COMPLETO
        Container(
          width: double.infinity,
          height: 100,
          decoration: const BoxDecoration(
            color: Color(0xFF0B3B60),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(40),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                // Avatar de usuario - CAMBIADO A IMAGEN
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
                      width: 48,
                      height: 48,
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

                // Texto del usuario
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hola Ciudadano!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (_usuario?.nombre.toUpperCase() ?? 'USUARIO'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 30),

        // BLOQUE INFERIOR: INFORMACIÓN METEOROLÓGICA Y FECHA
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          height: 110,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color(0xFF0B3B60),
            borderRadius: BorderRadius.circular(19),
          ),
          child: Row(
            children: [
              // Ícono de clima
              SizedBox(
                width: 48,
                height: 48,
                child: _isLoadingWeather
                    ? const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                    : Icon(
                        _weatherData?.weatherIcon ?? Icons.wb_sunny_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
              ),

              const SizedBox(width: 18),

              // Datos del clima
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _weatherData?.temperatureString ??
                          (_isLoadingWeather ? '--°C' : '23°C'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Prob. de precipitaciones: ${_weatherData?.humidity ?? 5}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      'Humedad: ${_weatherData?.humidity ?? 55}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      'Viento: a ${_weatherData?.windSpeed.toStringAsFixed(0) ?? 6} km/h',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 18),

              // Ícono de calendario
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    // Barra azul del mes
                    Container(
                      width: double.infinity,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0B3B60),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(10),
                          topRight: Radius.circular(10),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          monthNames[now.month - 1].substring(0, 3),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    // Día
                    Expanded(
                      child: Center(
                        child: Text(
                          '${now.day}',
                          style: const TextStyle(
                            color: Color(0xFF0B3B60),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildAnimatedStatsCards() {
    // Verificar que las animaciones estén inicializadas
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
        // Asegurar que animationValue esté en el rango válido
        final safeAnimationValue = animationValue.clamp(0.0, 1.0);

        return Transform.scale(
          scale: safeAnimationValue,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - safeAnimationValue)),
            child: Opacity(
              opacity: safeAnimationValue,
              child: GestureDetector(
                onTap: () {
                  // Animación de tap
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
    // Verificar que la animación esté inicializada
    if (_pulseAnimation == null) {
      return _buildStaticLoadingCard();
    }

    return AnimatedBuilder(
      animation: _pulseAnimation!,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation!.value
              .clamp(0.0, 2.0), // Limitar el rango de escala
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

  Widget _buildQuickActionsWithoutAnimation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Acciones Rápidas',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                'Nuevo Trámite',
                Icons.add_circle_outline,
                const Color(0xFF0B3B60),
                () => setState(() => _page = 2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                'Mis Documentos',
                Icons.folder_open,
                const Color(0xFF059669),
                () => setState(() => _page = 1),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedQuickActionCard(
      String title, IconData icon, Color color, VoidCallback onTap, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 800 + (index * 200)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, animationValue, child) {
        // Asegurar que animationValue esté en el rango válido
        final safeAnimationValue = animationValue.clamp(0.0, 1.0);

        return Transform.scale(
          scale: safeAnimationValue,
          child: GestureDetector(
            onTap: () {
              // Animación de tap con feedback háptico
              _animateButtonPress();
              onTap();
            },
            onTapDown: (_) => _animateButtonPress(),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Hero(
                    tag: 'action_icon_$index',
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _animateButtonPress() {
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
  }

  Widget _buildAnimatedRecentActivity() {
    // Verificar que las animaciones estén inicializadas
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
        // Asegurar que animationValue esté en el rango válido
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
        // Verificar que la animación esté inicializada
        if (_pulseAnimation == null) {
          return _buildStaticLoadingActivityItem(index);
        }

        return AnimatedBuilder(
          animation: _pulseAnimation!,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation!.value
                  .clamp(0.0, 2.0), // Limitar el rango de escala
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
        // Asegurar que animationValue esté en el rango válido
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _getPageAtIndex(_page),
      bottomNavigationBar: CurvedNavigationBar(
        index: _page,
        height: 60.0,
        items: const [
          Icon(Icons.home_rounded, size: 24, color: Colors.white),
          Icon(Icons.folder_open_rounded, size: 24, color: Colors.white),
          Icon(Icons.description_rounded, size: 24, color: Colors.white),
          Icon(Icons.person_rounded, size: 24, color: Colors.white),
        ],
        color: const Color(0xFF0B3B60),
        buttonBackgroundColor: const Color(0xFF0B3B60),
        backgroundColor: Colors.transparent,
        animationDuration: const Duration(milliseconds: 200),
        onTap: (index) => setState(() => _page = index),
      ),
    );
  }
}
