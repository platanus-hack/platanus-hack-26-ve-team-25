import 'package:flutter/material.dart';

import '../tema.dart';
import 'componentes/boton_grande.dart';
import 'controlador.dart';

/// «Lucero, llama a mi hijo»: 5 s para arrepentirse antes de llamar. Se cancela con el botón o
/// diciendo «no». Si no hay número configurado lo dice, y no promete una llamada que no saldrá.
class LlamadaPorVozPantalla extends StatelessWidget {
  const LlamadaPorVozPantalla({
    super.key,
    required this.c,
    required this.llamada,
  });

  final Controlador c;
  final LlamadaPorVoz llamada;

  @override
  Widget build(BuildContext context) {
    final conNumero = llamada.numero.isNotEmpty;
    final segundos = (c.porLlamarRestante.inMilliseconds / 1000).ceil();
    final titulo = conNumero
        ? 'Llamando a ${llamada.quien}'
        : 'No tengo el número de ${llamada.quien}';
    final detalle = conNumero
        ? 'En $segundos. Diga «no» para cancelar.'
        : 'Su familia lo puede agregar al configurar la casa.';

    return Scaffold(
      backgroundColor: llamada.emergencias ? Colores.rojoOscuro : Colores.verde,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 22, 28, 22),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 46,
                        height: 1.05,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      detalle,
                      style: const TextStyle(fontSize: 26, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 28),
              SizedBox(
                width: 300,
                child: BotonGrande(
                  texto: conNumero ? 'No llamar' : 'Volver',
                  alto: double.infinity,
                  tamano: 40,
                  fondo: Colors.white,
                  color: llamada.emergencias
                      ? Colores.rojoOscuro
                      : Colores.verde,
                  alTocar: c.noLlamar,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
