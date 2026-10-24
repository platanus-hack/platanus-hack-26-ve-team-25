/// Una toma del día: qué pastilla, a qué hora y cómo se ve, para que la persona la reconozca
/// aunque no lea bien el nombre.
class Pastilla {
  const Pastilla({
    required this.id,
    required this.nombre,
    required this.dosis,
    required this.hora,
    required this.minuto,
    required this.colores,
    this.indicacion = '1 pastilla, con agua',
  });

  final String id;
  final String nombre;
  final String dosis;
  final int hora;
  final int minuto;

  /// Los colores de la cápsula, de izquierda a derecha (ARGB). Uno solo si es de un color.
  final List<int> colores;
  final String indicacion;

  String get horaTexto => '$hora:${minuto.toString().padLeft(2, '0')}';

  DateTime enElDia(DateTime dia) =>
      DateTime(dia.year, dia.month, dia.day, hora, minuto);
}

enum EstadoToma { tomada, leToca, masTarde, olvidada }

/// Las tomas del día y lo que la persona ya respondió. Es Dart puro: la pantalla solo pregunta.
class PlanDelDia {
  PlanDelDia(List<Pastilla> pastillas)
    : pastillas = [...pastillas]
        ..sort(
          (a, b) => (a.hora * 60 + a.minuto).compareTo(b.hora * 60 + b.minuto),
        );

  /// Cuánto tiempo después de la hora sigue «tocándole». Pasado eso, la toma se considera olvidada
  /// y es un aviso amarillo para la familia.
  static const ventana = Duration(hours: 2);

  final List<Pastilla> pastillas;
  final _tomadas = <String, DateTime>{};

  bool tomada(Pastilla p) => _tomadas.containsKey(p.id);

  EstadoToma estado(Pastilla p, DateTime ahora) {
    if (tomada(p)) return EstadoToma.tomada;
    final hora = p.enElDia(ahora);
    if (ahora.isBefore(hora)) return EstadoToma.masTarde;
    if (ahora.isBefore(hora.add(ventana))) return EstadoToma.leToca;
    return EstadoToma.olvidada;
  }

  /// La toma que le toca ahora, o null. Es la primera del día que esté en su ventana.
  Pastilla? leToca(DateTime ahora) {
    for (final p in pastillas) {
      if (estado(p, ahora) == EstadoToma.leToca) return p;
    }
    return null;
  }

  /// La que hay que recordar en pantalla completa: la que le toca. No se puede posponer.
  Pastilla? recordar(DateTime ahora) => leToca(ahora);

  void marcarTomada(Pastilla p, DateTime ahora) => _tomadas[p.id] = ahora;

  /// Para probar sin esperar a la hora: la próxima toma pendiente pasa a tocar ya.
  Pastilla? siguientePendiente(DateTime ahora) {
    for (final p in pastillas) {
      if (!tomada(p) && estado(p, ahora) != EstadoToma.olvidada) return p;
    }
    return null;
  }
}
