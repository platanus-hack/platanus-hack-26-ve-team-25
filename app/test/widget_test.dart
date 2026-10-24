import 'package:casa/datos/simulado.dart';
import 'package:casa/dominio/tipos.dart';
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

  testWidgets('del reposo a «¿Está bien?» y de vuelta deslizando', (
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

    // Un toque no apaga la alarma: hay que deslizar.
    await tester.tap(find.byIcon(Icons.arrow_forward_rounded));
    await tester.pump();
    expect(find.text('¿Está bien, Carmen?'), findsOneWidget);

    await tester.drag(
      find.byIcon(Icons.arrow_forward_rounded),
      const Offset(400, 0),
    );
    await tester.pump();
    expect(find.text('Cuidando la casa'), findsOneWidget);
    await _cerrar(tester, c);
  });

  testWidgets('el pánico llama al primer contacto una sola vez', (
    tester,
  ) async {
    comoTelefono(tester);
    final llamadas = <String>[];
    final c = Controlador(
      casa: const Casa(
        id: 'prueba',
        nombre: 'Carmen',
        condiciones: [],
        contactos: [
          Contacto(
            nombre: 'Josuep',
            relacion: 'hijo',
            canal: Canal.llamada,
            orden: 1,
            telefono: '04120000000',
          ),
        ],
      ),
      llamar: (numero) async => llamadas.add(numero),
    );
    await tester.pumpWidget(AppCasa(controlador: c));

    await tester.tap(find.text('Pedir ayuda'));
    await tester.pump();
    expect(find.text('Estamos llamando a Josuep'), findsOneWidget);
    expect(llamadas, ['04120000000']);

    await tester.pump(
      const Duration(seconds: 3),
    ); // los tics del reloj no vuelven a llamar
    expect(llamadas, hasLength(1));

    await tester.tap(find.text('Fue sin querer, estoy bien'));
    await tester.pump();
    expect(find.text('Cuidando la casa'), findsOneWidget);
    await _cerrar(tester, c);
  });

  testWidgets('sin número configurado no promete una llamada', (tester) async {
    comoTelefono(tester);
    final c = Controlador(casa: casaSimulada);
    await tester.pumpWidget(AppCasa(controlador: c));

    await tester.tap(find.text('Pedir ayuda'));
    await tester.pump();
    expect(find.text('Pida ayuda a alguien cerca'), findsOneWidget);
    expect(find.textContaining('llamando'), findsNothing);
    await _cerrar(tester, c);
  });
}

/// Desmonta la app antes de apagar el reloj del controlador, para que la prueba no termine
/// con un temporizador vivo.
Future<void> _cerrar(WidgetTester tester, Controlador c) async {
  await tester.pumpWidget(const SizedBox());
  c.dispose();
}
