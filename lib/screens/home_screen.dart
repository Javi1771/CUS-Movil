import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

// Imports locales usando rutas relativas
import 'perfil_usuario_screen.dart';
import 'mis_documentos_screen.dart';
import 'tramites_screen.dart';
import 'secretarias_screen.dart';
import '../services/weather_service.dart';
import '../services/location_service.dart';
import '../services/user_data_service.dart';
import '../services/tramites_service.dart';
import '../models/usuario_cus.dart';
import '../models/weather_data.dart';
import '../models/secretaria.dart';

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

  Future<void> _loadResumenGeneral() async {
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
    try {
      setState(() => _isLoadingWeather = true);
      final data = await WeatherService.getByCoords(lat: lat, lon: lon);
      if (!mounted) return;
      setState(() => _weatherData = data);
    } catch (e) {
      debugPrint('Error al obtener el clima: $e');
    } finally {
      if (mounted) setState(() => _isLoadingWeather = false);
    }
  }

  Future<void> _initWeather() async {
    if (_isLoadingWeather) return;
    setState(() => _isLoadingWeather = true);

    try {
      await _locationService.initialize();
      final isReady = await _locationService.isReady();

      if (isReady) {
        final currentLocation = await _locationService.getCurrentLocation(
          timeout: const Duration(seconds: 8),
        );

        if (currentLocation != null) {
          await _fetchWeather(
            currentLocation.latitude, 
            currentLocation.longitude
          );
        }

        _posSub?.cancel();
        _posSub = _locationService.getPositionStream(
          distanceFilter: 300,
        ).listen(
          (pos) => _fetchWeather(pos.latitude, pos.longitude),
          onError: (e) => debugPrint('Error en stream de ubicación: $e'),
        );
      }
    } catch (e) {
      debugPrint('Error inicializando clima: $e');
    } finally {
      if (mounted) setState(() => _isLoadingWeather = false);
    }
  }

  Future<void> _refreshWeather() async {
    try {
      setState(() => _isLoadingWeather = true);
      final currentLocation = await _locationService.getCurrentLocation(
        timeout: const Duration(seconds: 8),
      );

      if (currentLocation != null) {
        await _fetchWeather(
          currentLocation.latitude, 
          currentLocation.longitude
        );
      }
    } catch (e) {
      debugPrint('Error refrescando clima: $e');
    } finally {
      if (mounted) setState(() => _isLoadingWeather = false);
    }
  }

  Future<void> _refreshData() async {
    _slideController.reset();
    _fadeController.reset();

    await Future.wait([
      _refreshWeather(),
      _loadResumenGeneral(),
    ]);

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
                  'Secretarías de Gobierno',
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
              'Secretarías de Gobierno',
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
    final color = Color(int.parse(secretaria.color.replaceFirst('#', '0xFF')));
    
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
        height: 160, // Altura fija para evitar overflow
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              color.withOpacity(0.02),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: color.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => setState(() => _page = 3),
            splashColor: color.withOpacity(0.1),
            highlightColor: color.withOpacity(0.05),
            child: Padding(
              padding: const EdgeInsets.all(14), // Reducido de 16 a 14
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // Importante para evitar overflow
                children: [
                  // Header con icono mejorado
                  Row(
                    children: [
                      Container(
                        width: 42, // Reducido de 48 a 42
                        height: 42, // Reducido de 48 a 42
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              color,
                              color.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12), // Reducido de 14 a 12
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.3),
                              blurRadius: 6, // Reducido de 8 a 6
                              offset: const Offset(0, 3), // Reducido de 4 a 3
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.account_balance,
                          color: Colors.white,
                          size: 22, // Reducido de 24 a 22
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6, // Reducido de 8 a 6
                          vertical: 3, // Reducido de 4 a 3
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10), // Reducido de 12 a 10
                          border: Border.all(
                            color: color.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '${secretaria.servicios.length}',
                          style: TextStyle(
                            fontSize: 11, // Reducido de 12 a 11
                            color: color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12), // Reducido de 16 a 12
                  
                  // Título mejorado con Flexible para evitar overflow
                  Flexible(
                    child: Text(
                      secretaria.nombre,
                      style: const TextStyle(
                        fontSize: 13, // Reducido de 14 a 13
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                        height: 1.1, // Reducido de 1.2 a 1.1
                        letterSpacing: -0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  const SizedBox(height: 6), // Reducido de 8 a 6
                  
                  // Descripción de servicios
                  Text(
                    '${secretaria.servicios.length} servicios',
                    style: TextStyle(
                      fontSize: 11, // Reducido de 12 a 11
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Footer con indicador de acción
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 6), // Reducido de 8 a 6
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8), // Reducido de 10 a 8
                      border: Border.all(
                        color: color.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 12, // Reducido de 14 a 12
                          color: color,
                        ),
                        const SizedBox(width: 4), // Reducido de 6 a 4
                        Text(
                          'Ver detalles',
                          style: TextStyle(
                            fontSize: 10, // Reducido de 11 a 10
                            color: color,
                            fontWeight: FontWeight.w600,
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

  Widget _buildNewHeader() {
    final now = DateTime.now();
    final monthNames = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
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
                        color: _weatherData?.weatherColor ?? Colors.white,
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
                      _weatherData?.temperatureString ?? '--°C',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _weatherData?.capitalizedDescription ?? 'Cargando...',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    Text(
                      'Humedad: ${_weatherData?.humidity ?? '--'}%',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    Text(
                      'Viento: ${_weatherData != null ? (_weatherData!.windSpeed * 3.6).round() : '--'} km/h',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
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
                ),
                child: Column(
                  children: [
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
          Icon(Icons.account_balance, size: 24, color: Colors.white),
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