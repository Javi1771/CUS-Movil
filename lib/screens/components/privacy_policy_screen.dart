// lib/screens/privacy_policy_screen.dart
// ignore_for_file: library_private_types_in_public_api

import 'package:cus_movil/widgets/alert_helper.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  _PrivacyPolicyScreenState createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  static const _pdfUrl =
      'https://cus.sanjuandelrio.gob.mx/tramites-sjr/public/pdf/Aviso%20de%20Privacidad%20Integral.pdf';

  late PdfViewerController _pdfController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfViewerController();
  }

  @override
  Widget build(BuildContext context) {
    const govBlue = Color(0xFF0B3B60);
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F5),
      appBar: AppBar(
        backgroundColor: govBlue,
        elevation: 4,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.privacy_tip, size: 24, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Aviso de Privacidad',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          //* Encabezado descriptivo
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Text(
              'Consulta aquí el Aviso de Privacidad Integral de la Clave Única Sanjuanense.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: govBlue,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          //* Contenedor del PDF
          Expanded(
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 6,
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  SfPdfViewer.network(
                    _pdfUrl,
                    controller: _pdfController,
                    onDocumentLoaded: (_) => setState(() => _isLoading = false),
                    onDocumentLoadFailed: (details) {
                      setState(() => _isLoading = false);
                      AlertHelper.showAlert(
                        'Error al cargar PDF: ${details.error}',
                        type: AlertType.error,
                      );
                    },
                  ),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator()),
                ],
              ),
            ),
          ),

          //* Pie con botón de cierre
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: TextButton.icon(
              icon: const Icon(Icons.close, size: 20, color: govBlue),
              label: const Text('Cerrar', style: TextStyle(color: govBlue)),
              style: TextButton.styleFrom(
                textStyle:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
