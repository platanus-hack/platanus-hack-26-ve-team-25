import 'dart:typed_data';

import 'package:casa/datos/frases.dart';
import 'package:casa/oido/nivel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Vosk: solo cuentan las palabras con confianza', () {
    const json =
        '{"result": [{"word": "me", "conf": 0.95}, {"word": "caí", "conf": 0.9}], '
        '"text": "me caí"}';
    expect(textoConfiable(json), 'me caí');
    const dudoso =
        '{"result": [{"word": "ayuda", "conf": 0.31}], "text": "ayuda"}';
    expect(textoConfiable(dudoso), '');
  });

  test('Vosk: sin palabras o con [unk] no hay texto', () {
    expect(textoConfiable('{"text": ""}'), '');
    expect(
      textoConfiable(
        '{"result": [{"word": "[unk]", "conf": 1.0}], "text": "[unk]"}',
      ),
      '',
    );
  });

  test('el audio del anillo vuelve a PCM de 16 bits como llegó', () {
    final original = Uint8List.fromList([1, 0, 0xFF, 0xFF, 0x00, 0x40]);
    final muestras = LectorPcm16().leer(original);
    expect(pcm16DeMuestras(muestras), original);
  });

  test('a plena escala no se desborda', () {
    final pcm = pcm16DeMuestras(Float32List.fromList([1.5, -1.5]));
    expect(ByteData.sublistView(pcm).getInt16(0, Endian.little), 32767);
    expect(ByteData.sublistView(pcm).getInt16(2, Endian.little), -32768);
  });
}
