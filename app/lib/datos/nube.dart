import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../dominio/alerta.dart';
import '../dominio/tipos.dart';

/// Lo que la casa le cuenta a Supabase: el latido, los eventos y las alertas. Nunca audio.
///
/// Las funciones están en supabase/migrations/. Todas piden la clave de la casa, que vive solo en
/// app/config/local.json, y la llave pública no toca las tablas.
class Supabase {
  Supabase({required this.url, required this.llave, http.Client? cliente})
    : _cliente = cliente ?? http.Client();

  final String url;
  final String llave;
  final http.Client _cliente;

  /// Llama una función de la base. Lanza [ErrorNube] si no se pudo.
  Future<Object?> rpc(String funcion, Map<String, Object?> args) async {
    final http.Response r;
    try {
      r = await _cliente
          .post(
            Uri.parse('$url/rest/v1/rpc/$funcion'),
            headers: {'apikey': llave, 'Content-Type': 'application/json'},
            body: jsonEncode(args),
          )
          .timeout(const Duration(seconds: 10));
    } on Object catch (e) {
      throw ErrorNube('$funcion: $e', permanente: false);
    }
    // Un 4xx no se arregla reintentando (un tipo que la base no conoce, una función que no
    // existe); un 5xx o un 429 sí.
    if (r.statusCode >= 400) {
      throw ErrorNube(
        '$funcion: ${r.statusCode} ${r.body}',
        permanente:
            r.statusCode < 500 && r.statusCode != 408 && r.statusCode != 429,
      );
    }
    return r.body.isEmpty ? null : jsonDecode(r.body);
  }
}

class ErrorNube implements Exception {
  const ErrorNube(this.mensaje, {required this.permanente});

  final String mensaje;

  /// True si reintentar no sirve de nada.
  final bool permanente;

  @override
  String toString() => 'ErrorNube($mensaje)';
}

/// Si el teléfono tiene fuente de alimentación y cuánta batería le queda.
typedef Energia = ({bool enchufado, int bateria});

/// El nombre del evento en la base: `hueleGas` → `huele_gas`.
String tipoEnLaBase(TipoEvento t) =>
    t.name.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]!.toLowerCase()}');

/// Lo que la casa responde a una alerta, con el nombre que usa `casa_responder`.
String? respuestaEnLaBase(EstadoAlerta e) => switch (e) {
  EstadoAlerta.cancelada => 'cancelar',
  EstadoAlerta.escalada => 'escalar',
  EstadoAlerta.atendida => 'atender',
  EstadoAlerta.pendiente => null,
};

/// Un envío pendiente. Las alertas y las respuestas apuntan a su evento y a su alerta con un
/// número local, porque el id de la base llega recién cuando el envío anterior sale.
sealed class _Envio {}

class _Evento extends _Envio {
  _Evento(this.local, this.tipo, this.hora);
  final int local;
  final TipoEvento tipo;
  final DateTime hora;
}

class _Alerta extends _Envio {
  _Alerta(this.local, this.evento, this.venceEn, {required this.urgente});
  final int local;
  final int evento;
  final DateTime venceEn;
  final bool urgente;
}

class _Respuesta extends _Envio {
  _Respuesta(this.alerta, this.respuesta);
  final int alerta;
  final String respuesta;
}

/// Manda a Supabase lo que pasa en la casa, en orden y con una cola en memoria: si no hay
/// internet, lo guarda y reintenta cada [reintento]. Una alarma que la persona apagó sin
/// internet llega igual cuando vuelve, con su hora real.
///
/// El latido no hace cola: solo importa el último. Cada [cadaLatido] le dice a la base que la
/// casa sigue viva, y es lo que la familia ve como «sin señal» cuando deja de llegar.
class Nube {
  Nube(
    this._supabase, {
    required this.clave,
    this.energia,
    DateTime Function()? reloj,
    this.reintento = const Duration(seconds: 10),
  }) : _reloj = reloj ?? DateTime.now;

  /// Cada cuánto el latido. Ver docs/investigacion-alertas.md.
  static const cadaLatido = Duration(seconds: 90);

  /// Más que esto en la cola y se descarta lo más viejo: el teléfono no puede llenarse la memoria
  /// en un corte de días.
  static const maximoEnCola = 200;

  final Supabase _supabase;
  final String clave;
  final Future<Energia> Function()? energia;
  final DateTime Function() _reloj;
  final Duration reintento;

  final _cola = <_Envio>[];
  final _ids = <int, String>{};
  int _siguiente = 0;
  int? _alertaActual;
  Future<void>? _vaciando;
  Timer? _reintentar;
  Timer? _latiendo;

