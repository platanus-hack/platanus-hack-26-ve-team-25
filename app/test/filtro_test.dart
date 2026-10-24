import 'dart:math' as math;
import 'dart:typed_data';

import 'package:casa/oido/filtro.dart';
import 'package:flutter_test/flutter_test.dart';

const _tasa = 16000;

Float32List _seno(double f, {double amplitud = 0.5, int n = _tasa}) =>
    Float32List.fromList([
      for (var i = 0; i < n; i++)
        amplitud * math.sin(2 * math.pi * f * i / _tasa),
    ]);

// La sirena como la arma Sirena.kt: la onda cuadrada de 520 Hz como suma de sus armónicos impares.
Float32List _sirena({int n = _tasa}) => Float32List.fromList([
  for (var i = 0; i < n; i++)
    0.6 *
        [
          for (var k = 1; k * frecuenciaSirena < _tasa / 2; k += 2)
            math.sin(2 * math.pi * k * frecuenciaSirena * i / _tasa) / k,
        ].fold(0.0, (a, b) => a + b),
]);

// Energía en dB, sin el primer cuarto de segundo, donde el filtro todavía se asienta.
double _db(Float32List x) {
  var suma = 0.0;
  for (var i = _tasa ~/ 4; i < x.length; i++) {
    suma += x[i] * x[i];
  }
  return 10 * math.log(suma / (x.length - _tasa ~/ 4)) / math.ln10;
}

void main() {
  test('la sirena baja más de 30 dB', () {
    final antes = _db(_sirena());
    final despues = _db(quitarSirena(_sirena()));
    printOnFailure('baja ${(antes - despues).toStringAsFixed(1)} dB');
    expect(antes - despues, greaterThan(30));
  });

  test('una voz entre los armónicos casi no se toca', () {
    // 300, 700 y 1.800 Hz: el grave, el medio y el agudo de una voz, lejos de los múltiplos de 520.
    for (final f in [300.0, 700.0, 1800.0]) {
      final antes = _db(_seno(f));
      final despues = _db(quitarSirena(_seno(f)));
      expect(antes - despues, lessThan(1), reason: '$f Hz');
    }
  });

  test('voz encima de la sirena: después del filtro manda la voz', () {
    final voz = _seno(700, amplitud: 0.1);
    final sirena = _sirena();
    final mezcla = Float32List.fromList([
      for (var i = 0; i < _tasa; i++) voz[i] + sirena[i],
    ]);
    final limpia = quitarSirena(mezcla);
    // Lo que queda es casi solo la voz.
    expect((_db(limpia) - _db(voz)).abs(), lessThan(3));
  });
}
