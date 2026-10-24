import 'package:flutter/material.dart';

import '../dominio/pastillas.dart';
import '../dominio/tipos.dart';
import '../tema.dart';
import 'componentes/boton_grande.dart';
import 'componentes/capsula.dart';
import 'controlador.dart';

/// «Es hora de la losartán»: verde, tranquila y en toda la pantalla. La pastilla se dibuja con
/// sus colores para reconocerla sin leer. Solo se quita con «Ya me la tomé», que ocupa todo el
/// lado derecho: no hay «más tarde». Si pasan 2 horas sin tomarla, se va sola y queda como
/// olvidada (PlanDelDia.ventana): así nunca empuja a tomar dos dosis seguidas.
///
/// Abajo queda «Pedir ayuda», más chico: mientras la pantalla está, el reposo no se ve, y la
/// persona no puede quedarse sin forma de pedir ayuda.
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
                      const SizedBox(height: 22),
                      SizedBox(
                        width: 220,
                        child: BotonGrande(
                          texto: 'Pedir ayuda',
                          alto: 64,
                          tamano: 21,
                          fondo: Colores.rojo,
                          color: Colors.white,
                          alTocar: () => c.pedirAyuda(TipoEvento.panico),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 28),
              SizedBox(
                width: 340,
                child: BotonGrande(
                  texto: 'Ya me la tomé',
                  icono: Icons.check_rounded,
                  alto: double.infinity,
                  tamano: 44,
                  fondo: Colors.white,
                  color: Colores.verde,
                  alTocar: () => c.yaLaTome(pastilla),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