  /// Cuántos envíos esperan internet, para la línea de diagnóstico.
  int get enCola => _cola.length;

  /// Empieza a latir. El primer latido sale ya.
  void iniciar() {
    _latiendo?.cancel();
    _latiendo = Timer.periodic(cadaLatido, (_) => unawaited(latir()));
    unawaited(latir());
  }

  Future<void> latir() async {
    // Si Android no lo dice, se asume enchufado: el latido importa más que ese dato.
    Energia e = (enchufado: true, bateria: 100);
    try {
      e = await energia?.call() ?? e;
    } on Object catch (error) {
      debugPrint('Sin energía: $error');
    }
    try {
      await _supabase.rpc('casa_latido', {
        'p_clave': clave,
        'p_enchufado': e.enchufado,
        'p_bateria': e.bateria,
      });
    } on ErrorNube catch (error) {
      debugPrint('Sin latido: $error');
      return;
    }
    // Si hubo internet para el latido, también lo hay para lo que esperaba.
    await vaciar();
  }

  /// Nació una alerta en la casa: primero su evento, después la alerta.
  void nuevaAlerta(Alerta a) {
    final evento = _siguiente++;
    final alerta = _siguiente++;
    _alertaActual = alerta;
    _encolar(_Evento(evento, a.motivo, a.creada));
    _encolar(
      _Alerta(
        alerta,
        evento,
        a.venceEn,
        urgente: a.estado == EstadoAlerta.escalada,
      ),
    );
  }

  /// La alerta de la casa cambió de estado: «Estoy bien», «Necesito ayuda», se venció o alguien
  /// la atendió.
  void cambioDeEstado(EstadoAlerta estado) {
    final alerta = _alertaActual;
    final respuesta = respuestaEnLaBase(estado);
    if (alerta == null || respuesta == null) return;
    _encolar(_Respuesta(alerta, respuesta));
  }

  void _encolar(_Envio envio) {
    _cola.add(envio);
    if (_cola.length > maximoEnCola) _cola.removeAt(0);
    unawaited(vaciar());
  }

  /// Manda lo que haya en la cola, en orden. Si algo falla por la red, para y reintenta luego.
  /// Si ya se está mandando, devuelve ese mismo envío: nunca hay dos a la vez.
  Future<void> vaciar() => _vaciando ??= _vaciar().whenComplete(() {
    _vaciando = null;
  });

  Future<void> _vaciar() async {
    _reintentar?.cancel();
    while (_cola.isNotEmpty) {
      try {
        await _mandar(_cola.first);
      } on ErrorNube catch (e) {
        if (!e.permanente) {
          _reintentar = Timer(reintento, () => unawaited(vaciar()));
          return;
        }
        // Reintentar no lo arregla y no puede tapar lo que viene detrás.
        debugPrint('Descartado: $e');
      }
      _cola.removeAt(0);
    }
  }

  Future<void> _mandar(_Envio envio) async {
    switch (envio) {
      case _Evento(:final local, :final tipo, :final hora):
        final id = await _supabase.rpc('casa_evento', {
          'p_clave': clave,
          'p_tipo': tipoEnLaBase(tipo),
          'p_descripcion': tipo.frase,
          'p_hora': hora.toUtc().toIso8601String(),
        });
        _guardar(local, id, 'casa_evento');
      case _Alerta(:final local, :final evento, :final venceEn, :final urgente):
        final idEvento = _ids[evento];
        // Si su evento se descartó, no hay a qué colgarla.
        if (idEvento == null) return;
        // Lo que le quedaba en la casa, por si sale tarde. La base no baja de 5 s, y si ya venció
        // en la casa, la respuesta «escalar» va justo detrás.
        final espera = venceEn.difference(_reloj()).inSeconds;
        final id = await _supabase.rpc('casa_alerta', {
          'p_clave': clave,
          'p_evento': idEvento,
          'p_espera_s': espera < 0 ? 0 : espera,
          'p_urgente': urgente,
        });
        _guardar(local, id, 'casa_alerta');
      case _Respuesta(:final alerta, :final respuesta):
        final idAlerta = _ids[alerta];
        if (idAlerta == null) return;
        await _supabase.rpc('casa_responder', {
          'p_clave': clave,
          'p_alerta': idAlerta,
          'p_respuesta': respuesta,
        });
    }
  }

  // La base devuelve null si la clave no es de ninguna casa: es permanente.
  void _guardar(int local, Object? id, String funcion) {
    if (id is! String) {
      throw ErrorNube('$funcion devolvió $id: ¿la clave?', permanente: true);
    }
    _ids[local] = id;
  }

  void dispose() {
    _reintentar?.cancel();
    _latiendo?.cancel();
  }
}
