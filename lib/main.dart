import 'package:flutter/material.dart';
import 'routes.dart';

void main() {
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
      initialRoute: '/',
      routes: appRoutes,
    );
  }
}
