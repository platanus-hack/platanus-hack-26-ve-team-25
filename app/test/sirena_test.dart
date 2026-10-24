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

  /// Simula que la sirena se calla para escuchar (true) o vuelve (false).
  void ventana(bool abierta) => _ventanas.add(abierta);

  @override
  Stream<bool> get ventanas => _ventanas.stream;

  @override
  Future<void> sonar(String frase) async => pasos.add('sonar: $frase');

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

  test('«¿Está bien?» suena mientras espera y se calla con «Estoy bien»', () {
    c.oirEvento(TipoEvento.alarma);
    expect(sirena.pasos, [
      'sonar: Carmen, ¿está bien? Diga «Lucero, estoy bien», o deslice el botón.',
    ]);
    c.estoyBien();
    expect(sirena.pasos.last, 'callar');
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
  });

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

  test('sin alarma no hay ventana', () {
    sirena.ventana(true);
    expect(c.ventanaParaHablar, isFalse);
  });
}
