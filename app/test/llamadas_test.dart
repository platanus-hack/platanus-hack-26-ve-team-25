import 'package:casa/datos/llamadas.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'si WhatsApp puede, la llamada sale por WhatsApp y no por teléfono',
    () async {
      final telefono = <String>[];
      final via = await llamarPrimeroPorWhatsApp(
        '04120000000',
        whatsapp: (_) async => true,
        telefono: (n) async => telefono.add(n),
      );
      expect(via, ViaLlamada.whatsapp);
      expect(telefono, isEmpty);
    },
  );

  test(
    'si WhatsApp no encuentra el contacto, cae a la llamada normal',
    () async {
      final telefono = <String>[];
      final via = await llamarPrimeroPorWhatsApp(
        '04120000000',
        whatsapp: (_) async => false,
        telefono: (n) async => telefono.add(n),
      );
      expect(via, ViaLlamada.telefono);
      expect(telefono, ['04120000000']);
    },
  );

  test('si WhatsApp falla, también cae a la llamada normal', () async {
    final telefono = <String>[];
    final via = await llamarPrimeroPorWhatsApp(
      '04120000000',
      whatsapp: (_) async => throw PlatformException(code: 'error'),
      telefono: (n) async => telefono.add(n),
    );
    expect(via, ViaLlamada.telefono);
    expect(telefono, hasLength(1));
  });
}
