import 'package:casa/datos/simulado.dart';
import 'package:casa/dominio/tipos.dart';
import 'package:casa/main.dart';
import 'package:casa/ui/controlador.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Un teléfono acostado, como en los mockups: 844 × 390 puntos.
  void comoRelojDeMesa(WidgetTester tester) {
    tester.view.physicalSize = const Size(2532, 1170);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  // Las 6:00, antes de la primera pastilla, para que el reposo no muestre un recordatorio.
  DateTime temprano() => DateTime(2026, 10, 24, 6);

  testWidgets('del reposo a «¿Está bien?» y de vuelta deslizando', (
    tester,
  ) async {
    comoRelojDeMesa(tester);
    final c = Controlador(
      casa: casaSimulada,
      pastillas: pastillasSimuladas,
      reloj: temprano,
    );
    await tester.pumpWidget(AppCasa(controlador: c));

    expect(find.text('Cuidando la casa'), findsOneWidget);
    expect(find.text('Pastillas de hoy'), findsOneWidget);

    await tester.longPress(
      find.text('6:00'),
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
    comoRelojDeMesa(tester);
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
      reloj: temprano,
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
    comoRelojDeMesa(tester);
    final c = Controlador(casa: casaSimulada, reloj: temprano);
    await tester.pumpWidget(AppCasa(controlador: c));

    await tester.tap(find.text('Pedir ayuda'));
    await tester.pump();
    expect(find.text('Pida ayuda a alguien cerca'), findsOneWidget);
    expect(find.textContaining('llamando'), findsNothing);
    await _cerrar(tester, c);
  });

  testWidgets('a la hora de la pastilla la recuerda y «Ya la tomé» la marca', (
    tester,
  ) async {
    comoRelojDeMesa(tester);
    final c = Controlador(
      casa: casaSimulada,
      pastillas: pastillasSimuladas,
      reloj: () => DateTime(2026, 10, 24, 8, 2),
    );
    await tester.pumpWidget(AppCasa(controlador: c));

    expect(find.text('Es hora de la losartán'), findsOneWidget);
    await tester.tap(find.text('Ya la tomé'));
    await tester.pump();

    expect(find.text('Cuidando la casa'), findsOneWidget);
    expect(find.text('Le toca ahora'), findsNothing);
    expect(c.plan.tomada(pastillasSimuladas.first), isTrue);
    await _cerrar(tester, c);
  });

  testWidgets('una alarma gana sobre el recordatorio de la pastilla', (
    tester,
  ) async {
    comoRelojDeMesa(tester);
    final c = Controlador(
      casa: casaSimulada,
      pastillas: pastillasSimuladas,
      reloj: () => DateTime(2026, 10, 24, 8, 2),
    );
    await tester.pumpWidget(AppCasa(controlador: c));

    c.oirEvento(TipoEvento.alarma);
    await tester.pump();
    expect(find.text('¿Está bien, Carmen?'), findsOneWidget);
    await _cerrar(tester, c);
  });
}

/// Desmonta la app antes de apagar el reloj del controlador, para que la prueba no termine
/// con un temporizador vivo.
Future<void> _cerrar(WidgetTester tester, Controlador c) async {
  await tester.pumpWidget(const SizedBox());
  c.dispose();
}
