import 'dart:async';

import 'package:casa/datos/voz.dart';
import 'package:casa/oido/oido.dart';

/// Una voz falsa: devuelve lo que la prueba le diga cuando la prueba quiera.
class VozFalsa implements Voz {
  final _respuesta = Completer<List<String>>();
  bool escucho = false;

  void responder(List<String> versiones) => _respuesta.complete(versiones);

  @override
  Future<List<String>> escuchar({required Duration hasta}) {
    escucho = true;
    return _respuesta.future;
  }
}

/// Un micrófono falso que anota si lo pausaron y lo reanudaron.
class MicrofonoFalso implements Microfono {
  final pasos = <String>[];

  @override
  Future<void> pausar() async => pasos.add('pausar');

  @override
  Future<void> reanudar() async => pasos.add('reanudar');
}
