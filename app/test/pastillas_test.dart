import 'package:casa/dominio/pastillas.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const manana = Pastilla(
    id: 'a',
    nombre: 'Losartán',
    dosis: '50 mg',
    hora: 8,
    minuto: 0,
    colores: [0xFFFFFFFF],
  );
  const tarde = Pastilla(
    id: 'b',
    nombre: 'Metformina',
    dosis: '500 mg',
    hora: 14,
    minuto: 0,
    colores: [0xFFFFFFFF],
  );
  DateTime a(int h, [int m = 0]) => DateTime(2026, 10, 24, h, m);

  test('ordena las tomas por hora', () {
    expect(PlanDelDia([tarde, manana]).pastillas.map((p) => p.id), ['a', 'b']);
  });

  test('antes de la hora todavía no le toca', () {
    expect(PlanDelDia([manana]).estado(manana, a(7, 59)), EstadoToma.masTarde);
  });

  test('a la hora le toca y se recuerda en pantalla', () {
    final plan = PlanDelDia([manana, tarde]);
    expect(plan.leToca(a(8, 5)), manana);
    expect(plan.recordar(a(8, 5)), manana);
  });

  test('«Ya la tomé» la saca del recordatorio', () {
    final plan = PlanDelDia([manana])..marcarTomada(manana, a(8, 3));
    expect(plan.estado(manana, a(8, 4)), EstadoToma.tomada);
    expect(plan.recordar(a(8, 4)), isNull);
  });

  test('«Recuérdame en 10 min» la esconde 10 minutos y vuelve', () {
    final plan = PlanDelDia([manana])..posponer(manana, a(8, 0));
    expect(plan.recordar(a(8, 9)), isNull);
    expect(plan.recordar(a(8, 10)), manana);
  });

  test('pasadas dos horas sin tomarla queda olvidada', () {
    final plan = PlanDelDia([manana]);
    expect(plan.estado(manana, a(10, 0)), EstadoToma.olvidada);
    expect(plan.recordar(a(10, 0)), isNull);
  });

  test('la siguiente pendiente salta las tomadas y las olvidadas', () {
    final plan = PlanDelDia([manana, tarde]);
    expect(plan.siguientePendiente(a(11)), tarde);
    plan.marcarTomada(tarde, a(11));
    expect(plan.siguientePendiente(a(11)), isNull);
  });
}
