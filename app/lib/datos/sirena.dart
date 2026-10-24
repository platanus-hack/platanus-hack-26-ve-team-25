import 'package:flutter/services.dart';

/// La alarma que suena y vibra mientras «¿Está bien?» espera respuesta. En la app es el tono de
/// 520 Hz de Sirena.kt; en las pruebas, una falsa que anota.
abstract interface class Sirena {
  Future<void> sonar();
  Future<void> callar();
}

class SirenaAndroid implements Sirena {
  static const _canal = MethodChannel('casa/sirena');

  @override
  Future<void> sonar() => _canal.invokeMethod<void>('sonar');

  @override
  Future<void> callar() => _canal.invokeMethod<void>('callar');
}
