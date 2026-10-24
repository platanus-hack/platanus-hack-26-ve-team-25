import 'dart:async';
import 'dart:typed_data';

import 'package:casa/datos/frases.dart';
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
  Uint8List ultimoAudio(Duration duracion) =>
      Uint8List(32000 * duracion.inSeconds);

  @override
  Future<void> pausar() async => pasos.add('pausar');

  @override
  Future<void> reanudar() async => pasos.add('reanudar');
}

/// Un Vosk falso: contesta lo que la prueba le diga y anota cuánto audio recibió.
class FrasesFalsas implements Frases {
  FrasesFalsas(this.oye);

  final List<String> oye;
  final audios = <int>[];

  @override
  Future<List<String>> reconocer(Uint8List pcm) async {
    audios.add(pcm.length);
    return oye;
  }
}
