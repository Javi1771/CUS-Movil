import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:cus_movil/screens/perfil_usuario_screen.dart';
import 'package:cus_movil/screens/mis_documentos_screen.dart';
import 'package:cus_movil/screens/tramites_screen.dart';
import 'package:cus_movil/services/user_data_service.dart';
import 'package:cus_movil/services/weather_service.dart';
import 'package:cus_movil/services/auth_service.dart';
import 'package:cus_movil/models/usuario_cus.dart';
import '../utils/ui_optimizer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> 
    with TickerProviderStateMixin, UIOptimizationMixin {
  int _page = 0;
  final GlobalKey _bottomNavigationKey = GlobalKey();

  UsuarioCUS? _usuario;
  WeatherData? _weatherData;
  bool _isLoadingUser = true;
  bool _isLoadingWeather = true;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  List<Widget> pages = [];

  // Datos de actividad reciente de trámites
  final List<Map<String, dynamic>> _recentActivity = [
    {
      'title': 'Solicitud de CURP',
      'subtitle': 'Trámite completado exitosamente',
      'time': DateTime.now().subtract(const Duration(hours: 2)),
      'icon': Icons.description,
      'color': const Color(0xFF00AE6F),
      'status': 'completed'
    },
    {
      'title': 'Constancia de Domicilio',
      'subtitle': 'Documento generado y disponible',
      'time': DateTime.now().subtract(const Duration(hours: 8)),
      'icon': Icons.home,
      'color': const Color(0xFF0B3B60),
      'status': 'ready'
    },
    {
      'title': 'Pago de Predial',
      'subtitle': 'Pago procesado correctamente',
      'time': DateTime.now().subtract(const Duration(days: 1)),
      'icon': Icons.payment,
      'color': const Color(0xFF00B2E2),
      'status': 'paid'
    },
    {
      'title': 'Licencia de Funcionamiento',
      'subtitle': 'En proceso de revisión',
      'time': DateTime.now().subtract(const Duration(days: 2)),
      'icon': Icons.business,
      'color': const Color(0xFFE67425),
      'status': 'pending'
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializePages();
    _loadAllData();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    _animationController.forward();
  }

  void _initializePages() {
    // Initialize pages lazily to improve startup performance
    pages = [
      _buildHomePage(),
      Container(), // Placeholder - will be loaded when needed
      Container(), // Placeholder - will be loaded when needed
      Container(), // Placeholder - will be loaded when needed
    ];
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

  Future<void> _loadAllData() async {
    // Load data sequentially to avoid overwhelming the main thread
    await _loadUserData();
    
    // Load weather data in background without blocking UI
    _loadWeatherDataInBackground();
  }
  
  void _loadWeatherDataInBackground() {
    // Use a separate isolate or delayed execution to avoid blocking
    Future.delayed(const Duration(milliseconds: 500), () {
      _loadWeatherData();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      // First try to load from auth service (faster, local data)
      final authService = AuthService('temp');
      final userData = await authService.getUserData();

      if (userData != null && mounted) {
        String? nombre = _extractNameFromAuthData(userData);
        if (nombre != null && nombre.isNotEmpty) {
          final usuarioAuth = UsuarioCUS(
            nombre: nombre,
            email: userData['email'] ?? 'usuario@ejemplo.com',
            curp: userData['curp'] ?? 'TEMP123456789',
            usuarioId: userData['id']?.toString() ?? 'auth-user',
            tipoPerfil: TipoPerfilCUS.ciudadano,
          );

          setState(() {
            _usuario = usuarioAuth;
            _isLoadingUser = false;
          });
          
          // Load full user data in background
          _loadFullUserDataInBackground();
          return;
        }
      }
      
      // If auth data not available, try API with timeout
      final usuario = await UserDataService.getUserData()
          .timeout(const Duration(seconds: 5));
      
      if (mounted) {
        setState(() {
          _usuario = usuario;
          _isLoadingUser = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando datos del usuario: $e');
      _setFallbackUser();
    }
  }
  
  void _loadFullUserDataInBackground() {
    // Load complete user data without blocking UI
    Future.delayed(const Duration(milliseconds: 1000), () async {
      try {
        final usuario = await UserDataService.getUserData()
            .timeout(const Duration(seconds: 10));
        if (mounted && usuario != null) {
          setState(() {
            _usuario = usuario;
          });
        }
      } catch (e) {
        debugPrint('Error loading full user data in background: $e');
      }
    });
  }

  String? _extractNameFromAuthData(Map<String, dynamic> userData) {
    final nameFields = [
      'nombre',
      'name',
      'username',
      'user',
      'displayName',
      'first_name',
      'firstName',
      'full_name',
      'fullName'
    ];

    for (String field in nameFields) {
      if (userData.containsKey(field) && userData[field] != null) {
        return userData[field].toString();
      }
    }
    return null;
  }

  void _setFallbackUser() {
    final usuarioTemp = UsuarioCUS(
      nombre: 'Ciudadano',
      email: 'ciudadano@sanjuan.gob.mx',
      curp: 'TEMP123456789',
      usuarioId: 'temp-id',
      tipoPerfil: TipoPerfilCUS.ciudadano,
    );

    if (mounted) {
      setState(() {
        _usuario = usuarioTemp;
        _isLoadingUser = false;
      });
    }
  }

  Future<void> _loadWeatherData() async {
    try {
      final weather = await WeatherService.getCurrentWeather(
        city: 'San Juan del Río',
        country: 'MX',
      );

      if (mounted) {
        setState(() {
          _weatherData = weather;
          _isLoadingWeather = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando datos del clima: $e');
      _setMockWeatherData();
    }
  }

  void _setMockWeatherData() {
    try {
      final mockWeather = WeatherData(
        city: 'San Juan del Río',
        temperature: 22.0,
        description: 'parcialmente nublado',
        icon: '02d',
        humidity: 65,
        windSpeed: 3.5,
      );

      if (mounted) {
        setState(() {
          _weatherData = mockWeather;
          _isLoadingWeather = false;
        });
      }
    } catch (e) {
      debugPrint('Error setting mock weather data: $e');
      if (mounted) {
        setState(() {
          _weatherData = null;
          _isLoadingWeather = false;
        });
      }
    }
  }

  String _getFirstName() {
    if (_usuario?.nombre?.isNotEmpty == true) {
      final firstName = _usuario!.nombre!.split(' ')[0];
      return firstName.isNotEmpty ? firstName : 'Ciudadano';
    }
    return 'Ciudadano';
  }

  String _getGreetingMessage() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Buenos días. Bienvenido al portal ciudadano.';
    } else if (hour < 18) {
      return 'Buenas tardes. ¿En qué podemos ayudarte hoy?';
    } else {
      return 'Buenas noches. Gestiona tus trámites fácilmente.';
    }
  }

  Widget _buildWeatherCard() {
    if (_isLoadingWeather) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Row(
          children: [
            CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0B3B60)),
            ),
            SizedBox(width: 16),
            Text(
              'Cargando información del clima...',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    if (_weatherData == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _weatherData!.weatherColor.withOpacity(0.1),
            _weatherData!.weatherColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _weatherData!.weatherColor.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _weatherData!.weatherColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _weatherData!.weatherIcon,
              color: _weatherData!.weatherColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      size: 16,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _weatherData!.city,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _weatherData!.temperatureString,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: _weatherData!.weatherColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _weatherData!.capitalizedDescription,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.water_drop,
                    size: 14,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_weatherData!.humidity}%',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.air,
                    size: 14,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_weatherData!.windSpeed.toStringAsFixed(1)} km/h',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHomePage() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0B3B60),
              Color(0xFF1A5490),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                _buildHeader(),
                _buildMainContent(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstitutionalFooter() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0B3B60),
            Color(0xFF1A5490),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B3B60).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/logo_blanco.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.account_balance,
                        color: Colors.white,
                        size: 28,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Municipio de San Juan del Río',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Administración 2021-2024',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            child: const Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.security,
                      color: Colors.white,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Plataforma segura y confiable',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.support_agent,
                      color: Colors.white,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Soporte técnico disponible 24/7',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.verified_user,
                      color: Colors.white,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Certificado por el Gobierno del Estado',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGovernmentImageHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo principal del gobierno - más grande y prominente
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0B3B60).withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/logo_institucional.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // Si falla, intentar con otro logo
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/logo_sjr.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback final con icono
                        return Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF0B3B60),
                                Color(0xFF1A5490),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.account_balance,
                            color: Colors.white,
                            size: 60,
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Información institucional
          const Text(
            'Gobierno Municipal',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0B3B60),
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'San Juan del Río, Querétaro',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Badges oficiales
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00AE6F).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF00AE6F).withOpacity(0.3),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified,
                      size: 16,
                      color: Color(0xFF00AE6F),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Portal Oficial',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF00AE6F),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B3B60).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF0B3B60).withOpacity(0.3),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.security,
                      size: 16,
                      color: Color(0xFF0B3B60),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Seguro',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0B3B60),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildWelcomeSection(),
          const SizedBox(height: 16),
          _buildWeatherCard(),
        ],
      ),
    );
  }

  Widget _buildGovernmentBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00AE6F).withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/mejor_sanjuan.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.flag,
                    color: Color(0xFF00AE6F),
                    size: 20,
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Portal Oficial de Servicios Digitales',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0B3B60),
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  'Gobierno Transparente y Eficiente',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF00AE6F).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified,
                  size: 12,
                  color: Color(0xFF00AE6F),
                ),
                SizedBox(width: 4),
                Text(
                  'Verificado',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF00AE6F),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return optimizedBuild('welcome_section', () {
      return UIOptimizer().optimizeOverflow(
        enableClipping: true,
        child: Container(
          padding: const EdgeInsets.all(20), // Reducido de 24 a 20
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20), // Reducido de 24 a 20
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0b3b60).withOpacity(0.08),
                blurRadius: 20, // Reducido de 24 a 20
                offset: const Offset(0, 4), // Reducido de 6 a 4
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Prevenir overflow vertical
            children: [
              // Header con saludo personalizado
              Row(
                children: [
                  // Avatar del usuario
                  Container(
                    width: 45, // Reducido de 50 a 45
                    height: 45, // Reducido de 50 a 45
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF0b3b60),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0b3b60).withOpacity(0.3),
                          blurRadius: 8, // Reducido de 12 a 8
                          offset: const Offset(0, 2), // Reducido de 4 a 2
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 22, // Reducido de 26 a 22
                    ),
                  ),
                  const SizedBox(width: 12), // Reducido de 16 a 12
                  // Saludo y descripción
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Hola, ${_getFirstName()}',
                          style: const TextStyle(
                            fontSize: 18, // Reducido de 20 a 18
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0b3b60),
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Portal Ciudadano Activo',
                          style: TextStyle(
                            fontSize: 12, // Reducido de 13 a 12
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Logo blanco
                  Container(
                    width: 40, // Reducido de 44 a 40
                    height: 40, // Reducido de 44 a 40
                    decoration: BoxDecoration(
                      color: const Color(0xFF00AE6F).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10), // Reducido de 12 a 10
                      border: Border.all(
                        color: const Color(0xFF00AE6F).withOpacity(0.2),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: UIOptimizer().optimizeImage(
                        assetPath: 'assets/images/logo_blanco.png',
                        width: 40,
                        height: 40,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20), // Reducido de 24 a 20
              // Tarjeta principal con información
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20), // Reducido de 24 a 20
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF39b0f7),
                      Color(0xFF0f96e8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16), // Reducido de 20 a 16
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF39b0f7).withOpacity(0.3),
                      blurRadius: 12, // Reducido de 16 a 12
                      offset: const Offset(0, 6), // Reducido de 8 a 6
                    ),
                  ],
                ),
                child: IntrinsicHeight( // Prevenir overflow vertical
                  child: Row(
                    children: [
                      // Contenido de texto
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Clave Única San Juanense',
                              style: TextStyle(
                                fontSize: 16, // Reducido de 18 a 16
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6), // Reducido de 8 a 6
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_rounded,
                                  color: Colors.white70,
                                  size: 14, // Reducido de 16 a 14
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: const Text(
                                    'San Juan del Río, Qro.',
                                    style: TextStyle(
                                      fontSize: 12, // Reducido de 13 a 12
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white70,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12), // Reducido de 16 a 12
                            const Text(
                              '18°C',
                              style: TextStyle(
                                fontSize: 32, // Reducido de 36 a 32
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.0,
                              ),
                            ),
                            const Text(
                              'Clima actual',
                              style: TextStyle(
                                fontSize: 11, // Reducido de 12 a 11
                                fontWeight: FontWeight.w500,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Ilustración con imagen mejor_sanjuan
                      Expanded(
                        flex: 2,
                        child: Container(
                          height: 100, // Reducido de 120 a 100
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12), // Reducido de 16 a 12
                          ),
                          child: Center(
                            child: UIOptimizer().optimizeImage(
                              assetPath: 'assets/images/mejor_sanjuan.png',
                              width: 70, // Reducido de 80 a 70
                              height: 70, // Reducido de 80 a 70
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildMainContent() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildQuickStats(),
          _buildRecentActivity(),
          _buildQuickAccess(),
          const SizedBox(height: 100), // Espacio para el bottom navigation
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen de Actividad',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0B3B60),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard('12', 'Trámites\nActivos',
                    Icons.description_rounded, const Color(0xFF0B3B60)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard('3', 'Pendientes',
                    Icons.pending_actions_rounded, const Color(0xFFE67425)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard('98%', 'Completados',
                    Icons.check_circle_rounded, const Color(0xFF00AE6F)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return optimizedBuild('recent_activity', () {
      return UIOptimizer().optimizeOverflow(
        enableClipping: true,
        child: Container(
          margin: const EdgeInsets.all(16), // Reducido de 20 a 16
          padding: const EdgeInsets.all(16), // Reducido de 20 a 16
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16), // Reducido de 20 a 16
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12, // Reducido de 15 a 12
                offset: const Offset(0, 4), // Reducido de 5 a 4
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.history,
                          color: const Color(0xFF0B3B60),
                          size: 18, // Reducido de 20 a 18
                        ),
                        const SizedBox(width: 6), // Reducido de 8 a 6
                        Expanded(
                          child: const Text(
                            'Actividad Reciente',
                            style: TextStyle(
                              fontSize: 16, // Reducido de 18 a 16
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0B3B60),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() => _page = 2);
                    },
                    child: const Text(
                      'Ver todos',
                      style: TextStyle(
                        color: Color(0xFF0B3B60),
                        fontWeight: FontWeight.w600,
                        fontSize: 14, // Añadido tamaño específico
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12), // Reducido de 16 a 12
              // Usar ListView.builder para mejor rendimiento
              UIOptimizer().optimizeListView(
                itemCount: _recentActivity.take(3).length,
                itemBuilder: (context, index) {
                  final activity = _recentActivity[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index < 2 ? 8 : 0, // Reducido de 12 a 8
                    ),
                    child: _buildActivityItem(activity),
                  );
                },
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    final DateTime time = activity['time'];
    final String timeAgo = _getTimeAgo(time);

    return UIOptimizer().optimizeOverflow(
      enableClipping: true,
      child: Container(
        padding: const EdgeInsets.all(12), // Reducido de 16 a 12
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10), // Reducido de 12 a 10
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Icon(
                activity['icon'],
                color: activity['color'],
                size: 20, // Reducido de 24 a 20
              ),
              const SizedBox(width: 12), // Reducido de 16 a 12
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      activity['title'],
                      style: const TextStyle(
                        fontSize: 13, // Reducido de 14 a 13
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0B3B60),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3), // Reducido de 4 a 3
                    Text(
                      activity['subtitle'],
                      style: TextStyle(
                        fontSize: 11, // Reducido de 12 a 11
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4), // Reducido de 6 a 4
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 10, // Reducido de 12 a 10
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 3), // Reducido de 4 a 3
                        Expanded(
                          child: Text(
                            timeAgo,
                            style: TextStyle(
                              fontSize: 10, // Reducido de 11 a 10
                              color: Colors.grey.shade500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _buildStatusBadge(activity['status']),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    String label;

    switch (status) {
      case 'completed':
        backgroundColor = const Color(0xFF00AE6F);
        label = 'Completado';
        break;
      case 'ready':
        backgroundColor = const Color(0xFF0B3B60);
        label = 'Listo';
        break;
      case 'paid':
        backgroundColor = const Color(0xFF00B2E2);
        label = 'Pagado';
        break;
      case 'pending':
        backgroundColor = const Color(0xFFE67425);
        label = 'Pendiente';
        break;
      default:
        backgroundColor = Colors.grey;
        label = 'En proceso';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: backgroundColor,
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return 'Hace ${difference.inDays} día${difference.inDays == 1 ? '' : 's'}';
    } else if (difference.inHours > 0) {
      return 'Hace ${difference.inHours} hora${difference.inHours == 1 ? '' : 's'}';
    } else if (difference.inMinutes > 0) {
      return 'Hace ${difference.inMinutes} minuto${difference.inMinutes == 1 ? '' : 's'}';
    } else {
      return 'Hace un momento';
    }
  }

  Widget _buildQuickAccess() {
    final quickActions = [
      {
        'title': 'Trámites',
        'subtitle': 'Gestionar servicios',
        'icon': Icons.description_rounded,
        'color': const Color(0xFF0B3B60),
        'action': () {
          if (pages.isNotEmpty && pages.length > 2) {
            setState(() => _page = 2);
          }
        }
      },
      {
        'title': 'Archivos',
        'subtitle': 'Ver documentos',
        'icon': Icons.folder_rounded,
        'color': const Color(0xFF00AE6F),
        'action': () {
          if (pages.isNotEmpty && pages.length > 1) {
            setState(() => _page = 1);
          }
        }
      },
      {
        'title': 'Perfil',
        'subtitle': 'Configuración',
        'icon': Icons.person_rounded,
        'color': const Color(0xFFE67425),
        'action': () {
          if (pages.isNotEmpty && pages.length > 3) {
            setState(() => _page = 3);
          }
        }
      },
      {
        'title': 'Ayuda',
        'subtitle': 'Soporte técnico',
        'icon': Icons.help_rounded,
        'color': const Color(0xFFCE1D81),
        'action': () => _showSupportDialog()
      },
    ];

    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Servicios Principales',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0B3B60),
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
            ),
            itemCount: quickActions.length,
            itemBuilder: (context, index) {
              final action = quickActions[index];
              return _buildQuickAccessCard(action);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessCard(Map<String, dynamic> action) {
    return GestureDetector(
      onTap: action['action'],
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: action['color'].withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: action['color'].withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: action['color'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                action['icon'],
                color: action['color'],
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              action['title'],
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: action['color'],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              action['subtitle'],
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showSupportDialog() {
    showDialog(
      context: context,
      barrierDismissible: true, // Permite cerrar tocando fuera del diálogo
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Soporte Técnico',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: const Text(
            'Para obtener ayuda, contacte al departamento de sistemas municipales.',
            style: TextStyle(
              fontSize: 16,
              height: 1.4, // Mejora el espaciado entre líneas
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor:
                    const Color(0xFF0B3B60), // Color consistente con tu tema
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text(
                'Cerrar',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          actionsPadding: const EdgeInsets.fromLTRB(0, 0, 16, 16),
        );
      },
    );
  }

// Alternativa más completa con más opciones:
  void _showSupportDialogAdvanced() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.support_agent,
                color: const Color(0xFF0B3B60),
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Soporte Técnico',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Para obtener ayuda, contacte al departamento de sistemas municipales.',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Información de contacto:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.email, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        const Text(
                          'sistemas@municipio.gob.mx',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        const Text(
                          'Ext. 1234',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade600,
              ),
              child: const Text('Cerrar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Aquí puedes agregar lógica para abrir email o teléfono
                // Por ejemplo: launch('mailto:sistemas@municipio.gob.mx');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B3B60),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Contactar'),
            ),
          ],
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _getPageAtIndex(_page),
      bottomNavigationBar: CurvedNavigationBar(
        key: _bottomNavigationKey,
        index: _page,
        height: 65.0,
        items: const [
          Icon(Icons.home_rounded, size: 30, color: Colors.white),
          Icon(Icons.folder_open_rounded, size: 30, color: Colors.white),
          Icon(Icons.description_rounded, size: 30, color: Colors.white),
          Icon(Icons.person_rounded, size: 30, color: Colors.white),
        ],
        color: const Color(0xFF0B3B60),
        buttonBackgroundColor: const Color(0xFF0B3B60),
        backgroundColor: Colors.transparent,
        animationCurve: Curves.easeInOutBack,
        animationDuration: const Duration(milliseconds: 300), // Reduced animation time
        onTap: (index) {
          setState(() {
            _page = index;
          });
        },
      ),
    );
  }
}
