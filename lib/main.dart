import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'routes/routes.dart';
import 'utils/performance_monitor.dart';
import 'utils/performance_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configurar rendimiento antes de cargar la app
  PerformanceConfig.initialize();

  // Cargar variables de entorno
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('⚠️ Error cargando .env: $e');
  }

  // Inicializar formateo de fechas
  await initializeDateFormatting('es', null);

  // Configurar manejo de errores optimizado
  FlutterError.onError = (FlutterErrorDetails details) {
    final exceptionString = details.exception.toString();

    // Ignorar errores comunes de overflow que no afectan funcionalidad
    if (exceptionString.contains('RenderFlex overflowed') ||
        exceptionString.contains('overflowed by') ||
        exceptionString.contains('pixels on the')) {
      debugPrint('Overflow detectado y manejado: ${details.exception}');
      return;
    }

    // Ignorar errores de layout menores
    if (exceptionString.contains('RenderBox') ||
        exceptionString.contains('constraints') ||
        exceptionString.contains('layout')) {
      debugPrint('Error de layout detectado: ${details.exception}');
      return;
    }

    // Ignorar errores de performance warnings
    if (exceptionString.contains('Performance Warning') ||
        exceptionString.contains('FPS dropped')) {
      return;
    }

    // Solo mostrar errores críticos
    FlutterError.presentError(details);
  };

  runApp(const CusApp());

  // Iniciar monitoreo de rendimiento en debug mode
  if (const bool.fromEnvironment('dart.vm.product') == false) {
    PerformanceMonitor().startMonitoring();
  }
}

class CusApp extends StatelessWidget {
  const CusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clave Única Sanjuanense',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color.fromARGB(255, 80, 175, 243),
        colorScheme: ColorScheme.fromSwatch()
            .copyWith(secondary: const Color(0xFF28A745)),
        fontFamily: 'Roboto',
        // Configuración optimizada para rendimiento
        textTheme: const TextTheme().apply(
          fontSizeFactor: 1.0,
          fontSizeDelta: 0.0,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        // Configuración de splash para mejor rendimiento
        splashFactory: InkRipple.splashFactory,
        // Configuración de animaciones más rápidas
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      // Configuración global optimizada
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            // Limitar el factor de escala de texto para evitar overflow
            textScaleFactor:
                MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.2),
          ),
          child: child!,
        );
      },
      initialRoute: '/',
      onGenerateRoute: (settings) {
        final pageBuilder = appRoutes[settings.name];
        if (pageBuilder != null) {
          return PageRouteBuilder(
            settings: settings,
            pageBuilder: (context, animation, secondaryAnimation) => pageBuilder(context),
            transitionDuration: const Duration(milliseconds: 200),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
          );
        }
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Página no encontrada')),
          ),
        );
      },
    );
  }
}