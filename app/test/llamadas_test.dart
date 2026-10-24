import 'package:casa/datos/llamadas.dart';
import 'package:flutter_test/flutter_test.dart';

import 'telefono_falso.dart';

void main() {
  test(
    'si WhatsApp puede, la llamada sale por WhatsApp y no por teléfono',
    () async {
      final t = TelefonoFalso();
      expect(
        await llamarPrimeroPorWhatsApp('04120000000', t),
        ViaLlamada.whatsapp,
      );
      expect(t.porTelefono, isEmpty);
    },
  );

  test(
    'si WhatsApp no encuentra el contacto, cae a la llamada normal',
    () async {
      final t = TelefonoFalso(whatsappFunciona: false);
      expect(
        await llamarPrimeroPorWhatsApp('04120000000', t),
        ViaLlamada.telefono,
      );
      expect(t.porTelefono, ['04120000000']);
    },
  );

  test('si WhatsApp falla, también cae a la llamada normal', () async {
    final t = TelefonoFalso(whatsappFalla: true);
    expect(
      await llamarPrimeroPorWhatsApp('04120000000', t),
      ViaLlamada.telefono,
    );
    expect(t.porTelefono, hasLength(1));
  });

  test('sin internet ni se intenta WhatsApp: llamada normal directa', () async {
    final t = TelefonoFalso(conInternet: false);
    expect(
      await llamarPrimeroPorWhatsApp('04120000000', t),
      ViaLlamada.telefono,
    );
    expect(t.porWhatsApp, isEmpty);
    expect(t.porTelefono, ['04120000000']);
  });
}
