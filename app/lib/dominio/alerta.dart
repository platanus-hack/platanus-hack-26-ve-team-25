import 'tipos.dart';

/// Cuánto espera la casa a que la persona responda antes de avisar a la familia.
/// En el demo se corre con `--dart-define=DEMO=true` para que sean 15 s.
const esperaConfirmacion = bool.fromEnvironment('DEMO')
    ? Duration(seconds: 15)
    : Duration(seconds: 60);

/// Cuántos ciclos de 4 s del tono suenan antes de que la voz pregunte. Con 60 s son dos; con los
/// 15 s de la tarima, uno: así la pregunta y su ventana callada (4 s) caben antes de avisar.
const ciclosAntesDeLaPregunta = bool.fromEnvironment('DEMO') ? 1 : 2;

/// Los estados de una alerta, con las únicas transiciones válidas:
///
///     pendiente ──► cancelada            la persona tocó «Estoy bien»
///     pendiente ──► escalada ──► atendida  nadie respondió, o pidió ayuda
enum EstadoAlerta { pendiente, cancelada, escalada, atendida }

/// Una alerta es inmutable: cada transición devuelve una alerta nueva. Una transición que no
/// vale desde el estado actual devuelve la misma alerta sin cambios, así un toque doble o un
/// reloj que llega tarde nunca la hacen retroceder.
class Alerta {
  const Alerta._({
    required this.motivo,
    required this.nivel,
    required this.estado,
    required this.creada,
    required this.venceEn,
    this.escaladaEn,
    this.cerradaEn,
    this.atendidaPor,
  });

  /// Un evento que pide confirmación: suena la alarma en la casa y corre la cuenta regresiva.
  factory Alerta.preguntar(
    TipoEvento motivo,
    DateTime ahora, {
    Duration espera = esperaConfirmacion,
  }) => Alerta._(
    motivo: motivo,
    nivel: Nivel.rojo,
    estado: EstadoAlerta.pendiente,
    creada: ahora,
    venceEn: ahora.add(espera),
  );

  /// El botón de pánico y los reportes de la persona no esperan: avisan a la familia ya.
  factory Alerta.urgente(TipoEvento motivo, DateTime ahora) => Alerta._(
    motivo: motivo,
    nivel: Nivel.rojo,
    estado: EstadoAlerta.escalada,
    creada: ahora,
    venceEn: ahora,
    escaladaEn: ahora,
  );

  final TipoEvento motivo;
  final Nivel nivel;
  final EstadoAlerta estado;
  final DateTime creada;
  final DateTime venceEn;
  final DateTime? escaladaEn;
  final DateTime? cerradaEn;
  final String? atendidaPor;

  bool get abierta =>
      estado == EstadoAlerta.pendiente || estado == EstadoAlerta.escalada;

  /// Lo que falta para avisar a la familia. Cero si ya venció o si no está pendiente.
  Duration restante(DateTime ahora) {
    if (estado != EstadoAlerta.pendiente || !ahora.isBefore(venceEn)) {
      return Duration.zero;
    }
    return venceEn.difference(ahora);
  }

  /// «Estoy bien» antes de que venza: falsa alarma, la familia no se entera como urgencia.
  Alerta cancelar(DateTime ahora) => estado == EstadoAlerta.pendiente
      ? _copia(estado: EstadoAlerta.cancelada, cerradaEn: ahora)
      : this;

  /// «Necesito ayuda», o se acabó el tiempo sin respuesta.
  Alerta escalar(DateTime ahora) => estado == EstadoAlerta.pendiente
      ? _copia(estado: EstadoAlerta.escalada, escaladaEn: ahora)
      : this;

  /// Alguien se hizo cargo: la familia, el vecino o la misma persona («Fue sin querer»).
  Alerta atender(DateTime ahora, String quien) =>
      estado == EstadoAlerta.escalada
      ? _copia(
          estado: EstadoAlerta.atendida,
          cerradaEn: ahora,
          atendidaPor: quien,
        )
      : this;

  /// Se llama con cada tic del reloj: si venció sin respuesta, escala.
  Alerta revisar(DateTime ahora) =>
      estado == EstadoAlerta.pendiente && !ahora.isBefore(venceEn)
      ? escalar(ahora)
      : this;

  Alerta _copia({
    required EstadoAlerta estado,
    DateTime? escaladaEn,
    DateTime? cerradaEn,
    String? atendidaPor,
  }) => Alerta._(
    motivo: motivo,
    nivel: nivel,
    estado: estado,
    creada: creada,
    venceEn: venceEn,
    escaladaEn: escaladaEn ?? this.escaladaEn,
    cerradaEn: cerradaEn ?? this.cerradaEn,
    atendidaPor: atendidaPor ?? this.atendidaPor,
  );
}
