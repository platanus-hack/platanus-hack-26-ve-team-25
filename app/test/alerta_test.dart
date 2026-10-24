import 'package:casa/dominio/alerta.dart';
import 'package:casa/dominio/tipos.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final t0 = DateTime(2026, 10, 24, 14, 5);
  const espera = Duration(seconds: 60);
  Alerta nueva() => Alerta.preguntar(TipoEvento.alarma, t0, espera: espera);

  group('pendiente', () {
    test('cuenta los segundos que faltan', () {
      expect(
        nueva().restante(t0.add(const Duration(seconds: 13))),
        const Duration(seconds: 47),
      );
    });

    test('no escala antes de vencer', () {
      expect(
        nueva().revisar(t0.add(const Duration(seconds: 59))).estado,
        EstadoAlerta.pendiente,
      );
    });

    test('escala sola al vencer sin respuesta', () {
      final a = nueva().revisar(t0.add(espera));
      expect(a.estado, EstadoAlerta.escalada);
      expect(a.escaladaEn, t0.add(espera));
      expect(a.restante(t0.add(espera)), Duration.zero);
    });

    test('«Estoy bien» la cancela', () {
      final a = nueva().cancelar(t0.add(const Duration(seconds: 8)));
      expect(a.estado, EstadoAlerta.cancelada);
      expect(a.abierta, isFalse);
    });

    test('«Necesito ayuda» la escala sin esperar', () {
      expect(
        nueva().escalar(t0.add(const Duration(seconds: 3))).estado,
        EstadoAlerta.escalada,
      );
    });
  });

  group('transiciones que no valen', () {
    test(
      'una alerta cancelada no escala aunque el reloj la revise después',
      () {
        final a = nueva()
            .cancelar(t0)
            .revisar(t0.add(const Duration(minutes: 5)));
        expect(a.estado, EstadoAlerta.cancelada);
      },
    );

    test('una alerta escalada ya no se puede cancelar: solo atender', () {
      final escalada = nueva().escalar(t0);
      expect(escalada.cancelar(t0).estado, EstadoAlerta.escalada);
      final atendida = escalada.atender(t0, 'María');
      expect(atendida.estado, EstadoAlerta.atendida);
      expect(atendida.atendidaPor, 'María');
    });

    test('escalar dos veces no cambia la hora del primer aviso', () {
      final una = nueva().escalar(t0.add(const Duration(seconds: 5)));
      final dos = una.escalar(t0.add(const Duration(seconds: 30)));
      expect(dos.escaladaEn, t0.add(const Duration(seconds: 5)));
    });

    test('una pendiente no se puede atender', () {
      expect(nueva().atender(t0, 'María').estado, EstadoAlerta.pendiente);
    });
  });

  test('el pánico nace escalado, sin cuenta regresiva', () {
    final a = Alerta.urgente(TipoEvento.panico, t0);
    expect(a.estado, EstadoAlerta.escalada);
    expect(a.restante(t0), Duration.zero);
  });
}
