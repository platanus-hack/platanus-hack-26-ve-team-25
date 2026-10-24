import 'package:casa/dominio/respuesta.dart';
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
}
