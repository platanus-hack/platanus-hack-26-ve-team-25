import 'package:flutter/material.dart';

import '../dominio/pastillas.dart';
import '../tema.dart';
import 'componentes/boton_grande.dart';
import 'componentes/capsula.dart';
import 'controlador.dart';

/// «Es hora de la losartán»: verde y tranquila. La pastilla se dibuja con sus colores para
/// reconocerla sin leer, y «Ya la tomé» es un toque grande: aquí no hay riesgo en un toque
/// por reflejo, como sí lo hay al apagar una alarma.
///
/// Por hacer: la foto de la caja, que vendrá del récipe leído por foto (OCR).
class HoraPastilla extends StatelessWidget {
  const HoraPastilla({super.key, required this.c, required this.pastilla});

  final Controlador c;
  final Pastilla pastilla;

  @override
  Widget build(BuildContext context) {
    final saludo = switch (c.ahora.hour) {
      < 12 => 'Buenos días',
      < 19 => 'Buenas tardes',
      _ => 'Buenas noches',
    };

    return Scaffold(
      backgroundColor: Colores.verde,
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
                        '${pastilla.horaTexto} · $saludo, ${c.casa.nombre}',
                        style: const TextStyle(
                          fontSize: 20,
                          color: Color(0xFFD7EBDD),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Es hora de la ${pastilla.nombre.toLowerCase()}',
                        style: const TextStyle(
                          fontSize: 48,
                          height: 1.05,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Capsula(
                            colores: pastilla.colores,
                            ancho: 96,
                            alto: 40,
                          ),
                          const SizedBox(width: 18),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pastilla.indicacion,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  pastilla.dosis,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    color: Color(0xFFD7EBDD),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 28),
              SizedBox(
                width: 300,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    BotonGrande(
                      texto: 'Ya la tomé',
                      icono: Icons.check_rounded,
                      alto: 180,
                      tamano: 38,
                      fondo: Colors.white,
                      color: Colores.verde,
                      alTocar: () => c.yaLaTome(pastilla),
                    ),
                    const SizedBox(height: 14),
                    BotonGrande(
                      texto: 'Recuérdame en 10 min',
                      alto: 64,
                      tamano: 21,
                      fondo: Colors.transparent,
                      color: Colors.white,
                      borde: const Color(0xFF8FC3A1),
                      alTocar: () => c.recordarLuego(pastilla),
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
