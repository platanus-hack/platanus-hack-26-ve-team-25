import 'package:casa/dominio/comandos.dart';
import 'package:casa/dominio/pedidos.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('con el nombre de la casa, llama', () {
    expect(ordenPorVoz(['Lucero, llama a mi hijo']), Orden.llamarHijo);
    expect(
      ordenPorVoz(['lucero llama a emergencias']),
      Orden.llamarEmergencias,
    );
    expect(
      ordenPorVoz(['lucero llamen una ambulancia']),
      Orden.llamarEmergencias,
    );
    expect(ordenPorVoz(['ay lucero llama a la vecina']), Orden.llamarVecino);
  });

  test('sin el nombre de la casa, no llama: puede ser la TV', () {
    expect(ordenPorVoz(['llama a mi hijo']), isNull);
    expect(ordenPorVoz(['lucero mañana te llamo']), isNull);
  });

  test('«no» cancela solo si la frase entera es para cancelar', () {
    expect(ordenPorVoz(['no']), Orden.cancelar);
    expect(ordenPorVoz(['no no no llames']), Orden.cancelar);
    expect(ordenPorVoz(['cancela']), Orden.cancelar);
    expect(ordenPorVoz(['no me puedo parar']), isNull);
  });

  test('«ya me la tomé», con o sin tilde', () {
    expect(ordenPorVoz(['ya me la tomé']), Orden.yaMeLaTome);
    expect(ordenPorVoz(['ya me la tome']), Orden.yaMeLaTome);
  });

  test('cada orden de llamar de la gramática se reconoce', () {
    for (final f in frasesDeOrdenes.where((f) => f.startsWith('lucero'))) {
      expect(ordenPorVoz([f]), isNotNull, reason: f);
    }
  });

  test('sin el nombre, «llamen a mi hijo» sigue siendo un pedido de ayuda', () {
    expect(ordenPorVoz(['llamen a mi hijo']), isNull);
    expect(pedidoPorVoz(['llamen a mi hijo']), isNotNull);
  });
}
