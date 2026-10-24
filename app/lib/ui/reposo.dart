import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../dominio/tipos.dart';
import '../oido/oido.dart';
import '../tema.dart';
import 'componentes/boton_grande.dart';
import 'componentes/capsula.dart';
import 'configurar.dart';
import 'leer_recipe.dart';
import 'controlador.dart';

const _dias = [
  'Lunes',
  'Martes',
  'Miércoles',
  'Jueves',
  'Viernes',
  'Sábado',
  'Domingo',
];
const _meses = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

/// El teléfono acostado como reloj de mesa. A la izquierda la hora, grande y tenue sobre negro
/// (gasta poco y no calienta), y abajo las pastillas en chico y el botón para leer un récipe. A
/// la derecha, de arriba abajo, «Pedir ayuda»: lo único que hay que encontrar con prisa.
///
/// «Huele a gas» y «Me siento mal» ya no son botones: se dicen en voz alta (ver
/// Controlador._escucharPedido).
///
/// Toques largos de prueba:
/// - mantener el reloj simula una alarma de humo;
/// - mantener «Cuidando la casa» abre la configuración (la usa el familiar);
/// - mantener «Pastillas de hoy» recuerda ya la próxima pastilla.
class Reposo extends StatelessWidget {
  const Reposo({super.key, required this.c});

  final Controlador c;

  @override
  Widget build(BuildContext context) {
    final ahora = c.ahora;
    final hora = '${ahora.hour}:${ahora.minute.toString().padLeft(2, '0')}';
    final fecha =
        '${_dias[ahora.weekday - 1]} ${ahora.day} de ${_meses[ahora.month - 1]}';

    return Scaffold(
      backgroundColor: Colores.noche,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onLongPress: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => Configurar(casa: c.casa),
                          ),
                        ),
                        child: _Estado(escuchando: c.escuchandoVoz),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onLongPress: () => c.oirEvento(TipoEvento.alarma),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Flexible(
                              child: FittedBox(
                                child: Text(
                                  hora,
                                  style: const TextStyle(
                                    fontSize: 116,
                                    height: 1,
                                    letterSpacing: -3,
                                    color: Colores.relojTenue,
                                  ),
                                ),
                              ),
                            ),
                            Text(
                              fecha,
                              style: const TextStyle(
                                fontSize: 24,
                                color: Colores.textoTenue,
                              ),
                            ),
                            // Solo en debug: lo que oye el teléfono, para probar el modelo.
                            if (kDebugMode)
                              Text(
                                _diagnostico(c.ultimaEscucha),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colores.textoTenue,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 72,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: _Pastillas(c: c)),
                          const SizedBox(width: 10),
                          const _LeerRecipe(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 22),
              SizedBox(
                width: 300,
                child: BotonGrande(
                  texto: 'Pedir ayuda',
                  alto: double.infinity,
                  tamano: 40,
                  fondo: Colores.rojo,
                  color: Colors.white,
                  alTocar: () => c.pedirAyuda(TipoEvento.panico),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Las pastillas en una línea: la que le toca, o la próxima. Si le toca, tocar la tarjeta abre el
/// recordatorio grande, con «Ya la tomé».
class _Pastillas extends StatelessWidget {
  const _Pastillas({required this.c});

  final Controlador c;

  @override
  Widget build(BuildContext context) {
    final ahora = c.ahora;
    final toca = c.pastillaQueToca;
    final proxima = toca ?? c.plan.siguientePendiente(ahora);
    final String linea;
    if (toca != null) {
      linea = 'Le toca: ${toca.horaTexto} · ${toca.nombre}';
    } else if (proxima != null) {
      linea = 'Próxima: ${proxima.horaTexto} · ${proxima.nombre}';
    } else {
      linea = 'Ya tomó las de hoy';
    }

    return Material(
      color: toca != null ? const Color(0xFF1F3A2A) : const Color(0xFF161618),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: toca != null ? c.recordarAhora : null,
        onLongPress: c.recordarAhora,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              if (proxima != null)
                Capsula(colores: proxima.colores, ancho: 40, alto: 18)
              else
                const Icon(
                  Icons.check_rounded,
                  color: Colores.verdePunto,
                  size: 26,
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pastillas de hoy',
                      style: TextStyle(fontSize: 14, color: Colores.textoTenue),
                    ),
                    Text(
                      linea,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: toca != null ? Colors.white : Colores.textoClaro,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// El botón chico para leer un récipe o un informe médico con la cámara.
class _LeerRecipe extends StatelessWidget {
  const _LeerRecipe();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: OutlinedButton.icon(
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: (_) => const LeerRecipe())),
        icon: const Icon(Icons.document_scanner_rounded, size: 26),
        label: const Text('Leer récipe', textAlign: TextAlign.center),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colores.textoClaro,
          side: const BorderSide(color: Colores.nocheBorde, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: const TextStyle(
            fontFamily: fuente,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            height: 1.1,
          ),
        ),
      ),
    );
  }
}

class _Estado extends StatelessWidget {
  const _Estado({required this.escuchando});

  /// True mientras el reconocimiento de voz escucha lo que dijo la persona.
  final bool escuchando;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colores.verdeFondo,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (escuchando)
            const Icon(Icons.mic_rounded, size: 18, color: Colores.verdePunto)
          else
            const CircleAvatar(radius: 5, backgroundColor: Colores.verdePunto),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              escuchando ? 'Le escucho…' : 'Cuidando la casa',
              style: const TextStyle(fontSize: 16, color: Colores.verdeClaro),
            ),
          ),
        ],
      ),
    );
  }
}

String _diagnostico(Escucha? e) {
  if (e == null) return 'Oído: esperando el micrófono…';
  final top = e.top
      .map((c) => '${c.nombre} ${(c.puntaje * 100).round()}%')
      .join(' · ');
  return '${e.db.round()} dB (fondo ${e.fondo.round()})${e.compuerta ? ' · compuerta abierta' : ''} · $top';
}
