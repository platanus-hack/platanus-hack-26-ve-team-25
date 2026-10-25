import 'dart:async';

import 'package:casa/datos/simulado.dart';
import 'package:casa/datos/sirena.dart';
import 'package:casa/dominio/alerta.dart';
import 'package:casa/dominio/tipos.dart';
import 'package:casa/oido/oido.dart';
import 'package:casa/oido/sonidos.dart';
import 'package:casa/ui/controlador.dart';
import 'package:flutter_test/flutter_test.dart';

import 'voz_falsa.dart';

class SirenaFalsa implements Sirena {
  final pasos = <String>[];
  final _ventanas = StreamController<bool>.broadcast(sync: true);
  final _hablando = StreamController<bool>.broadcast(sync: true);

  /// Simula que la sirena se calla para escuchar (true) o vuelve (false).
  void ventana(bool abierta) => _ventanas.add(abierta);

  /// Simula que la voz del teléfono empieza (true) o termina (false) la frase.
  void hablar(bool hablando) => _hablando.add(hablando);

  @override
  Stream<bool> get ventanas => _ventanas.stream;

  @override
  Stream<bool> get hablando => _hablando.stream;

  @override
  Future<void> sonar(String frase, {String? primera}) async =>
      pasos.add('sonar: $primera → $frase');

  @override
  Future<void> tono() async => pasos.add('tono');

  @override
  Future<void> decir(String frase) async => pasos.add('decir: $frase');

  @override
  Future<void> callar() async => pasos.add('callar');
}

