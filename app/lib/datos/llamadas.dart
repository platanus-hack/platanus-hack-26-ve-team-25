import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';

/// Por dónde salió la llamada de emergencia.
enum ViaLlamada { whatsapp, telefono }

/// Lo que la casa sabe hacer con el teléfono. En la app es Android de verdad; en las pruebas,
/// uno falso que anota las llamadas.
abstract interface class Telefono {
  /// Abre una llamada de voz de WhatsApp. False si no se pudo.
  Future<bool> whatsapp(String numero);

  /// Una llamada telefónica normal y directa.
  Future<void> llamar(String numero);

  /// True si hay internet de verdad, por wifi o por datos. Sin internet, WhatsApp no puede llamar.
  Future<bool> hayInternet();

  /// Una llamada normal en altavoz y con el volumen al máximo: para emergencias, o cuando la
  /// persona la pidió en voz alta y puede estar lejos del teléfono. False si no se pudo.
  Future<bool> llamarEnAltavoz(String numero);

  /// Cada vez que termina una llamada de WhatsApp, cuántos segundos duró, timbre incluido.
  /// Android no dice si la contestaron.
  Stream<int> get finDeWhatsApp;
}

/// WhatsApp primero: los hijos suelen estar fuera del país, y una llamada normal al exterior
/// cuesta y muchas veces no entra. Si no hay internet, ni se intenta: WhatsApp timbraría sin
/// salir y se perderían segundos. Si WhatsApp no se puede (no está instalado, el contacto no está
/// en la agenda o falta el permiso), también cae a la llamada telefónica normal.
Future<ViaLlamada> llamarPrimeroPorWhatsApp(String numero, Telefono t) async {
  try {
    if (await t.hayInternet() && await t.whatsapp(numero)) {
      return ViaLlamada.whatsapp;
    }
  } on PlatformException {
    // Cualquier falla de WhatsApp termina en la llamada normal: lo importante es que salga.
  }
  await t.llamar(numero);
  return ViaLlamada.telefono;
}

/// El teléfono de verdad. El lado de WhatsApp está en MainActivity.kt.
class TelefonoAndroid implements Telefono {
  TelefonoAndroid() {
    _canal.setMethodCallHandler((llamada) async {
      if (llamada.method == 'whatsappTermino') {
        _fin.add((llamada.arguments as Map)['segundos'] as int);
      }
    });
  }

  static const _canal = MethodChannel('casa/llamadas');
  final _fin = StreamController<int>.broadcast();

  @override
  Future<bool> whatsapp(String numero) async =>
      await _canal.invokeMethod<bool>('whatsapp', {'numero': numero}) ?? false;

  @override
  Future<void> llamar(String numero) async =>
      FlutterPhoneDirectCaller.callNumber(numero);

  @override
  Future<bool> hayInternet() async =>
      await _canal.invokeMethod<bool>('hayInternet') ?? true;

  @override
  Future<bool> llamarEnAltavoz(String numero) async =>
      await _canal.invokeMethod<bool>('llamarEnAltavoz', {'numero': numero}) ??
      false;

  @override
  Stream<int> get finDeWhatsApp => _fin.stream;
}
