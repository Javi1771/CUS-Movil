import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'routes/routes.dart';
import 'utils/performance_monitor.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Descomenta solo si sabes manejar el ciclo de renderizado tú mismo
  // WidgetsBinding.instance.deferFirstFrame();

  await dotenv.load(fileName: ".env");
  await initializeDateFormatting('es', null);

  FlutterError.onError = (FlutterErrorDetails details) {
    final exceptionString = details.exception.toString();

    if (exceptionString.contains('RenderFlex overflowed') ||
        exceptionString.contains('overflowed by') ||
        exceptionString.contains('pixels on the')) {
      debugPrint('Overflow detectado y manejado: ${details.exception}');
      return;
    }

    if (exceptionString.contains('RenderBox') ||
        exceptionString.contains('constraints') ||
        exceptionString.contains('layout')) {
      debugPrint('Error de layout detectado: ${details.exception}');
      return;
    }

    FlutterError.presentError(details);
  };

  runApp(const CusApp());

  // Solo si usas deferFirstFrame (comentado arriba), permite el primer frame aquí
  // WidgetsBinding.instance.allowFirstFrame();

  PerformanceMonitor().startMonitoring();
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
        // Configuración para prevenir overflow de texto
        textTheme: const TextTheme().apply(
          fontSizeFactor: 1.0,
          fontSizeDelta: 0.0,
        ),
        // Configuración de escalado de texto
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // Configuración global para prevenir overflow
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaleFactor:
                MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.2),
          ),
          child: child!,
        );
      },
      initialRoute: '/home',
      onGenerateRoute: (settings) {
        final pageBuilder = appRoutes[settings.name];
        if (pageBuilder != null) {
          return MaterialPageRoute(builder: pageBuilder);
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
