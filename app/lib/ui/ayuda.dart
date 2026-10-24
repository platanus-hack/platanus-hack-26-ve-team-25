import 'package:flutter/material.dart';

import '../dominio/alerta.dart';
import '../tema.dart';
import 'componentes/boton_grande.dart';
import 'controlador.dart';

/// Después de escalar. Solo dice lo que de verdad pasó: la casa llama al primer contacto.
/// No promete que «la ayuda viene en camino» ni muestra llamadas que todavía no existen.
class Ayuda extends StatelessWidget {
  const Ayuda({super.key, required this.c, required this.alerta});

  final Controlador c;
  final Alerta alerta;

  @override
  Widget build(BuildContext context) {
    final contacto = c.primerContacto;
    final conNumero = contacto.telefono.isNotEmpty;
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
              Text(
                conNumero
                    ? 'Estamos llamando a ${contacto.nombre}'
                    : 'Pida ayuda a alguien cerca',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 42,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                conNumero
                    ? 'Si contesta, puede hablarle desde aquí.'
                    : 'Este teléfono todavía no tiene un número de emergencia.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  height: 1.35,
                  color: Colores.rojoTexto,
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      decoration: BoxDecoration(
                        color: Colores.rojoTarjeta,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.call_rounded,
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
                                  conNumero
                                      ? 'Llamada desde las $hora'
                                      : 'Sin número',
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
                    ),
                  ),
                ),
              ),
              if (conNumero) ...[
                BotonGrande(
                  texto: 'Volver a llamar',
                  icono: Icons.call_rounded,
                  alto: 112,
                  tamano: 32,
                  fondo: Colors.white,
                  color: Colores.rojoOscuro,
                  alTocar: c.llamarPrimerContacto,
                ),
                const SizedBox(height: 16),
              ],
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
