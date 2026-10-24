import 'package:flutter/services.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';

/// Por dónde salió la llamada de emergencia.
enum ViaLlamada { whatsapp, telefono }

/// WhatsApp primero: los hijos suelen estar fuera del país, y una llamada normal al exterior
/// cuesta y muchas veces no entra. Si WhatsApp no se puede (no está instalado, el contacto no
/// está en la agenda o falta el permiso), cae a la llamada telefónica normal.
Future<ViaLlamada> llamarPrimeroPorWhatsApp(
  String numero, {
  required Future<bool> Function(String numero) whatsapp,
  required Future<void> Function(String numero) telefono,
}) async {
  try {
    if (await whatsapp(numero)) return ViaLlamada.whatsapp;
  } on PlatformException {
    // Cualquier falla de WhatsApp termina en la llamada normal: lo importante es que salga.
  }
  await telefono(numero);
  return ViaLlamada.telefono;
}

const _canal = MethodChannel('casa/llamadas');

/// La llamada de verdad, en el teléfono: el lado de WhatsApp está en MainActivity.kt.
Future<ViaLlamada> llamarEnElTelefono(String numero) =>
    llamarPrimeroPorWhatsApp(
      numero,
      whatsapp: (n) async =>
          await _canal.invokeMethod<bool>('whatsapp', {'numero': n}) ?? false,
      telefono: (n) async => FlutterPhoneDirectCaller.callNumber(n),
    );
