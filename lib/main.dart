import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'routes/routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cargar variables desde .env
  await dotenv.load(fileName: ".env");

  // Configuración regional de fechas en español
  await initializeDateFormatting('es', null);

  runApp(const CusApp());
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
      ),
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
