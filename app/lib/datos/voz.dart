import 'dart:async';

import 'package:speech_to_text/speech_to_text.dart';

/// Escucha una respuesta corta por voz. En la app es el reconocimiento de voz de Android; en las
/// pruebas, uno falso que devuelve lo que se le diga.
abstract interface class Voz {
  /// Las versiones de lo que entendió, de la más probable a la menos. Vacía si no entendió nada,
  /// no hay permiso o el teléfono no tiene reconocimiento de voz.
  Future<List<String>> escuchar({required Duration hasta});
}

/// El reconocimiento de voz del sistema, en español. Funciona sin internet si el teléfono tiene
/// descargado el paquete de español; si no, usa internet si hay.
class VozAndroid implements Voz {
  final _stt = SpeechToText();
  bool? _listo;
  String? _idioma;
  Completer<List<String>>? _respuesta;
  List<String> _ultimas = const [];

  @override
  Future<List<String>> escuchar({required Duration hasta}) async {
    _listo ??= await _stt.initialize(
      onError: (_) => _terminar(),
      onStatus: (estado) {
        if (estado == SpeechToText.doneStatus) _terminar();
      },
    );
    if (!_listo!) return const [];
    _idioma ??= await _espanol();

    _ultimas = const [];
    final respuesta = _respuesta = Completer<List<String>>();
    await _stt.listen(
      onResult: (r) {
        _ultimas = [for (final a in r.alternates) a.recognizedWords];
        if (r.finalResult) _terminar();
      },
      listenOptions: SpeechListenOptions(
        listenFor: hasta,
        pauseFor: const Duration(seconds: 4),
        localeId: _idioma,
        partialResults: false,
        cancelOnError: true,
        listenMode: ListenMode.confirmation,
      ),
    );
    return respuesta.future.timeout(
      hasta + const Duration(seconds: 2),
      onTimeout: () async {
        await _stt.cancel();
        return _ultimas;
      },
    );
  }

  void _terminar() {
    final r = _respuesta;
    if (r != null && !r.isCompleted) r.complete(_ultimas);
  }

  /// El español del teléfono, prefiriendo el latinoamericano. Null usa el idioma del sistema.
  Future<String?> _espanol() async {
    final idiomas = (await _stt.locales()).map((l) => l.localeId).toList();
    for (final preferido in [
      'es_VE',
      'es-VE',
      'es_US',
      'es-US',
      'es_419',
      'es-419',
      'es_ES',
      'es-ES',
    ]) {
      if (idiomas.contains(preferido)) return preferido;
    }
    return idiomas.where((i) => i.startsWith('es')).firstOrNull;
  }
}
