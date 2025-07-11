import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class VistaPreviaPDFScreen extends StatelessWidget {
  final String rutaPdf;
  final String titulo;

  const VistaPreviaPDFScreen({
    super.key,
    required this.rutaPdf,
    required this.titulo,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(titulo),
        backgroundColor: const Color(0xFF0B3B60),
      ),
      body: PDFView(
        filePath: rutaPdf,
        enableSwipe: true,
        swipeHorizontal: false,
        autoSpacing: true,
        pageFling: true,
        onError: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al cargar PDF: $error')),
          );
        },
        onRender: (pages) {
          debugPrint('PDF Renderizado');
        },
        onPageError: (page, error) {
          debugPrint('Error en página $page: $error');
        },
      ),
    );
  }
}
