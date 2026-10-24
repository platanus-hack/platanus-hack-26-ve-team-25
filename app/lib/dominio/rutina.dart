/// La rutina de la casa: lo de siempre que suena, para que la familia vea «Su día» sin que nadie
/// toque nada, y para notar lo que falta. Una caída no siempre suena: si de día la casa se queda
/// callada mucho rato, eso también es un aviso.
///
/// Solo sale una etiqueta por hábito y por franja del día («Oímos la cocina» en la mañana), nunca
/// el audio. La web de la familia ya pinta estos eventos en «Su día», y los que traen `distinto`
/// como «DÍA DISTINTO» (web/src/lib/familia/estado.ts).
enum Habito {
  cocina('la cocina', 'Oímos la cocina'),
  agua('agua', 'Oímos agua corriendo'),
  puerta('una puerta', 'Oímos la puerta'),
  bano('el baño', 'Oímos el baño'),
  tv('la TV', 'TV o radio'),
  voces('voces', 'Oímos voces');

  const Habito(this.primero, this.frase);

  /// Cómo se dice en «Primer sonido del día: …».
  final String primero;
  final String frase;
}

/// El hábito de cada clase de YAMNet que cuenta como rutina (las de sonidos.dart).
Habito? habitoDeClase(String clase) => switch (clase) {
  'Dishes, pots, and pans' ||
  'Cutlery, silverware' ||
  'Microwave oven' => Habito.cocina,
  'Water tap, faucet' || 'Sink (filling or washing)' => Habito.agua,
  'Door' || 'Doorbell' || 'Knock' => Habito.puerta,
  'Toilet flush' => Habito.bano,
  'Television' || 'Radio' => Habito.tv,
  'Speech' => Habito.voces,
  _ => null,
};

class EventoDeRutina {
  const EventoDeRutina(this.hora, this.descripcion, {this.distinto});

  final DateTime hora;
  final String descripcion;

  /// Si salió de lo de siempre, por qué. La familia lo ve como un aviso «para saber».
  final String? distinto;
}

class Rutina {
  Rutina({
    this.silencioLargo = const Duration(hours: 3),
    this.despierta = 8,
    this.duerme = 21,
  });

  /// Cuánto silencio de día ya no es normal.
  final Duration silencioLargo;

  /// Entre estas horas se espera que algo suene; de noche el silencio es normal.
  final int despierta;
  final int duerme;

  DateTime? _dia;
  DateTime? _empezo;
  DateTime? _ultimoSonido;
  bool _avisoElSilencio = false;
  final _anotados = <(int, Habito)>{};

  /// Oyó una clase de rutina. Devuelve lo que hay que anotar: nada si ese hábito ya se anotó en
  /// esta franja, para no llenar «Su día» con la misma línea.
  List<EventoDeRutina> oir(String clase, DateTime ahora) {
    final habito = habitoDeClase(clase);
    if (habito == null) return const [];
    _nuevoDia(ahora);
    final primero = _ultimoSonido == null || _anotados.isEmpty;
    _ultimoSonido = ahora;
    _avisoElSilencio = false;
    if (!_anotados.add((_franja(ahora), habito))) return const [];
    return [
      EventoDeRutina(
        ahora,
        primero ? 'Primer sonido del día: ${habito.primero}' : habito.frase,
      ),
    ];
  }

  /// Se llama con cada tic. Si de día no suena nada desde hace [silencioLargo], avisa una vez.
  EventoDeRutina? revisar(DateTime ahora) {
    _nuevoDia(ahora);
    if (ahora.hour < despierta || ahora.hour >= duerme) return null;
    // Si no ha sonado nada hoy, el silencio se cuenta desde que la casa despierta, o desde que la
    // app empezó a oír, lo que sea más tarde: antes de eso no se sabe.
    final despertar = DateTime(ahora.year, ahora.month, ahora.day, despierta);
    final empezo = _empezo!;
    final desde =
        _ultimoSonido ?? (empezo.isAfter(despertar) ? empezo : despertar);
    if (_avisoElSilencio || ahora.difference(desde) < silencioLargo) {
      return null;
    }
    _avisoElSilencio = true;
    final hhmm = '${desde.hour}:${desde.minute.toString().padLeft(2, '0')}';
    return EventoDeRutina(
      ahora,
      'No se oye movimiento en la casa',
      distinto:
          'No suena nada desde las $hhmm, y a esta hora siempre hay algo.',
    );
  }

  void _nuevoDia(DateTime ahora) {
    _empezo ??= ahora;
    final dia = DateTime(ahora.year, ahora.month, ahora.day);
    if (_dia == dia) return;
    _dia = dia;
    _anotados.clear();
    _ultimoSonido = null;
    _avisoElSilencio = false;
  }

  // Mañana, tarde y noche.
  static int _franja(DateTime t) => t.hour < 12 ? 0 : (t.hour < 18 ? 1 : 2);
}
