import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cus_movil/main.dart';

void main() {
  testWidgets('Smoke test: carga la app y muestra el splash', (WidgetTester tester) async {
    //? Construye la app
    await tester.pumpWidget(const CusApp());

    //* Aquí comprobamos, por ejemplo, que aparece el logo en splash:
    expect(find.byType(Image), findsOneWidget);

    //* (O cualquier otro elemento que deba estar en el splash)
  });
}
