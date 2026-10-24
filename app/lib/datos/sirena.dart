import 'package:flutter/services.dart';

/// La alarma que suena y vibra mientras «¿Está bien?» espera respuesta. En la app es el tono de
/// 520 Hz de Sirena.kt, que cada dos ciclos dice [frase] con la voz del teléfono; en las pruebas,
/// una falsa que anota.
abstract interface class Sirena {
  Future<void> sonar(String frase);

  /// Cambia lo que dice desde el próximo turno de voz, sin cortar el tono.
  Future<void> decir(String frase);

  Future<void> callar();
}

class SirenaAndroid implements Sirena {
  static const _canal = MethodChannel('casa/sirena');

  @override
  Future<void> sonar(String frase) =>
      _canal.invokeMethod<void>('sonar', {'frase': frase});

  @override
  Future<void> decir(String frase) =>
      _canal.invokeMethod<void>('decir', {'frase': frase});

  @override
  Future<void> callar() => _canal.invokeMethod<void>('callar');
}
