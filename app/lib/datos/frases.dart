import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../dominio/pedidos.dart';

/// Lo que se dijo en voz alta en la casa, reconocido sin internet. En la app es Vosk (el lado
/// nativo está en Frases.kt); en las pruebas, uno falso.
abstract interface class Frases {
  /// Las frases del banco de pedidos que se dijeron en este audio (PCM de 16 bits a 16 kHz).
  /// Vacía si no se dijo ninguna o no se entendió con confianza.
  Future<List<String>> reconocer(Uint8List pcm);
}

/// Una palabra que Vosk reconoció con menos confianza que esto no cuenta. Con la gramática
/// cerrada, Vosk tiende a forzar una frase del banco sobre cualquier voz: la confianza es lo que
/// separa «ayuda» de una conversación que se le parece. Ajustar con voces mayores reales.
const confianzaMinima = 0.6;

/// Lee el resultado de Vosk y deja solo el texto de las palabras con confianza suficiente. Vosk
/// devuelve `{"result": [{"word": "ayuda", "conf": 0.93}, …], "text": "ayuda"}`.
String textoConfiable(String json, {double umbral = confianzaMinima}) {
  final r = jsonDecode(json) as Map<String, dynamic>;
  final palabras = (r['result'] as List?) ?? const [];
  return [
    for (final p in palabras.cast<Map<String, dynamic>>())
      if ((p['conf'] as num? ?? 0) >= umbral && p['word'] != '[unk]') p['word'],
  ].join(' ');
}

class FrasesVosk implements Frases {
  static const _canal = MethodChannel('casa/frases');
  bool _listo = false;

  /// Copia el modelo a la memoria del teléfono la primera vez y le da el banco como gramática.
  /// Si falta el modelo (tool/descargar_vosk.sh), la casa sigue oyendo sin las frases.
  Future<void> iniciar() async {
    try {
      _listo =
          await _canal.invokeMethod<bool>('iniciar', {
            'frases': [...todasLasFrases, '[unk]'],
          }) ??
          false;
    } on PlatformException catch (e) {
      debugPrint('Sin Vosk: $e');
    }
  }

  @override
  Future<List<String>> reconocer(Uint8List pcm) async {
    if (!_listo) return const [];
    final json = await _canal.invokeMethod<String>('reconocer', {'pcm': pcm});
    if (json == null) return const [];
    final texto = textoConfiable(json);
    return texto.isEmpty ? const [] : [texto];
  }
}
