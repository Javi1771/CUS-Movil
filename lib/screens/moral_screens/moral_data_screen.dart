import 'package:flutter/material.dart';

class MoralDataScreen extends StatelessWidget {
  const MoralDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Datos - Persona Moral')),
      body: const Center(child: Text('Formulario para persona moral')),
    );
  }
}
