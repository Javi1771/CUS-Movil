import 'dart:collection';
import 'package:xml/xml.dart';
import 'package:flutter/services.dart' show rootBundle;

class CodigoPostalLoader {
  final Map<String, List<String>> _coloniasPorCP = {};

  Future<void> cargarDesdeXML() async {
    final xmlStr = await rootBundle.loadString('assets/codigos_postales_queretaro.xml');
    final document = XmlDocument.parse(xmlStr);

    for (final registro in document.findAllElements('table')) {
      final cp = registro.getElement('d_codigo')?.innerText ?? '';
      final colonia = registro.getElement('d_asenta')?.innerText ?? '';

      if (cp.isNotEmpty && colonia.isNotEmpty) {
        _coloniasPorCP.putIfAbsent(cp, () => <String>[]).add(colonia);
      }
    }
  }

  List<String> buscarColoniasPorCP(String cp) {
    final list = _coloniasPorCP[cp] ?? [];
    return LinkedHashSet<String>.from(list).toList();
  }

  List<String> buscarCallesPorCP(String cp) => [];
}
