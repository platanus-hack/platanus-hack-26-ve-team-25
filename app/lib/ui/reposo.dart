import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../dominio/tipos.dart';
import '../oido/oido.dart';
import '../tema.dart';
import 'componentes/boton_grande.dart';
import 'componentes/capsula.dart';
import 'configurar.dart';
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

/// El teléfono acostado como reloj de mesa. A la izquierda la hora, grande, tenue sobre negro (gasta
/// poco y no calienta) y más arriba que abajo, y debajo la cinta de la próxima pastilla. A la
/// derecha, todo el alto, «Pedir ayuda»: lo único que hay que encontrar con prisa. Las fotos (la
/// factura de la farmacia) se leen desde la web de la familia, no desde aquí.
///
/// «Huele a gas» y «Me siento mal» ya no son botones: se dicen en voz alta (ver
/// Controlador._reconocerPedido y el banco de pedidos.dart).
///
/// Toques largos de prueba:
/// - mantener el reloj simula una alarma de humo;
/// - mantener «Cuidando la casa» abre la configuración (la usa el familiar);
/// - mantener «Pastillas de hoy» recuerda ya la próxima pastilla.
/// El alto de la cinta de la pastilla.
const _altoDeAbajo = 96.0;

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
                        child: const _Estado(),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onLongPress: () => c.oirEvento(TipoEvento.alarma),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Más espacio abajo que arriba: el reloj queda alto.
                            const Spacer(),
                            Flexible(
                              flex: 10,
                              child: FittedBox(
                                child: Text(
                                  hora,
                                  style: const TextStyle(
                                    fontSize: 160,
                                    height: 1,
                                    letterSpacing: -4,
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
                            const Spacer(flex: 2),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: _altoDeAbajo,
                      child: _Pastillas(c: c),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 22),
              SizedBox(
                width: 300,
                child: BotonGrande(
                  texto: c.textoDelBotonRojo,
                  alto: double.infinity,
                  tamano: 44,
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
/// recordatorio grande, con «Ya me la tomé».
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
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: [
              if (proxima != null)
                Capsula(colores: proxima.colores, ancho: 60, alto: 26)
              else
                const Icon(
                  Icons.check_rounded,
                  color: Colores.verdePunto,
                  size: 34,
                ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pastillas de hoy',
                      style: TextStyle(fontSize: 18, color: Colores.textoTenue),
                    ),
                    Text(
                      linea,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 27,
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

class _Estado extends StatelessWidget {
  const _Estado();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colores.verdeFondo,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 5, backgroundColor: Colores.verdePunto),
          SizedBox(width: 10),
          Flexible(
            child: Text(
              'Cuidando la casa',
              style: TextStyle(fontSize: 19, color: Colores.verdeClaro),
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
