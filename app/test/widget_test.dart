import 'package:casa/datos/simulado.dart';
import 'package:casa/main.dart';
import 'package:casa/ui/controlador.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // El tamaño de un teléfono, como en los mockups: 390 × 844 puntos.
  void comoTelefono(WidgetTester tester) {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  testWidgets('del reposo a «¿Está bien?» y de vuelta con «Estoy bien»', (
    tester,
  ) async {
    comoTelefono(tester);
    final c = Controlador(casa: casaSimulada);
    await tester.pumpWidget(AppCasa(controlador: c));

    expect(find.text('Cuidando la casa'), findsOneWidget);

    await tester.longPress(
      find.textContaining(':').first,
    ); // el reloj simula una alarma de humo
    await tester.pump();
    expect(find.text('¿Está bien, Carmen?'), findsOneWidget);

    await tester.tap(find.text('Estoy bien'));
    await tester.pump();
    expect(find.text('Cuidando la casa'), findsOneWidget);
    await _cerrar(tester, c);
  });

  testWidgets('el pánico va directo a avisar a la familia', (tester) async {
    comoTelefono(tester);
    final c = Controlador(casa: casaSimulada);
    await tester.pumpWidget(AppCasa(controlador: c));

    await tester.tap(find.text('Pedir ayuda'));
    await tester.pump();
    expect(find.text('Ya avisamos a su familia'), findsOneWidget);

    await tester.tap(find.text('Fue sin querer, estoy bien'));
    await tester.pump();
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.text('Cuidando la casa'), findsOneWidget);
    await _cerrar(tester, c);
  });
}

/// Desmonta la app antes de apagar el reloj del controlador, para que la prueba no termine
/// con un temporizador vivo.
Future<void> _cerrar(WidgetTester tester, Controlador c) async {
  await tester.pumpWidget(const SizedBox());
  c.dispose();
}
