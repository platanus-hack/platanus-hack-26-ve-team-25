import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../dominio/tipos.dart';
import '../oido/oido.dart';
import '../tema.dart';
import 'componentes/boton_grande.dart';
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

/// Casi siempre la casa está así: un reloj grande y tenue sobre negro, que gasta poco y no
/// calienta, y abajo los botones con los que la persona avisa.
///
/// Mientras no exista el oído, dos toques largos sirven para probar:
/// - mantener el reloj simula una alarma de humo;
/// - mantener «Cuidando la casa» abre la configuración (la usa el familiar).
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
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
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
                    children: [
                      FittedBox(
                        child: Text(
                          hora,
                          style: const TextStyle(
                            fontSize: 112,
                            height: 1,
                            letterSpacing: -2,
                            color: Colores.relojTenue,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        fecha,
                        style: const TextStyle(
                          fontSize: 26,
                          color: Colores.textoTenue,
                        ),
                      ),
                      // Solo en debug: lo que oye el teléfono, para probar el modelo.
                      if (kDebugMode) ...[
                        const SizedBox(height: 16),
                        Text(
                          _diagnostico(c.ultimaEscucha),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colores.textoTenue,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              BotonGrande(
                texto: 'Pedir ayuda',
                icono: Icons.warning_amber_rounded,
                alto: 128,
                tamano: 34,
                fondo: Colores.rojo,
                color: Colors.white,
                alTocar: () => c.pedirAyuda(TipoEvento.panico),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _BotonPersona(
                      'Huele a gas',
                      alTocar: () => c.pedirAyuda(TipoEvento.hueleGas),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _BotonPersona(
                      'Me siento mal',
                      alTocar: () => c.pedirAyuda(TipoEvento.meSientoMal),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _BotonPersona(
                      'Estoy bien hoy',
                      verde: true,
                      alTocar: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Gracias. Que tenga buen día.',
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              style: TextStyle(fontSize: 18, color: Colores.verdeClaro),
            ),
          ),
        ],
      ),
    );
  }
}

class _BotonPersona extends StatelessWidget {
  const _BotonPersona(this.texto, {required this.alTocar, this.verde = false});

  final String texto;
  final VoidCallback alTocar;
  final bool verde;

  @override
  Widget build(BuildContext context) {
    return BotonGrande(
      texto: texto,
      alto: 104,
      tamano: 20,
      fondo: verde ? const Color(0xFF142019) : Colores.nocheBoton,
      color: verde ? Colores.verdeClaro : Colores.textoClaro,
      borde: verde ? const Color(0xFF2F5A3F) : Colores.nocheBorde,
      alTocar: alTocar,
    );
  }
}

String _diagnostico(Escucha? e) {
  if (e == null) return 'Oído: esperando el micrófono…';
  final top = e.top
      .map((c) => '${c.nombre} ${(c.puntaje * 100).round()}%')
      .join(' · ');
  return '${e.db.round()} dB (fondo ${e.fondo.round()})${e.compuerta ? ' · compuerta abierta' : ''}\n$top';
}
