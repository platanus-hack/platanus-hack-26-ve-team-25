import 'dart:math' as math;
import 'dart:typed_data';

/// La frecuencia de la sirena de «¿Está bien?» (Sirena.kt).
const frecuenciaSirena = 520.0;

/// Le quita a un audio la sirena de 520 Hz, para que Vosk entienda «Lucero, estoy bien» dicho
/// encima de la alarma.
///
/// No se emite la onda contraria por el parlante: cancelaría la sirena también para quien la
/// tiene que oír. Se resta en lo que oye el micrófono, y solo en lo que va a Vosk; YAMNet sigue
/// oyendo todo. Como la sirena es una onda cuadrada conocida, su energía está solo en 520 Hz y sus
/// múltiplos (los impares de la onda, y los pares que agrega la distorsión del parlante). Un filtro
/// muesca de [ancho] Hz en cada uno corta la sirena y apenas toca la voz, que se reparte entre
/// 300 y 3.400 Hz.
Float32List quitarSirena(
  Float32List muestras, {
  double tasa = 16000,
  double ancho = 40,
}) {
  var salida = Float32List.fromList(muestras);
  for (var f = frecuenciaSirena; f < tasa / 2 - ancho; f += frecuenciaSirena) {
    salida = _muesca(salida, f, ancho, tasa);
  }
  return salida;
}

// Un biquad de muesca (Robert Bristow-Johnson, «Audio EQ Cookbook»).
Float32List _muesca(Float32List x, double f, double ancho, double tasa) {
  final w = 2 * math.pi * f / tasa;
  final alfa =
      math.sin(w) * _sinh(math.ln2 / 2 * _octavas(f, ancho) * w / math.sin(w));
  final a0 = 1 + alfa;
  final b0 = 1 / a0;
  final b1 = -2 * math.cos(w) / a0;
  final b2 = 1 / a0;
  final a1 = -2 * math.cos(w) / a0;
  final a2 = (1 - alfa) / a0;
  final y = Float32List(x.length);
  double x1 = 0, x2 = 0, y1 = 0, y2 = 0;
  for (var i = 0; i < x.length; i++) {
    final v = b0 * x[i] + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2;
    x2 = x1;
    x1 = x[i];
    y2 = y1;
    y1 = v;
    y[i] = v;
  }
  return y;
}

// El ancho de la muesca en octavas, para que mida [ancho] Hz en cualquier frecuencia.
double _octavas(double f, double ancho) =>
    math.log((f + ancho / 2) / (f - ancho / 2)) / math.ln2;

double _sinh(double x) => (math.exp(x) - math.exp(-x)) / 2;
