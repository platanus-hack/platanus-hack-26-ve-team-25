// El contrato compartido con la web de la familia (web/src/lib/familia/tipos.ts).
// Si cambia aquí, cambia allá en el mismo commit. Ver docs/pantallas.md.

enum Canal { telegram, llamada }

class Contacto {
  const Contacto({
    required this.nombre,
    required this.relacion,
    required this.canal,
    required this.orden,
    this.donde = '',
    this.telefono = '',
  });

  final String nombre;
  final String relacion;
  final Canal canal;
  final int orden;
  final String donde;

  /// Número para la llamada de emergencia. Vacío si no se configuró.
  final String telefono;
}

class Casa {
  const Casa({
    required this.id,
    required this.nombre,
    required this.condiciones,
    required this.contactos,
  });

  final String id;
  final String nombre;
  final List<String> condiciones;
  final List<Contacto> contactos;
}

/// Lo que oyó o sintió el teléfono, o lo que tocó la persona.
enum TipoEvento {
  alarma('Oímos una alarma de humo'),
  vidrio('Oímos un vidrio que se rompe'),
  golpe('Oímos un golpe'),
  grito('Oímos un grito'),
  rutina('Rutina'),
  apagon('Se fue la luz'),
  panico('Pidió ayuda'),
  hueleGas('Dice que huele a gas'),
  meSientoMal('Dice que se siente mal'),
  estoyBien('Dijo que está bien hoy');

  const TipoEvento(this.frase);

  /// Cómo se le cuenta a la persona en la pantalla de la casa.
  final String frase;
}

enum Nivel { rojo, amarillo, verde }
