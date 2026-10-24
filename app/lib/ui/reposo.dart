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

/// El teléfono acostado como reloj de mesa. A la izquierda la hora, grande y tenue sobre negro
/// (gasta poco y no calienta), y abajo los botones para pedir ayuda, siempre visibles. A la
/// derecha, las pastillas del día.
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
                        child: const _Estado(),
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
                    Row(
                      children: [
                        Expanded(
                          child: BotonGrande(
                            texto: 'Pedir ayuda',
                            alto: 84,
                            tamano: 24,
                            fondo: Colores.rojo,
                            color: Colors.white,
                            alTocar: () => c.pedirAyuda(TipoEvento.panico),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _BotonPersona(
                            'Huele a gas',
                            alTocar: () => c.pedirAyuda(TipoEvento.hueleGas),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _BotonPersona(
                            'Me siento mal',
                            alTocar: () => c.pedirAyuda(TipoEvento.meSientoMal),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 22),
              SizedBox(width: 300, child: _Pastillas(c: c)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pastillas extends StatelessWidget {
  const _Pastillas({required this.c});

  final Controlador c;

  @override
  Widget build(BuildContext context) {
    final toca = c.pastillaQueToca;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161618),
        borderRadius: BorderRadius.circular(24),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onLongPress: c.recordarAhora,
              child: const Text(
                'Pastillas de hoy',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: Colores.textoClaro,
                ),
              ),
            ),
            const SizedBox(height: 10),
            for (final p in c.plan.pastillas)
              if (p == toca) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F3A2A),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Capsula(colores: p.colores),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${p.horaTexto} · ${p.nombre}',
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const Text(
                              'Le toca ahora',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colores.verdeClaro,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                BotonGrande(
                  texto: 'Ya la tomé',
                  icono: Icons.check_rounded,
                  alto: 72,
                  tamano: 24,
                  fondo: const Color(0xFF16A34A),
                  color: Colors.white,
                  alTocar: () => c.yaLaTome(p),
                ),
                const SizedBox(height: 6),
              ] else
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      Capsula(colores: p.colores, ancho: 40, alto: 18),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${p.horaTexto} · ${p.nombre}',
                          style: TextStyle(
                            fontSize: 17,
                            color: Colores.textoTenue,
                            decoration: c.plan.tomada(p)
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                      if (c.plan.tomada(p))
                        const Icon(
                          Icons.check_rounded,
                          color: Colores.verdePunto,
                          size: 22,
                        ),
                    ],
                  ),
                ),
          ],
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
              style: TextStyle(fontSize: 16, color: Colores.verdeClaro),
            ),
          ),
        ],
      ),
    );
  }
}

class _BotonPersona extends StatelessWidget {
  const _BotonPersona(this.texto, {required this.alTocar});

  final String texto;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    return BotonGrande(
      texto: texto,
      alto: 84,
      tamano: 19,
      fondo: Colores.nocheBoton,
      color: Colores.textoClaro,
      borde: Colores.nocheBorde,
      alTocar: alTocar,
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
