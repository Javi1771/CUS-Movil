import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:cus_movil/screens/perfil_usuario_screen.dart';
import 'package:cus_movil/screens/mis_documentos_screen.dart';
import 'package:cus_movil/screens/tramites_screen.dart';
import 'package:cus_movil/services/weather_service.dart';
import 'package:cus_movil/services/location_service.dart';
import 'package:cus_movil/models/usuario_cus.dart';
import 'package:geolocator/geolocator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _page = 0;
  UsuarioCUS? _usuario;
  WeatherData? _weatherData;
  late AnimationController _animationController;
  final LocationService _locationService = LocationService();
  bool _isLoadingWeather = false;

  @override
  void initState() {
    super.initState();
    _initializeBasics();
    _loadWeatherData();
  }

  void _initializeBasics() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _usuario = UsuarioCUS(
      nombre: 'Javier Lopez Camacho',
      email: 'ciudadano@sanjuan.gob.mx',
      curp: 'TEMP123456789',
      usuarioId: 'temp-id',
      tipoPerfil: TipoPerfilCUS.ciudadano,
    );

    // No inicializar _weatherData con datos fijos
    // Se cargará desde la API
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
        // Solo en caso de error total, no mostrar nada (weatherData permanece null)
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

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _getFirstName() {
    if (_usuario?.nombre?.isNotEmpty == true) {
      final firstName = _usuario!.nombre!.split(' ')[0];
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadWeatherData,
          color: const Color(0xFF0B3B60), // Azul consistente
          backgroundColor: Colors.white,
          child: ListView(
            padding: EdgeInsets.zero, // Sin padding para que el banner llegue a las orillas
            children: [
              _buildNewHeader(),
              Padding(
                padding: const EdgeInsets.all(8),
                child: _buildSimpleContent(),
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
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    return Column(
      children: [
        // BLOQUE SUPERIOR: CABECERA DE USUARIO - ANCHO COMPLETO
        Container(
          width: double.infinity,
          height: 100,
          decoration: const BoxDecoration(
            color: Color(0xFF0B3B60), // Azul consistente
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(40),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                // Avatar de usuario
                Container(
                  width: 48,
                  height: 48,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.grey,
                    size: 28,
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
                        (_usuario?.nombre?.toUpperCase() ?? 'JAVIER LOPEZ CAMACHO'),
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
        
        const SizedBox(height: 8), // Espacio entre bloques
        
        // BLOQUE INFERIOR: INFORMACIÓN METEOROLÓGICA Y FECHA
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          height: 90,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF0B3B60), // Azul consistente
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              // Ícono de clima
              Container(
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
              
              const SizedBox(width: 18), // Espacio fijo después del ícono
              
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
                      'Viento: a ${_weatherData?.windSpeed?.toStringAsFixed(0) ?? 6} km/h',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 18), // Espacio antes del calendario
              
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
                        color: Color(0xFF0B3B60), // Azul consistente
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
                            color: Color(0xFF0B3B60), // Azul consistente
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
        
        const SizedBox(height: 16), // Espacio después del banner
      ],
    );
  }

  Widget _buildSimpleContent() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Servicios',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0B3B60)), // Azul consistente
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: _buildMiniCard('12', 'Activos', Icons.description)),
              const SizedBox(width: 4),
              Expanded(
                  child: _buildMiniCard('3', 'Pendientes', Icons.schedule)),
              const SizedBox(width: 4),
              Expanded(
                  child: _buildMiniCard('85%', 'Completados', Icons.check)),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Acceso Rápido',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0B3B60)), // Azul consistente
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: _buildQuickButton('Trámites', Icons.description,
                      () => setState(() => _page = 2))),
              const SizedBox(width: 4),
              Expanded(
                  child: _buildQuickButton('Archivos', Icons.folder,
                      () => setState(() => _page = 1))),
              const SizedBox(width: 4),
              Expanded(
                  child: _buildQuickButton(
                      'Perfil', Icons.person, () => setState(() => _page = 3))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCard(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF0B3B60)), // Azul consistente
          const SizedBox(height: 2),
          Text(value,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          Text(label, style: const TextStyle(fontSize: 8, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildQuickButton(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF0B3B60).withOpacity(0.1), // Azul consistente
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF0B3B60)), // Azul consistente
            const SizedBox(height: 2),
            Text(title,
                style: const TextStyle(fontSize: 10, color: Color(0xFF0B3B60))), // Azul consistente
          ],
        ),
      ),
    );
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
        color: const Color(0xFF0B3B60), // Azul consistente
        buttonBackgroundColor: const Color(0xFF0B3B60), // Azul consistente
        backgroundColor: Colors.transparent,
        animationDuration: const Duration(milliseconds: 200),
        onTap: (index) => setState(() => _page = index),
      ),
    );
  }
}