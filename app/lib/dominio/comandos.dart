import 'respuesta.dart';

/// El nombre de la casa: las órdenes de llamar empiezan con él, como «Ok Google». Así, si la TV
/// dice «llama a tu hijo» en una novela, la casa no llama. A futuro lo elige la familia al
/// configurar; por ahora es fijo. Ver docs/por-planificar.md, punto 8.
const nombreDeLaCasa = 'Lucero';

/// Lo que la persona puede ordenar en voz alta.
enum Orden {
  llamarEmergencias,
  llamarHijo,
  llamarVecino,

  /// «No» o «cancela» durante los 5 s antes de una llamada.
  cancelar,

  /// «Ya me la tomé», mientras suena el recordatorio de la pastilla.
  yaMeLaTome,
}

const _llamar = ['llama', 'llame', 'llamen', 'llamar'];

/// A quién se llama, después de «Lucero, llama…». Una sola palabra de la lista basta.
const _destinos = <Orden, List<String>>{
  Orden.llamarEmergencias: [
    'a emergencias',
    'a emergencia',
    'al nueve uno uno',
    'a una ambulancia',
    'a la ambulancia',
    'una ambulancia',
  ],
  Orden.llamarHijo: [
    'a mi hijo',
    'a mi hija',
    'a mi muchacho',
    'a mi muchacha',
  ],
  Orden.llamarVecino: [
    'al vecino',
    'a la vecina',
    'a mi vecino',
    'a mi vecina',
  ],
};

/// Para cancelar, la frase entera tiene que ser de estas palabras: «no», «no, no llames»,
/// «cancela». Así «no me puedo parar» no cancela la llamada al hijo.
const _palabrasDeCancelar = {
  'no',
  'cancela',
  'cancelar',
  'llames',
  'llamar',
  'para',
  'detente',
};
const _cancelar = [
  'no',
  'cancela',
  'cancelar',
  'no llames',
  'no llamar',
  'para',
  'detente',
];

const _yaMeLaTome = ['ya me la tomé', 'me la tomé', 'ya la tomé'];

/// Todas las palabras de las órdenes, para la gramática de Vosk.
List<String> get frasesDeOrdenes => [
  for (final destinos in _destinos.values)
    for (final d in destinos)
      for (final l in _llamar) '${nombreDeLaCasa.toLowerCase()} $l $d',
  ..._cancelar,
  ..._yaMeLaTome,
];

/// La orden que se dijo, o null. Las llamadas solo cuentan si antes se dijo el nombre de la
/// casa; «no» y «ya me la tomé», no, porque solo se escuchan en su momento (los 5 s antes de
/// una llamada y el recordatorio de la pastilla) y ahí no hay tiempo para nombres.
Orden? ordenPorVoz(List<String> versiones) {
  final nombre = normalizar(nombreDeLaCasa).join(' ');
  for (final version in versiones) {
    final texto = ' ${normalizar(version).join(' ')} ';
    bool dice(String f) => texto.contains(' ${normalizar(f).join(' ')} ');

    final enNombre = texto.indexOf(' $nombre ');
    if (enNombre >= 0) {
      // Lo que viene después del nombre: «Lucero, llama a mi hijo».
      final despues = ' ${texto.substring(enNombre + nombre.length + 2)}';
      for (final MapEntry(key: orden, value: destinos) in _destinos.entries) {
        for (final l in _llamar) {
          if (destinos.any(
            (d) => despues.contains(' $l ${normalizar(d).join(' ')} '),
          )) {
            return orden;
          }
        }
      }
    }
    if (_yaMeLaTome.any(dice)) return Orden.yaMeLaTome;
    final palabras = normalizar(version);
    if (palabras.isNotEmpty && palabras.every(_palabrasDeCancelar.contains)) {
      return Orden.cancelar;
    }
  }
  return null;
}
