import 'package:casa/dominio/respuesta.dart';
import 'package:casa/dominio/tipos.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('«sí», con o sin tilde, es sí', () {
    expect(interpretarRespuesta(['Sí']), Respuesta.si);
    expect(interpretarRespuesta(['si si']), Respuesta.si);
    expect(interpretarRespuesta(['Sí, ya hablamos']), Respuesta.si);
    expect(interpretarRespuesta(['ya hablé con él']), Respuesta.si);
  });

  test('«no» es no', () {
    expect(interpretarRespuesta(['No']), Respuesta.no);
    expect(interpretarRespuesta(['no, no contestó']), Respuesta.no);
    expect(interpretarRespuesta(['nadie']), Respuesta.no);
  });

  test('«no hablamos» es no aunque contenga «hablamos»', () {
    expect(interpretarRespuesta(['no hablamos']), Respuesta.no);
  });

  test('ante la duda no decide: sigue la cuenta regresiva', () {
    expect(interpretarRespuesta(['']), isNull);
    expect(interpretarRespuesta(['ayúdenme']), isNull);
    expect(interpretarRespuesta(['no sé si']), isNull);
    expect(interpretarRespuesta([]), isNull);
  });

  test('usa la primera versión del reconocedor que sea clara', () {
    expect(interpretarRespuesta(['eh', 'sí']), Respuesta.si);
  });

  group('lo que se pide en voz alta', () {
    test('el gas, con o sin «me»', () {
      expect(pedidoPorVoz(['Me huele a gas']), TipoEvento.hueleGas);
      expect(
        pedidoPorVoz(['hay olor a gas en la cocina']),
        TipoEvento.hueleGas,
      );
    });

    test('sentirse mal, caerse o no poder respirar', () {
      expect(pedidoPorVoz(['me siento mal']), TipoEvento.meSientoMal);
      expect(pedidoPorVoz(['ay, me caí']), TipoEvento.meSientoMal);
      expect(pedidoPorVoz(['no puedo respirar']), TipoEvento.meSientoMal);
    });

    test('«ayuda» y «auxilio» son pánico', () {
      expect(pedidoPorVoz(['¡Ayúdenme!']), TipoEvento.panico);
      expect(pedidoPorVoz(['auxilio']), TipoEvento.panico);
    });

    test('si dice dos cosas, gana el gas', () {
      expect(
        pedidoPorVoz(['me siento mal y huele a gas']),
        TipoEvento.hueleGas,
      );
    });

    test('una conversación cualquiera no pide nada', () {
      expect(pedidoPorVoz(['vamos a comer a las doce']), isNull);
      expect(pedidoPorVoz(['el gasto del mes']), isNull);
      expect(pedidoPorVoz([]), isNull);
    });

    test('mira todas las versiones del reconocedor', () {
      expect(
        pedidoPorVoz(['me siento más', 'me siento mal']),
        TipoEvento.meSientoMal,
      );
    });
  });
}
