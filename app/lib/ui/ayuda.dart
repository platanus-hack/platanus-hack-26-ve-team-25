import 'package:flutter/material.dart';

import '../dominio/alerta.dart';
import '../tema.dart';
import 'componentes/boton_grande.dart';
import 'controlador.dart';

/// Después de escalar. Solo dice lo que de verdad pasó: la casa llama al primer contacto.
/// No promete que «la ayuda viene en camino» ni muestra llamadas que todavía no existen.
///
/// Si la llamada de WhatsApp duró como para haber timbrado, la app vuelve aquí y pregunta si
/// pudieron hablar, porque Android no dice si la contestaron. Si nadie responde, llama por
/// teléfono.
class Ayuda extends StatelessWidget {
  const Ayuda({super.key, required this.c, required this.alerta});

  final Controlador c;
  final Alerta alerta;

  @override
  Widget build(BuildContext context) {
    final contacto = c.primerContacto;
    final conNumero = contacto.telefono.isNotEmpty;
    final pregunta = c.preguntaRestante;

    final String titulo;
    final String detalle;
    if (pregunta != null) {
      titulo = '¿Pudo hablar con ${contacto.nombre}?';
      detalle =
          'Si no, lo llamamos por teléfono en 0:${pregunta.inSeconds.toString().padLeft(2, '0')}.';
    } else if (conNumero) {
      titulo = 'Estamos llamando a ${contacto.nombre}';
      detalle = 'Si contesta, puede hablarle desde aquí.';
    } else {
      titulo = 'Pida ayuda a alguien cerca';
      detalle = 'Este teléfono todavía no tiene un número de emergencia.';
    }

    return Scaffold(
      backgroundColor: Colores.rojoOscuro,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 22, 28, 22),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: const TextStyle(
                          fontSize: 42,
                          height: 1.08,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        detalle,
                        style: const TextStyle(
                          fontSize: 22,
                          height: 1.35,
                          color: Colores.rojoTexto,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colores.rojoTarjeta,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.call_rounded,
                              size: 32,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 16),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${contacto.nombre}, ${contacto.relacion}',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  if (!conNumero)
                                    const Text(
                                      'Sin número',
                                      style: TextStyle(
                                        fontSize: 17,
                                        color: Colores.rojoTexto,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 28),
              SizedBox(
                width: 320,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (pregunta != null) ...[
                      BotonGrande(
                        texto: 'Sí, ya hablamos',
                        icono: Icons.check_rounded,
                        alto: 112,
                        tamano: 30,
                        fondo: Colors.white,
                        color: Colores.rojoOscuro,
                        alTocar: c.siHablamos,
                      ),
                      const SizedBox(height: 16),
                      BotonGrande(
                        texto: 'Llamar por teléfono ya',
                        alto: 72,
                        tamano: 21,
                        fondo: Colors.transparent,
                        color: Colors.white,
                        borde: const Color(0xFFF3B7B3),
                        alTocar: c.llamarPorTelefono,
                      ),
                    ] else ...[
                      if (conNumero) ...[
                        BotonGrande(
                          texto: 'Volver a llamar',
                          alto: 112,
                          tamano: 30,
                          fondo: Colors.white,
                          color: Colores.rojoOscuro,
                          alTocar: c.llamarPrimerContacto,
                        ),
                        const SizedBox(height: 16),
                      ],
                      BotonGrande(
                        texto: 'Fue sin querer, estoy bien',
                        alto: 72,
                        tamano: 21,
                        fondo: Colors.transparent,
                        color: Colors.white,
                        borde: const Color(0xFFF3B7B3),
                        alTocar: c.fueSinQuerer,
                      ),
                    ],
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
