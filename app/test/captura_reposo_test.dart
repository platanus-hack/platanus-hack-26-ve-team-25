// Captura de la pantalla de reposo como PNG, para mirarla sin teléfono. No corre con `make test`
// (ver dart_test.yaml): `flutter test --run-skipped --update-goldens -t captura` la escribe en
// test/capturas/.
@Tags(['captura'])
library;

import 'dart:io';

import 'package:casa/datos/simulado.dart';
import 'package:casa/main.dart';
import 'package:casa/ui/controlador.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _fuente(String familia, List<String> archivos) async {
  final f = FontLoader(familia);
  for (final a in archivos) {
    f.addFont(
      Future.value(ByteData.sublistView(File(a).readAsBytesSync())),
    );
  }
  await f.load();
}

void main() {
  testWidgets('reposo como reloj de mesa', (tester) async {
    await _fuente('AtkinsonHyperlegible', [
      'assets/fuentes/AtkinsonHyperlegible-Regular.ttf',
      'assets/fuentes/AtkinsonHyperlegible-Bold.ttf',
    ]);
    final iconos = Platform.environment['FLUTTER_ROOT'] ?? '';
    final material = File(
      '$iconos/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    );
    if (material.existsSync()) await _fuente('MaterialIcons', [material.path]);

    // El Infinix acostado: 2436 × 1080 px a densidad 2,75.
    tester.view.physicalSize = const Size(2436, 1080);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    final c = Controlador(
      casa: casaSimulada,
      pastillas: pastillasSimuladas,
      reloj: () => DateTime(2026, 10, 24, 10, 50),
    );
    await tester.pumpWidget(AppCasa(controlador: c));
    await expectLater(
      find.byType(AppCasa),
      matchesGoldenFile('capturas/reposo.png'),
    );
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
}
