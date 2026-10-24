import 'dart:math' as math;
import 'dart:typed_data';

// Nivel de sonido y compuerta barata: corren con cada bloque de audio, antes del modelo.
// Es la misma lógica que web/src/lib/escucha/nivel.ts, que ya se probó en /escucha.

/// Nivel RMS de un bloque en dBFS: 0 es el máximo digital, el silencio queda cerca de -100.
double rmsDb(Float32List bloque) {
  var suma = 0.0;
  for (final m in bloque) {
    suma += m * m;
  }
  final rms = math.sqrt(suma / math.max(1, bloque.length));
  return 20 * math.log(math.max(rms, 1e-5)) / math.ln10;
}

/// El ruido de fondo de la casa. Sigue al nivel con un promedio lento y casi no se deja
/// arrastrar por los picos: un golpe no sube el fondo, pero una TV que se queda prendida sí,
/// poco a poco.
class LineaBase {
  LineaBase({this.alfa = 0.02, this.alfaPico = 0.002, this.margenPicoDb = 6});

  final double alfa;
  final double alfaPico;
  final double margenPicoDb;
  double? _valor;

  double actualizar(double db) {
    final v = _valor;
    if (v == null) {
      _valor = db;
    } else {
      final esPico = db > v + margenPicoDb;
      _valor = v + (esPico ? alfaPico : alfa) * (db - v);
    }
    return _valor!;
  }

  double get actual => _valor ?? -100;
}

/// Se abre cuando el nivel salta `umbralDb` sobre el fondo y se sostiene `sostenMs`.
class Compuerta {
  Compuerta({this.umbralDb = 15, this.sostenMs = 1500});

  final double umbralDb;
  final int sostenMs;
  int _abiertaHasta = 0;

  bool evaluar(double db, double fondo, int ahoraMs) {
    if (db - fondo >= umbralDb) _abiertaHasta = ahoraMs + sostenMs;
    return ahoraMs < _abiertaHasta;
  }
}