void main() {
  late DateTime ahora;
  late SirenaFalsa sirena;
  late StreamController<Escucha> oido;
  late Controlador c;

  // La alarma de humo, como la vería YAMNet.
  const alarma = Escucha(
    db: -10,
    fondo: -40,
    compuerta: true,
    top: [Clase('Smoke detector, smoke alarm', 0.9)],
    sonido: Sonido(
      TipoSonido.alarma,
      Clase('Smoke detector, smoke alarm', 0.9),
    ),
  );

  // Alguien habla, como lo vería YAMNet.
  const voz = Escucha(
    db: -30,
    fondo: -50,
    compuerta: true,
    top: [Clase('Speech', 0.8)],
  );

  setUp(() {
    ahora = DateTime(2026, 10, 24, 6);
    sirena = SirenaFalsa();
    oido = StreamController<Escucha>.broadcast(sync: true);
    c = Controlador(
      casa: casaSimulada,
      reloj: () => ahora,
      escuchas: oido.stream,
      sirena: sirena,
    );
  });
  tearDown(() => c.dispose());

  test('Lucero pregunta de una vez, corto, y se calla con «Estoy bien»', () {
    c.oirEvento(TipoEvento.alarma);
    expect(sirena.pasos, [
      'sonar: Carmen, ¿está bien? → '
          'Carmen, ¿está bien? Diga «Lucero, estoy bien», o deslice el botón.',
    ]);
    c.estoyBien();
    expect(sirena.pasos.last, 'callar');
  });

  testWidgets('el tono entra recién en los últimos 3 s, una sola vez', (
    tester,
  ) async {
    final c = Controlador(
      casa: casaSimulada,
      reloj: () => ahora,
      sirena: sirena,
    );
    c.oirEvento(TipoEvento.golpe);
    ahora = ahora.add(
      esperaConfirmacion - sirenaAlFinal - const Duration(seconds: 1),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(sirena.pasos, isNot(contains('tono')));
    ahora = ahora.add(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    ahora = ahora.add(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(sirena.pasos.where((p) => p == 'tono'), hasLength(1));
    c.dispose();
  });

  test('se calla al escalar: ya no pregunta, avisa', () {
    c.oirEvento(TipoEvento.golpe);
    c.necesitoAyuda();
    expect(sirena.pasos.last, 'callar');
  });

  test('el pánico no suena: nace escalado', () {
    c.pedirAyuda(TipoEvento.panico);
    expect(sirena.pasos, isEmpty);
  });

  test('su propio tono no vuelve a abrir «¿Está bien?» al callarse', () {
    c.oirEvento(TipoEvento.alarma);
    c.estoyBien();
    oido.add(alarma); // el anillo todavía tiene el tono
    expect(c.alerta, isNull);

    ahora = ahora.add(Controlador.sordoTrasLaAlarma);
    oido.add(alarma); // pasado ese tiempo, una alarma de verdad sí pregunta
    expect(c.alerta?.motivo, TipoEvento.alarma);
  });

  testWidgets('a 20 s del final dice a quién va a llamar, una sola vez', (
    tester,
  ) async {
    // El reloj del controlador tiene que nacer dentro del tiempo falso de la prueba.
    final c = Controlador(
      casa: casaSimulada,
      reloj: () => ahora,
      sirena: sirena,
    );
    c.oirEvento(TipoEvento.alarma);
    ahora = ahora.add(esperaConfirmacion - Controlador.avisoFinal);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(sirena.pasos.where((p) => p.startsWith('decir')), [
      'decir: Carmen, si no responde, voy a avisar a su familia.',
    ]);
    c.dispose();
  }, skip: !Controlador.diceElFinal);

  // Con DEMO=true: flutter test --dart-define=DEMO=true test/sirena_test.dart
  testWidgets(
    'en la tarima (10 s) no cambia la frase: siempre pregunta «¿Está bien?»',
    (tester) async {
      final c = Controlador(
        casa: casaSimulada,
        reloj: () => ahora,
        sirena: sirena,
      );
      c.oirEvento(TipoEvento.alarma);
      for (var i = 0; i < esperaConfirmacion.inSeconds - 1; i++) {
        ahora = ahora.add(const Duration(seconds: 1));
        await tester.pump(const Duration(seconds: 1));
      }
      expect(sirena.pasos.where((p) => p.startsWith('decir')), isEmpty);
      // La pregunta corta (unos 2 s de voz lenta) y su ventana callada de 4 s caben antes de
      // que entre el tono.
      expect(
        const Duration(seconds: 2 + 4),
        lessThanOrEqualTo(esperaConfirmacion - sirenaAlFinal),
      );
      c.dispose();
    },
    skip: Controlador.diceElFinal,
  );

  testWidgets(
    'en la ventana callada dice «Le escucho…» y entiende lo que se dijo',
    (tester) async {
      final frases = FrasesFalsas(['lucero estoy bien']);
      final c = Controlador(
        casa: casaSimulada,
        reloj: () => ahora,
        sirena: sirena,
        frases: frases,
        microfono: MicrofonoFalso(),
      );
      c.oirEvento(TipoEvento.golpe);
      sirena.ventana(true);
      expect(c.ventanaParaHablar, isTrue);

      ahora = ahora.add(const Duration(seconds: 4));
      sirena.ventana(false);
      await tester.pump();
      // Reconoció justo los 4 s de la ventana, y «Lucero, estoy bien» calló la alarma.
      expect(frases.audios, [32000 * 4]);
      expect(c.alerta, isNull);
      expect(sirena.pasos.last, 'callar');
      c.dispose();
    },
  );

  testWidgets(
    'no se oye a sí mismo: la frase «Lucero, estoy bien» del teléfono no calla la alarma',
    (tester) async {
      final frases = FrasesFalsas(['lucero estoy bien el botón']);
      final c = Controlador(
        casa: casaSimulada,
        reloj: () => ahora,
        escuchas: oido.stream,
        sirena: sirena,
        frases: frases,
        microfono: MicrofonoFalso(),
      );
      c.oirEvento(TipoEvento.golpe);

      // El teléfono dice la frase, YAMNet la oye como voz y despierta a Vosk: no le pasa audio.
      sirena.hablar(true);
      oido.add(voz);
      await tester.pump(Controlador.finDeFrase);
      await tester.pump();
      expect(frases.audios, isEmpty);
      expect(c.alerta?.estado, EstadoAlerta.pendiente);

      // Termina la frase y se abre la ventana. Al cerrarse, Vosk oye solo lo de después de la voz.
      sirena.hablar(false);
      sirena.ventana(true);
      ahora = ahora.add(const Duration(seconds: 4));
      sirena.ventana(false);
      await tester.pump();
      expect(frases.audios, [
        32000 * 3,
      ]); // 4 s menos la cola de la voz, en segundos enteros
      c.dispose();
    },
  );

  test('sin alarma no hay ventana', () {
    sirena.ventana(true);
    expect(c.ventanaParaHablar, isFalse);
  });
}
