import 'package:casa/dominio/rutina.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DateTime a(int h, [int m = 0]) => DateTime(2026, 10, 24, h, m);

  test(
    'el primer sonido del día se dice así, y después cada hábito por franja',
    () {
      final r = Rutina();
      expect(
        r.oir('Door', a(7, 12)).single.descripcion,
        'Primer sonido del día: una puerta',
      );
      expect(
        r.oir('Microwave oven', a(9, 5)).single.descripcion,
        'Oímos la cocina',
      );
      // La misma cocina en la misma mañana no se repite.
      expect(r.oir('Dishes, pots, and pans', a(10)), isEmpty);
      // En la tarde, sí.
      expect(
        r.oir('Cutlery, silverware', a(13)).single.descripcion,
        'Oímos la cocina',
      );
    },
  );

  test('lo que no es rutina no se anota', () {
    expect(Rutina().oir('Glass', a(9)), isEmpty);
  });

  test('de día, 3 horas sin sonido es un día distinto, y se avisa una vez', () {
    final r = Rutina()..oir('Door', a(9));
    expect(r.revisar(a(11, 59)), isNull);
    final silencio = r.revisar(a(12));
    expect(silencio?.descripcion, 'No se oye movimiento en la casa');
    expect(silencio?.distinto, contains('desde las 9:00'));
    expect(r.revisar(a(12, 30)), isNull);
    // Vuelve a sonar algo: el reloj del silencio empieza de nuevo.
    r.oir('Water tap, faucet', a(13));
    expect(r.revisar(a(15, 59)), isNull);
    expect(r.revisar(a(16)), isNotNull);
  });

  test('de noche el silencio es normal', () {
    final r = Rutina()..oir('Door', a(17));
    expect(r.revisar(a(21, 30)), isNull);
  });

  test('si la app recién empieza a oír, no culpa al silencio de antes', () {
    final r = Rutina();
    expect(r.revisar(a(19)), isNull);
    expect(r.revisar(a(20, 59)), isNull);
  });

  test('un día nuevo empieza de cero', () {
    final r = Rutina()..oir('Door', a(9));
    expect(
      r.oir('Door', DateTime(2026, 10, 25, 7)).single.descripcion,
      'Primer sonido del día: una puerta',
    );
  });
}
