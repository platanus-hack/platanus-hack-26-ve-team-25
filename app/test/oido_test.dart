import 'dart:typed_data';

import 'package:casa/dominio/tipos.dart';
import 'package:casa/oido/anillo.dart';
import 'package:casa/oido/nivel.dart';
import 'package:casa/oido/sonidos.dart';
import 'package:flutter_test/flutter_test.dart';

// Las mismas pruebas que web/src/lib/escucha/escucha.test.ts, para que la app y /escucha
// se porten igual.
void main() {
  group('rmsDb', () {
    test('una señal a plena escala da 0 dB', () {
      expect(
        rmsDb(Float32List.fromList(List.filled(100, 1))),
        closeTo(0, 1e-6),
      );
    });
    test('a la décima parte da -20 dB', () {
      expect(
        rmsDb(Float32List.fromList(List.filled(100, 0.1))),
        closeTo(-20, 1e-4),
      );
    });
    test('el silencio no da -infinito', () {
      expect(rmsDb(Float32List(100)), -100);
    });
  });

  group('LineaBase', () {
    test('un golpe aislado casi no mueve el fondo', () {
      final b = LineaBase()..actualizar(-60);
      expect(b.actualizar(-10), lessThan(-59));
    });
    test('un ruido que se queda (la TV) termina subiendo el fondo', () {
      final b = LineaBase()..actualizar(-60);
      for (var i = 0; i < 500; i++) {
        b.actualizar(-50);
      }
      expect(b.actual, greaterThan(-51));
    });
  });

  test('la compuerta se abre con un salto sobre el fondo y se cierra después del sostén', () {
    final c = Compuerta(umbralDb: 15, sostenMs: 1500);
    expect(c.evaluar(-55, -60, 0), isFalse);
    expect(c.evaluar(-40, -60, 100), isTrue);
    expect(c.evaluar(-60, -60, 1500), isTrue);
    expect(c.evaluar(-60, -60, 1700), isFalse);
  });

  group('Anillo', () {
    test(
      'devuelve las últimas muestras en orden aunque haya dado la vuelta',
      () {
        final a = Anillo(4)..escribir(Float32List.fromList([1, 2, 3, 4, 5, 6]));
        expect(a.ultimas(3), [4, 5, 6]);
      },
    );
    test('antes de llenarse devuelve solo lo que hay', () {
      final a = Anillo(10)..escribir(Float32List.fromList([1, 2]));
      expect(a.ultimas(5), [1, 2]);
    });
  });

  group('sonidos', () {
    test('la alarma de humo es una alerta', () {
      final s = sonidoDe([const Clase('Smoke detector, smoke alarm', 0.8)]);
      expect(s?.tipo, TipoSonido.alarma);
      expect(eventoDeSonido(s!.tipo), TipoEvento.alarma);
    });
    test('debajo del umbral no hay sonido', () {
      expect(sonidoDe([const Clase('Glass', 0.2)]), isNull);
    });
    test('la TV no pregunta «¿Está bien?»', () {
      expect(eventoDeSonido(TipoSonido.tv), isNull);
    });
    test('un quejido cuenta como pedido de ayuda', () {
      expect(
        sonidoDe([const Clase('Wail, moan', 0.4)])?.tipo,
        TipoSonido.grito,
      );
    });
    test('lee las etiquetas del CSV, también las que tienen coma', () {
      const csv =
          'index,mid,display_name\n0,/m/09x0r,Speech\n1,/m/0ytgt,"Child speech, kid speaking"\n';
      expect(leerEtiquetas(csv), ['Speech', 'Child speech, kid speaking']);
    });
  });
}
