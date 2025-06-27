import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:cus_movil/screens/mis_documentos_screen.dart';
import 'package:cus_movil/screens/perfil_usuario_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _page = 0;
  final GlobalKey _bottomNavigationKey = GlobalKey();

  final List<Widget> pages = const [
    Center(
        child: Text('👋 Bienvenido a CUS Móvil',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
    MisDocumentosScreen(),
    Center(child: Text('Eventos', style: TextStyle(fontSize: 24))),
    PerfilUsuarioScreen(), // Esta es la pantalla completa que creaste
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: pages[_page],
      bottomNavigationBar: CurvedNavigationBar(
        key: _bottomNavigationKey,
        index: _page,
        height: 65.0,
        items: const [
          Icon(Icons.home_rounded, size: 30, color: Colors.white),
          Icon(Icons.folder_open_rounded, size: 30, color: Colors.white),
          Icon(Icons.event_rounded, size: 30, color: Colors.white),
          Icon(Icons.person_rounded, size: 30, color: Colors.white),
        ],
        color: Color(0xFF0B3B60),
        buttonBackgroundColor: Color(0xFF0B3B60),
        backgroundColor: Colors.transparent,
        animationCurve: Curves.easeInOutBack,
        animationDuration: Duration(milliseconds: 500),
        onTap: (index) {
          setState(() {
            _page = index;
          });
        },
        letIndexChange: (index) => true,
      ),
    );
  }
}
