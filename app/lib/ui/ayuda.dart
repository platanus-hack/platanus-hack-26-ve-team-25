import 'package:flutter/material.dart';

import '../dominio/alerta.dart';
import '../dominio/tipos.dart';
import '../tema.dart';
import 'componentes/boton_grande.dart';
import 'controlador.dart';

/// Después de escalar: tranquiliza a la persona y le muestra a quién se avisó.
/// Por ahora el estado de cada contacto es simulado; después viene de Supabase y Telegram.
class Ayuda extends StatelessWidget {
  const Ayuda({super.key, required this.c, required this.alerta});

  final Controlador c;
  final Alerta alerta;

  @override
  Widget build(BuildContext context) {
    final contactos = [...c.casa.contactos]
      ..sort((a, b) => a.orden.compareTo(b.orden));
    final escalada = alerta.escaladaEn ?? alerta.creada;
    final hora =
        '${escalada.hour}:${escalada.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: Colores.rojoOscuro,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Ya avisamos a su familia',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 42,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Quédese tranquila. La ayuda viene en camino.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  height: 1.35,
                  color: Colores.rojoTexto,
                ),
              ),
              // Se desplaza si no cabe: muchos adultos mayores usan la letra del sistema grande.
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      children: [
                        for (final (i, contacto) in contactos.indexed) ...[
                          if (i > 0) const SizedBox(height: 14),
                          _Contacto(
                            contacto: contacto,
                            // Simulado: el primero ya recibió el aviso y al siguiente lo estamos llamando.
                            estado: i == 0
                                ? 'Recibió el aviso · $hora'
                                : 'Llamando…',
                            listo: i == 0,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              BotonGrande(
                texto: 'Llamar a ${contactos.first.nombre}',
                alto: 112,
                tamano: 32,
                fondo: Colors.white,
                color: Colores.rojoOscuro,
                alTocar: () {},
              ),
              const SizedBox(height: 16),
              BotonGrande(
                texto: 'Fue sin querer, estoy bien',
                alto: 64,
                tamano: 22,
                fondo: Colors.transparent,
                color: Colors.white,
                borde: const Color(0xFFF3B7B3),
                alTocar: c.fueSinQuerer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Contacto extends StatelessWidget {
  const _Contacto({
    required this.contacto,
    required this.estado,
    required this.listo,
  });

  final Contacto contacto;
  final String estado;
  final bool listo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colores.rojoTarjeta,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Icon(
            listo ? Icons.check_rounded : Icons.call_rounded,
            size: 34,
            color: Colors.white,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${contacto.nombre}, ${contacto.relacion}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  estado,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colores.rojoTexto,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
