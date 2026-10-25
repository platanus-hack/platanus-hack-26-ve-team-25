import 'respuesta.dart';
import 'tipos.dart';

/// El banco de frases con que una persona mayor pide ayuda en voz alta, sin tocar nada.
///
/// Es la gramática de Vosk: el reconocedor solo puede contestar con estas palabras, así que la
/// lista dice a la vez qué se entiende y qué se busca. Van con tildes, como en el vocabulario del
/// modelo; al comparar se quitan. Está pensada en el español de Venezuela («malita», «la
/// bombona») y en cómo habla alguien asustado: frases cortas, repetidas, a veces incompletas.
///
/// No entran palabras sueltas que aparecen en una conversación normal («médico», «fuego»,
/// «bombona» sola): una frase del banco abre «¿Está bien?», y eso tiene que ser raro.
///
/// El orden importa: si una frase dice dos cosas, gana la de arriba.
const bancoDePedidos = <TipoEvento, List<String>>{
  TipoEvento.hueleGas: [
    'huele a gas',
    'me huele a gas',
    'olor a gas',
    'hay olor a gas',
    'hay gas',
    'se sale el gas',
    'se está saliendo el gas',
    'se salió el gas',
    'escape de gas',
    'fuga de gas',
    'se está botando el gas',
    'la bombona se está botando',
  ],
  TipoEvento.meSientoMal: [
    'me siento mal',
    'me siento muy mal',
    'me siento malita',
    'me siento malito',
    'estoy mal',
    'estoy muy mal',
    'estoy malita',
    'estoy malito',
    'me duele',
    'me duele mucho',
    'me duele el pecho',
    'me duele la cabeza',
    'me duele el brazo',
    'me caí',
    'me fui al suelo',
    'no me puedo levantar',
    'no me puedo parar',
    'no puedo levantarme',
    'no puedo pararme',
    'me mareo',
    'estoy mareada',
    'estoy mareado',
    'me voy a desmayar',
    'me desmayo',
    'no puedo respirar',
    'me falta el aire',
    'me ahogo',
    'me estoy ahogando',
    'me golpeé',
    'me pegué',
    'me corté',
    'me quemé',
    'no veo',
    'no siento el brazo',
    'no siento la pierna',
    'se me durmió el brazo',
  ],
  TipoEvento.panico: [
    'ayuda',
    'ayúdame',
    'ayúdenme',
    'auxilio',
    'socorro',
    'necesito ayuda',
    'por favor ayuda',
    'llamen a una ambulancia',
    'una ambulancia',
    'llamen a mi hijo',
    'llamen a mi hija',
    'llama a mi hijo',
    'llama a mi hija',
    'llamen a alguien',
    'me estoy muriendo',
    'me muero',
    'ay dios mío ayuda',
    // El fuego no tiene evento propio: es un pedido de ayuda, sin decir que huele a gas.
    'huele a quemado',
    'hay humo',
    'se está quemando',
    'se quema la casa',
    'hay fuego',
    'incendio',
  ],
};

/// Todas las frases, para la gramática de Vosk.
List<String> get todasLasFrases => [
  for (final frases in bancoDePedidos.values) ...frases,
];

/// Lo que pidió la persona en voz alta, o null si no dijo nada del banco. Recibe todas las
/// versiones que propone el reconocedor, de la más probable a la menos.
TipoEvento? pedidoPorVoz(List<String> versiones) {
  for (final version in versiones) {
    final texto = ' ${normalizar(version).join(' ')} ';
    for (final MapEntry(key: tipo, value: frases) in bancoDePedidos.entries) {
      if (frases.any((f) => texto.contains(' ${normalizar(f).join(' ')} '))) {
        return tipo;
      }
    }
  }
  return null;
}
