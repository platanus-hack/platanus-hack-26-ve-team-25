import 'dart:async';

import 'package:flutter/services.dart';

import '../dominio/alerta.dart';

/// La alarma que suena y vibra mientras «¿Está bien?» espera respuesta. En la app es el tono de
/// 520 Hz de Sirena.kt, que cada dos ciclos dice [frase] con la voz del teléfono; en las pruebas,
/// una falsa que anota.
abstract interface class Sirena {
  Future<void> sonar(String frase);

  /// Cambia lo que dice desde el próximo turno de voz, sin cortar el tono.
  Future<void> decir(String frase);

  Future<void> callar();

  /// True cuando, después de la frase, la sirena se calla unos segundos para que la persona
  /// conteste; false cuando vuelve el tono.
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
  Future<void> sonar(String frase) => _canal.invokeMethod<void>('sonar', {
    'frase': frase,
    'ciclosAntes': ciclosAntesDeLaPregunta,
  });

  @override
  Future<void> decir(String frase) =>
      _canal.invokeMethod<void>('decir', {'frase': frase});

  @override
  Future<void> callar() => _canal.invokeMethod<void>('callar');
}
