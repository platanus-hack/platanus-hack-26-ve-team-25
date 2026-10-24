import 'dart:async';

import 'package:casa/datos/llamadas.dart';
import 'package:flutter/services.dart';

/// Un teléfono falso: anota las llamadas y deja simular el fin de un WhatsApp.
class TelefonoFalso implements Telefono {
  TelefonoFalso({
    this.whatsappFunciona = true,
    this.whatsappFalla = false,
    this.conInternet = true,
  });

  final bool whatsappFunciona;
  final bool whatsappFalla;
  final bool conInternet;
  final porWhatsApp = <String>[];
  final porTelefono = <String>[];
  final enAltavoz = <String>[];
  final _fin = StreamController<int>.broadcast();
  final _finTelefono = StreamController<int>.broadcast();

  void terminarWhatsApp(int segundos) => _fin.add(segundos);
  void terminarTelefono(int segundos) => _finTelefono.add(segundos);

  @override
  Future<bool> whatsapp(String numero) async {
    if (whatsappFalla) throw PlatformException(code: 'error');
    if (whatsappFunciona) porWhatsApp.add(numero);
    return whatsappFunciona;
  }

  @override
  Future<void> llamar(String numero) async => porTelefono.add(numero);

  @override
  Future<bool> hayInternet() async => conInternet;

  @override
  Future<bool> llamarEnAltavoz(String numero) async {
    enAltavoz.add(numero);
    return true;
  }

  @override
  Stream<int> get finDeWhatsApp => _fin.stream;

  @override
  Stream<int> get finDeTelefono => _finTelefono.stream;
}
