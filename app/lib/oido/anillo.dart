import 'dart:math' as math;
import 'dart:typed_data';

/// Los últimos segundos de audio, en memoria. Se pisa a sí mismo: el audio nunca se guarda
/// ni se envía, solo sirve para clasificar también lo que sonó justo antes del disparo.
class Anillo {
  Anillo(int capacidad) : _datos = Float32List(math.max(1, capacidad));

  final Float32List _datos;
  int _pos = 0;
  bool _lleno = false;

  int get disponibles => _lleno ? _datos.length : _pos;

  void escribir(Float32List bloque) {
    for (final m in bloque) {
      _datos[_pos] = m;
      _pos = (_pos + 1) % _datos.length;
      if (_pos == 0) _lleno = true;
    }
  }

  /// Copia de las últimas `n` muestras, de la más vieja a la más nueva.
  Float32List ultimas(int n) {
    final m = math.min(math.max(0, n), disponibles);
    final salida = Float32List(m);
    final inicio = (_pos - m + _datos.length) % _datos.length;
    for (var i = 0; i < m; i++) {
      salida[i] = _datos[(inicio + i) % _datos.length];
    }
    return salida;
  }
}
