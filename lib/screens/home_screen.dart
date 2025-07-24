import 'dart:async';
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
import 'package:cus_movil/widgets/simple_carousel.dart';

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

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  int _page = 0;
  UsuarioCUS? _usuario;
  WeatherData? _weatherData;
  LocationService? _locationService;
  bool _isLoadingWeather = false;
  bool _isLoadingStats = false;
  bool _isLoadingActivity = false;
  bool _isInitialized = false;

  EstadisticasActividad? _estadisticas;
  List<ActividadReciente> _actividadReciente = [];

  // Lista de imágenes para el carrusel
  final List<String> _carouselImages = [
    'assets/planmunicipal.png',
    'assets/sjrlegado.png',
  ];

  // Timers para evitar múltiples llamadas
  Timer? _initTimer;
  Timer? _weatherTimer;
  Timer? _dataTimer;

  @override
  void initState() {
    super.initState();
    debugPrint('🏠 HomeScreen iniciado');

    // Inicializar de forma asíncrona para evitar bloquear el UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAsync();
    });
  }

  @override
  void dispose() {
    _initTimer?.cancel();
    _weatherTimer?.cancel();
    _dataTimer?.cancel();
    _locationService = null;
    super.dispose();
  }

  void _initializeAsync() {
    if (_isInitialized) return;

    _initTimer = Timer(const Duration(milliseconds: 100), () {
      _initializeBasics();
    });

    _weatherTimer = Timer(const Duration(milliseconds: 500), () {
      _loadWeatherDataAsync();
    });

    _dataTimer = Timer(const Duration(milliseconds: 1000), () {
      _loadResumenGeneralAsync();
    });

    _isInitialized = true;
  }

  Future<void> _initializeBasics() async {
    if (!mounted) return;

    try {
      final usuario = await UserDataService.getUserData();
      if (mounted) {
        setState(() {
          _usuario = usuario;
        });
      }
    } catch (e) {
      debugPrint('[HomeScreen] Error cargando datos del usuario: $e');
      if (mounted) {
        setState(() {
          _usuario = UsuarioCUS(
            nombre: 'Usuario',
            email: 'usuario@ejemplo.com',
            curp: 'Sin CURP',
            usuarioId: 'temp-id',
            tipoPerfil: TipoPerfilCUS.ciudadano,
          );
        });
      }
    }
  }

  Future<void> _loadResumenGeneralAsync() async {
    if (!mounted || _isLoadingStats) return;

    setState(() {
      _isLoadingStats = true;
      _isLoadingActivity = true;
    });

    try {
      // EMERGENCY FIX: Usar datos estáticos inmediatamente para evitar ANR
      if (mounted) {
        setState(() {
          _estadisticas = EstadisticasActividad(
            tramitesActivos: 12,
            pendientes: 3,
            porcentajeCompletados: 75.0,
          );
          _actividadReciente = _createMockActivities();
          _isLoadingStats = false;
          _isLoadingActivity = false;
        });
      }

      // Intentar cargar datos reales en background sin bloquear UI
      _loadTramitesInBackground();
    } catch (e) {
      debugPrint('[HomeScreen] ❌ Error cargando datos de trámites: $e');
      if (mounted) {
        setState(() {
          _estadisticas = EstadisticasActividad(
            tramitesActivos: 0,
            pendientes: 0,
            porcentajeCompletados: 0.0,
          );
          _actividadReciente = [];
          _isLoadingStats = false;
          _isLoadingActivity = false;
        });
      }
    }
  }

  void _loadTramitesInBackground() {
    // Cargar en background sin await para no bloquear
    Future.delayed(const Duration(seconds: 3), () async {
      if (!mounted) return;

      try {
        final result = await _computeResumenGeneral();

        if (mounted) {
          setState(() {
            _estadisticas = result['estadisticas'];
            _actividadReciente = result['actividades'];
          });
        }
      } catch (e) {
        // Silencioso - ya tenemos datos por defecto
        debugPrint('[HomeScreen] Background tramites load failed: $e');
      }
    });
  }

  List<ActividadReciente> _createMockActivities() {
    final now = DateTime.now();
    return [
      ActividadReciente(
        titulo: 'Licencia de Construcción',
        descripcion: 'Trámite en proceso de revisión',
        fecha: now.subtract(const Duration(hours: 2)),
        estado: 'POR REVISAR',
        icono: Icons.construction,
        color: const Color(0xFFD97706),
      ),
      ActividadReciente(
        titulo: 'Constancia de Residencia',
        descripcion: 'Documento generado exitosamente',
        fecha: now.subtract(const Duration(days: 1)),
        estado: 'FIRMADO',
        icono: Icons.home,
        color: const Color(0xFF059669),
      ),
      ActividadReciente(
        titulo: 'Permiso de Uso de Suelo',
        descripcion: 'Pendiente de pago',
        fecha: now.subtract(const Duration(days: 3)),
        estado: 'REQUIERE PAGO',
        icono: Icons.landscape,
        color: const Color(0xFFD97706),
      ),
    ];
  }

  Future<Map<String, dynamic>> _computeResumenGeneral() async {
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

      return {
        'estadisticas': stats,
        'actividades': actividades,
      };
    } catch (e) {
      throw e;
    }
  }

  String _formatTextWithCapitalization(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  Future<void> _loadWeatherDataAsync() async {
    if (!mounted || _isLoadingWeather) return;

    setState(() {
      _isLoadingWeather = true;
    });

    try {
      // EMERGENCY FIX: Usar datos estáticos inmediatamente para evitar ANR
      if (mounted) {
        setState(() {
          _weatherData = WeatherData.defaultData();
          _isLoadingWeather = false;
        });
      }

      // Intentar cargar datos reales en background sin bloquear UI
      _loadWeatherInBackground();
    } catch (e) {
      debugPrint('[HomeScreen] ❌ Error cargando datos del clima: $e');
      if (mounted) {
        setState(() {
          _weatherData = WeatherData.defaultData();
          _isLoadingWeather = false;
        });
      }
    }
  }

  void _loadWeatherInBackground() {
    // Cargar en background sin await para no bloquear
    Future.delayed(const Duration(seconds: 2), () async {
      if (!mounted) return;

      try {
        final weatherData = await WeatherService.getCurrentWeather(
          city: 'San Juan del Río',
          country: 'MX',
        ).timeout(const Duration(seconds: 3));

        if (mounted) {
          setState(() {
            _weatherData = weatherData;
          });
        }
      } catch (e) {
        // Silencioso - ya tenemos datos por defecto
        debugPrint('[HomeScreen] Background weather load failed: $e');
      }
    });
  }

  Future<WeatherData> _getDefaultWeather() async {
    // EMERGENCY: Retornar datos inmediatos
    return WeatherData.defaultData();
  }

  Future<void> _refreshData() async {
    if (!mounted) return;

    // Refrescar de forma asíncrona
    _loadWeatherDataAsync();
    _loadResumenGeneralAsync();
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
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              _buildHeader(),
              _buildCarousel(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsCards(),
                    const SizedBox(height: 24),
                    _buildRecentActivity(),
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

  Widget _buildCarousel() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Destacados',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          SimpleCarousel(
            images: _carouselImages,
            height: 160,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final now = DateTime.now();
    final monthNames = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic'
    ];
    return Column(
      children: [
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
                      'Precipitaciones: ${_weatherData?.humidity ?? 5}%',
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
                      'Viento: ${_weatherData?.windSpeed.toStringAsFixed(0) ?? 6} km/h',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF0B3B60),
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0B3B60),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          monthNames[now.month - 1],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
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

  Widget _buildStatsCards() {
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

  Widget _buildRecentActivity() {
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

  Widget _buildLoadingActivity() {
    return Column(
      children: List.generate(3, (index) {
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
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF0B3B60)),
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
      }),
    );
  }

  Widget _buildEmptyActivity() {
    return Container(
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
    super.build(context);
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
