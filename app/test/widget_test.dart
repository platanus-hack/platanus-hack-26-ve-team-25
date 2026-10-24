import 'dart:async';

import 'package:casa/datos/simulado.dart';
import 'package:casa/dominio/tipos.dart';
import 'package:casa/main.dart';
import 'package:casa/oido/oido.dart';
import 'package:casa/oido/sonidos.dart';
import 'package:casa/ui/controlador.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'telefono_falso.dart';
import 'voz_falsa.dart';

void main() {
  // Un teléfono acostado, como en los mockups: 844 × 390 puntos.
  void comoRelojDeMesa(WidgetTester tester) {
    tester.view.physicalSize = const Size(2532, 1170);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  // Las 6:00, antes de la primera pastilla, para que el reposo no muestre un recordatorio.
  DateTime temprano() => DateTime(2026, 10, 24, 6);

  const casaConNumero = Casa(
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
  );

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

  group('la llamada de emergencia', () {
    late DateTime ahora;
    late TelefonoFalso t;
    late Controlador c;

    Future<void> pedirAyuda(WidgetTester tester) async {
      comoRelojDeMesa(tester);
      ahora = temprano();
      t = TelefonoFalso();
      c = Controlador(casa: casaConNumero, reloj: () => ahora, telefono: t);
      await tester.pumpWidget(AppCasa(controlador: c));
      await tester.tap(find.text('Pedir ayuda'));
      await tester.pump();
    }

    testWidgets('el pánico llama primero por WhatsApp, una sola vez', (
      tester,
    ) async {
      await pedirAyuda(tester);
      expect(find.text('Estamos llamando a Josuep'), findsOneWidget);
      expect(t.porWhatsApp, ['04120000000']);
      expect(t.porTelefono, isEmpty);
      expect(find.textContaining('WhatsApp'), findsNothing);

      await tester.pump(
        const Duration(seconds: 3),
      ); // los tics del reloj no vuelven a llamar
      expect(t.porWhatsApp, hasLength(1));
      await _cerrar(tester, c);
    });

    testWidgets(
      'si el WhatsApp terminó enseguida, llama por teléfono sin preguntar',
      (tester) async {
        await pedirAyuda(tester);
        t.terminarWhatsApp(4);
        await tester.pump();
        expect(t.porTelefono, ['04120000000']);
        expect(find.text('¿Pudo hablar con Josuep?'), findsNothing);
        await _cerrar(tester, c);
      },
    );

    testWidgets('si duró más, pregunta; «Sí, ya hablamos» cierra la alerta', (
      tester,
    ) async {
      await pedirAyuda(tester);
      t.terminarWhatsApp(40);
      await tester.pump();
      expect(find.text('¿Pudo hablar con Josuep?'), findsOneWidget);

      await tester.tap(find.text('Sí, ya hablamos'));
      await tester.pump();
      expect(find.text('Cuidando la casa'), findsOneWidget);
      expect(t.porTelefono, isEmpty);
      await _cerrar(tester, c);
    });

    testWidgets(
      'si nadie responde la pregunta, llama por teléfono a los 15 s',
      (tester) async {
        await pedirAyuda(tester);
        t.terminarWhatsApp(40);
        await tester.pump();

        ahora = ahora.add(const Duration(seconds: 14));
        await tester.pump(const Duration(seconds: 1));
        expect(t.porTelefono, isEmpty);

        ahora = ahora.add(const Duration(seconds: 2));
        await tester.pump(const Duration(seconds: 1));
        expect(t.porTelefono, ['04120000000']);
        expect(find.text('¿Pudo hablar con Josuep?'), findsNothing);
        await _cerrar(tester, c);
      },
    );

    testWidgets(
      '«Fue sin querer» cierra todo y el fin del WhatsApp ya no llama',
      (tester) async {
        await pedirAyuda(tester);
        await tester.tap(find.text('Fue sin querer, estoy bien'));
        await tester.pump();
        t.terminarWhatsApp(4);
        await tester.pump();
        expect(find.text('Cuidando la casa'), findsOneWidget);
        expect(t.porTelefono, isEmpty);
        await _cerrar(tester, c);
      },
    );
  });

  group('respuesta por voz a «¿Pudo hablar con Josuep?»', () {
    late DateTime ahora;
    late TelefonoFalso t;
    late VozFalsa voz;
    late MicrofonoFalso mic;
    late Controlador c;

    Future<void> preguntar(WidgetTester tester) async {
      comoRelojDeMesa(tester);
      ahora = temprano();
      t = TelefonoFalso();
      voz = VozFalsa();
      mic = MicrofonoFalso();
      c = Controlador(
        casa: casaConNumero,
        reloj: () => ahora,
        telefono: t,
        voz: voz,
        microfono: mic,
      );
      await tester.pumpWidget(AppCasa(controlador: c));
      await tester.tap(find.text('Pedir ayuda'));
      await tester.pump();
      t.terminarWhatsApp(40);
      await tester.pump();
    }

    testWidgets('pausa el oído y muestra que escucha', (tester) async {
      await preguntar(tester);
      expect(voz.escucho, isTrue);
      expect(mic.pasos, ['pausar']);
      expect(find.text('La escuchamos: diga «sí» o «no»'), findsOneWidget);
      voz.responder([]);
      await tester.pump();
      expect(mic.pasos, ['pausar', 'reanudar']);
      await _cerrar(tester, c);
    });

    testWidgets('«sí» cierra la alerta sin llamar por teléfono', (
      tester,
    ) async {
      await preguntar(tester);
      voz.responder(['sí, ya hablamos']);
      await tester.pump();
      expect(find.text('Cuidando la casa'), findsOneWidget);
      expect(t.porTelefono, isEmpty);
      await _cerrar(tester, c);
    });

    testWidgets('«no» llama por teléfono sin esperar', (tester) async {
      await preguntar(tester);
      voz.responder(['no']);
      await tester.pump();
      expect(t.porTelefono, ['04120000000']);
      await _cerrar(tester, c);
    });

    testWidgets('si no entiende, sigue la cuenta y llama a los 15 s', (
      tester,
    ) async {
      await preguntar(tester);
      voz.responder(['eh']);
      await tester.pump();
      expect(find.text('¿Pudo hablar con Josuep?'), findsOneWidget);
      expect(t.porTelefono, isEmpty);

      ahora = ahora.add(const Duration(seconds: 16));
      await tester.pump(const Duration(seconds: 1));
      expect(t.porTelefono, ['04120000000']);
      await _cerrar(tester, c);
    });
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

  testWidgets(
    'a la hora de la pastilla la recuerda y «Ya me la tomé» la marca',
    (tester) async {
      comoRelojDeMesa(tester);
      final c = Controlador(
        casa: casaSimulada,
        pastillas: pastillasSimuladas,
        reloj: () => DateTime(2026, 10, 24, 8, 2),
      );
      await tester.pumpWidget(AppCasa(controlador: c));

      expect(find.text('Es hora de la losartán'), findsOneWidget);
      expect(find.text('Recuérdame en 10 min'), findsNothing);
      await tester.tap(find.text('Ya me la tomé'));
      await tester.pump();

      expect(find.text('Cuidando la casa'), findsOneWidget);
      expect(find.text('Le toca ahora'), findsNothing);
      expect(c.plan.tomada(pastillasSimuladas.first), isTrue);
      await _cerrar(tester, c);
    },
  );

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

  group('pedir por voz, sin botones', () {
    late MicrofonoFalso mic;
    late StreamController<Escucha> oido;
    late Controlador c;

    Escucha oye(Map<String, double> clases) => Escucha(
      db: -40,
      fondo: -50,
      compuerta: false,
      top: [for (final e in clases.entries) Clase(e.key, e.value)],
    );

    Future<FrasesFalsas> abrir(WidgetTester tester, List<String> dice) async {
      comoRelojDeMesa(tester);
      final frases = FrasesFalsas(dice);
      mic = MicrofonoFalso();
      oido = StreamController<Escucha>();
      c = Controlador(
        casa: casaSimulada,
        reloj: temprano,
        escuchas: oido.stream,
        frases: frases,
        microfono: mic,
      );
      await tester.pumpWidget(AppCasa(controlador: c));
      return frases;
    }

    testWidgets('«me huele a gas» pregunta «¿Está bien?» con el motivo', (
      tester,
    ) async {
      final frases = await abrir(tester, ['me huele a gas']);
      expect(find.text('Huele a gas'), findsNothing);

      oido.add(oye({'Speech': 0.8}));
      await tester.pump();
      // Espera a que termine la frase y lee los últimos 5 s del anillo, sin pausar el oído.
      await tester.pump(Controlador.finDeFrase);
      await tester.pump();
      expect(frases.audios, [32000 * Controlador.audioDelPedido.inSeconds]);
      expect(mic.pasos, isEmpty);
      expect(find.text('¿Está bien, Carmen?'), findsOneWidget);
      expect(find.text(TipoEvento.hueleGas.frase), findsOneWidget);
      await _cerrar(tester, c);
    });

    testWidgets('la voz de la TV no despierta al reconocedor', (tester) async {
      final frases = await abrir(tester, ['ayuda']);
      oido.add(oye({'Speech': 0.7, 'Television': 0.4}));
      await tester.pump(Controlador.finDeFrase);
      expect(frases.audios, isEmpty);
      await _cerrar(tester, c);
    });

    testWidgets('una conversación cualquiera sigue en reposo', (tester) async {
      await abrir(tester, []);
      oido.add(oye({'Speech': 0.9}));
      await tester.pump();
      await tester.pump(Controlador.finDeFrase);
      await tester.pump();
      expect(find.text('Cuidando la casa'), findsOneWidget);
      await _cerrar(tester, c);
    });
  });

  testWidgets('«Leer récipe» dice que todavía no está lista y vuelve', (
    tester,
  ) async {
    comoRelojDeMesa(tester);
    final c = Controlador(casa: casaSimulada, reloj: temprano);
    await tester.pumpWidget(AppCasa(controlador: c));
    await tester.tap(find.text('Leer récipe'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Todavía no está lista'), findsOneWidget);
    await tester.tap(find.text('Volver'));
    await tester.pumpAndSettle();
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
