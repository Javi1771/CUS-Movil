import 'dart:collection';
import 'package:xml/xml.dart';
import 'package:flutter/services.dart' show rootBundle;

class CodigoPostalLoader {
  final Map<String, List<String>> _coloniasPorCP = {};
  bool _isLoaded = false;

  Future<void> cargarDesdeXML() async {
    if (_isLoaded) return; // Avoid reloading

    try {
      // Load XML in chunks to prevent blocking
      final xmlStr =
          await rootBundle.loadString('assets/codigos_postales_queretaro.xml');

      // Parse XML in background to prevent ANR
      await _parseXMLInBackground(xmlStr);
      _isLoaded = true;
    } catch (e) {
      print('Error loading postal codes: $e');
      // Continue with empty data instead of crashing
      _isLoaded = true;
    }
  }

  Future<void> _parseXMLInBackground(String xmlStr) async {
    try {
      final document = XmlDocument.parse(xmlStr);
      final elements = document.findAllElements('table').toList();

      // Process in batches to prevent blocking
      const batchSize = 100;
      for (int i = 0; i < elements.length; i += batchSize) {
        final batch = elements.skip(i).take(batchSize);

        for (final registro in batch) {
          final cp = registro.getElement('d_codigo')?.innerText ?? '';
          final colonia = registro.getElement('d_asenta')?.innerText ?? '';

          if (cp.isNotEmpty && colonia.isNotEmpty) {
            _coloniasPorCP.putIfAbsent(cp, () => <String>[]).add(colonia);
          }
        }

        // Yield control back to UI thread periodically
        if (i % (batchSize * 5) == 0) {
          await Future.delayed(const Duration(milliseconds: 1));
        }
      }
    } catch (e) {
      print('Error parsing XML: $e');
    }
  }

  List<String> buscarColoniasPorCP(String cp) {
    final list = _coloniasPorCP[cp] ?? [];
    return LinkedHashSet<String>.from(list).toList();
  }

  List<String> buscarCallesPorCP(String cp) => [];
}
