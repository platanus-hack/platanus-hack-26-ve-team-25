import 'dart:async';

import 'package:flutter/services.dart';

/// La alarma de «¿Está bien?»: en la app, Sirena.kt pregunta con la voz del teléfono, se calla
/// para oír la respuesta y vuelve a preguntar; al final suenan el tono de 520 Hz y la vibración.
/// En las pruebas, una falsa que anota.
abstract interface class Sirena {
  /// Empieza a preguntar: dice [primera] de una vez, sin tono, y después [frase] entre ventanas
  /// para contestar. El tono espera a [tono].
  Future<void> sonar(String frase, {String? primera});

  /// Los últimos segundos: se calla la voz y suenan el tono de 520 Hz y la vibración.
  Future<void> tono();

  /// Cambia lo que dice desde el próximo turno de voz.
  Future<void> decir(String frase);

  Future<void> callar();

  /// True cuando, después de la frase, la sirena se calla unos segundos para que la persona
  /// conteste; false cuando se cierra la ventana.
  Stream<bool> get ventanas;

  /// True cuando la voz del teléfono empieza a decir la frase; false cuando termina o se corta.
  Stream<bool> get hablando;
}

class SirenaAndroid implements Sirena {
  SirenaAndroid() {
    _canal.setMethodCallHandler((llamada) async {
      final si = llamada.arguments as bool;
      switch (llamada.method) {
        case 'ventana':
          _ventanas.add(si);
        case 'hablando':
          _hablando.add(si);
      }
    });
  }

  static const _canal = MethodChannel('casa/sirena');
  final _ventanas = StreamController<bool>.broadcast();
  final _hablando = StreamController<bool>.broadcast();

  @override
  Stream<bool> get ventanas => _ventanas.stream;

  @override
  Stream<bool> get hablando => _hablando.stream;

  @override
  Future<void> sonar(String frase, {String? primera}) =>
      _canal.invokeMethod<void>('sonar', {'frase': frase, 'primera': primera});

  @override
  Future<void> tono() => _canal.invokeMethod<void>('tono');

  @override
  Future<void> decir(String frase) =>
      _canal.invokeMethod<void>('decir', {'frase': frase});

  @override
  Future<void> callar() => _canal.invokeMethod<void>('callar');
}
