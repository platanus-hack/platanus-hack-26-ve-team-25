/// Lo que la persona contestó por voz a «¿Pudo hablar con Josuep?».
enum Respuesta { si, no }

const _si = [
  'si',
  'claro',
  'ya hablamos',
  'ya hable',
  'hablamos',
  'hable',
  'contesto',
  'me contesto',
  'ya',
];
const _no = [
  'no',
  'nadie',
  'no contesto',
  'no me contesto',
  'no hablamos',
  'no pude',
  'todavia no',
];

/// Interpreta lo que entendió el reconocimiento de voz. Ante la duda devuelve null, y entonces
/// sigue la cuenta regresiva: una mala lectura nunca puede impedir la llamada por teléfono.
///
/// Recibe todas las versiones que propone el reconocedor, de la más probable a la menos. Se
/// decide con la primera que tenga un «sí» o un «no» claro, y si una misma frase tiene los dos
/// («no sé si…»), no se decide.
Respuesta? interpretarRespuesta(List<String> versiones) {
  for (final version in versiones) {
    final palabras = _normalizar(version);
    if (palabras.isEmpty) continue;
    final texto = ' ${palabras.join(' ')} ';
    final dijoNo = _no.any((f) => texto.contains(' $f '));
    final dijoSi = _si.any((f) => texto.contains(' $f '));
    if (dijoNo && !dijoSi) return Respuesta.no;
    if (dijoSi && !dijoNo) return Respuesta.si;
    // Un «no» que contiene a «hablamos» («no hablamos») cuenta como no.
    if (dijoNo &&
        dijoSi &&
        _no.any((f) => f.contains(' ') && texto.contains(' $f '))) {
      return Respuesta.no;
    }
  }
  return null;
}

List<String> _normalizar(String texto) {
  const tildes = {'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u'};
  final limpio = texto
      .toLowerCase()
      .split('')
      .map((c) => tildes[c] ?? c)
      .join()
      .replaceAll(RegExp(r'[^a-zñ ]'), ' ');
  return limpio.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
}
