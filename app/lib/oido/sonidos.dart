import '../dominio/tipos.dart';

// De las 521 clases de YAMNet a lo que le importa a la familia. Los nombres son los de
// yamnet_class_map.csv. Es la misma tabla que web/src/lib/escucha/eventos.ts.

enum TipoSonido { alarma, vidrio, golpe, grito, tv, rutina }

const clasesYamnet = <String, TipoSonido>{
  'Smoke detector, smoke alarm': TipoSonido.alarma,
  'Fire alarm': TipoSonido.alarma,
  'Alarm': TipoSonido.alarma,
  'Glass': TipoSonido.vidrio,
  'Shatter': TipoSonido.vidrio,
  'Thump, thud': TipoSonido.golpe,
  'Bang': TipoSonido.golpe,
  'Slam': TipoSonido.golpe,
  'Screaming': TipoSonido.grito,
  'Shout': TipoSonido.grito,
  'Yell': TipoSonido.grito,
  'Crying, sobbing': TipoSonido.grito,
  // La voz de una persona mayor que pide ayuda suele ser un quejido, no un grito.
  'Wail, moan': TipoSonido.grito,
  'Television': TipoSonido.tv,
  'Radio': TipoSonido.tv,
  'Speech': TipoSonido.rutina,
  'Water tap, faucet': TipoSonido.rutina,
  'Sink (filling or washing)': TipoSonido.rutina,
  'Dishes, pots, and pans': TipoSonido.rutina,
  'Cutlery, silverware': TipoSonido.rutina,
  'Microwave oven': TipoSonido.rutina,
  'Toilet flush': TipoSonido.rutina,
  'Door': TipoSonido.rutina,
  'Doorbell': TipoSonido.rutina,
  'Knock': TipoSonido.rutina,
};

/// El evento de la casa que dispara cada sonido, o null si no es una alerta. La TV y la rutina
/// cuentan que la casa está viva, pero no preguntan «¿Está bien?».
TipoEvento? eventoDeSonido(TipoSonido tipo) => switch (tipo) {
  TipoSonido.alarma => TipoEvento.alarma,
  TipoSonido.vidrio => TipoEvento.vidrio,
  TipoSonido.golpe => TipoEvento.golpe,
  TipoSonido.grito => TipoEvento.grito,
  TipoSonido.tv || TipoSonido.rutina => null,
};

class Clase {
  const Clase(this.nombre, this.puntaje);

  final String nombre;
  final double puntaje;
}

class Sonido {
  const Sonido(this.tipo, this.clase);

  final TipoSonido tipo;
  final Clase clase;
}

/// Las clases ordenadas de mayor a menor puntaje.
List<Clase> ordenar(List<double> puntajes, List<String> etiquetas) {
  final clases = [
    for (var i = 0; i < puntajes.length && i < etiquetas.length; i++)
      Clase(etiquetas[i], puntajes[i]),
  ]..sort((a, b) => b.puntaje.compareTo(a.puntaje));
  return clases;
}

/// El sonido más probable de la ventana, si alguna clase que nos importa pasa el umbral.
Sonido? sonidoDe(List<Clase> clases, {double umbral = 0.3}) {
  Sonido? mejor;
  for (final c in clases) {
    final tipo = clasesYamnet[c.nombre];
    if (tipo != null &&
        c.puntaje >= umbral &&
        (mejor == null || c.puntaje > mejor.clase.puntaje)) {
      mejor = Sonido(tipo, c);
    }
  }
  return mejor;
}

/// Lee yamnet_class_map.csv (index,mid,display_name). Los nombres con coma vienen entre comillas.
List<String> leerEtiquetas(String csv) {
  final fila = RegExp(r'^\d+,[^,]+,(?:"([^"]*)"|(.*))$');
  return [
    for (final linea in csv.split('\n').skip(1))
      if (fila.firstMatch(linea.trim()) case final m?)
        m.group(1) ?? m.group(2)!,
  ];
}
