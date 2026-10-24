import 'dart:async';

import 'package:casa/datos/llamadas.dart';
import 'package:flutter/services.dart';

/// Un teléfono falso: anota las llamadas y deja simular el fin de un WhatsApp.
class TelefonoFalso implements Telefono {
  TelefonoFalso({this.whatsappFunciona = true, this.whatsappFalla = false});

  final bool whatsappFunciona;
  final bool whatsappFalla;
  final porWhatsApp = <String>[];
  final porTelefono = <String>[];
  final _fin = StreamController<int>.broadcast();

  void terminarWhatsApp(int segundos) => _fin.add(segundos);

  @override
  Future<bool> whatsapp(String numero) async {
    if (whatsappFalla) throw PlatformException(code: 'error');
    if (whatsappFunciona) porWhatsApp.add(numero);
    return whatsappFunciona;
  }

  @override
  Future<void> llamar(String numero) async => porTelefono.add(numero);

  @override
  Stream<int> get finDeWhatsApp => _fin.stream;
}
