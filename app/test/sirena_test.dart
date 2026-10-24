import 'dart:async';

import 'package:casa/datos/simulado.dart';
import 'package:casa/datos/sirena.dart';
import 'package:casa/dominio/tipos.dart';
import 'package:casa/oido/oido.dart';
import 'package:casa/oido/sonidos.dart';
import 'package:casa/ui/controlador.dart';
import 'package:flutter_test/flutter_test.dart';

class SirenaFalsa implements Sirena {
  final pasos = <String>[];

  @override
  Future<void> sonar() async => pasos.add('sonar');

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
    expect(sirena.pasos, ['sonar']);
    c.estoyBien();
    expect(sirena.pasos, ['sonar', 'callar']);
  });

  test('se calla al escalar: ya no pregunta, avisa', () {
    c.oirEvento(TipoEvento.golpe);
    c.necesitoAyuda();
    expect(sirena.pasos, ['sonar', 'callar']);
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
}
