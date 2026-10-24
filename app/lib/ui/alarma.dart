import 'package:flutter/material.dart';

import '../dominio/alerta.dart';
import '../dominio/comandos.dart';
import '../tema.dart';
import 'componentes/boton_grande.dart';
import 'componentes/deslizador.dart';
import 'controlador.dart';

/// «¿Está bien?»: la casa pregunta antes de avisar. Nunca dice «ALERTA»: pregunta.
/// A la izquierda qué oyó y cuánto falta; a la derecha los dos controles grandes. Si nadie
/// responde a tiempo, la alerta escala sola.
///
/// Mientras se ve, suena el tono de 520 Hz y vibra (Sirena.kt): lo prende y lo apaga el
/// controlador, no la pantalla.
class Alarma extends StatefulWidget {
  const Alarma({super.key, required this.c, required this.alerta});

  final Controlador c;
  final Alerta alerta;

  @override
  State<Alarma> createState() => _AlarmaState();
}

class _AlarmaState extends State<Alarma> with SingleTickerProviderStateMixin {
  // El fondo late despacio, sin destellos fuertes.
  late final AnimationController _latido = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _latido.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final alerta = widget.alerta;
    final restante = alerta.restante(c.ahora);
    final total = alerta.venceEn.difference(alerta.creada);
    final segundos = restante.inSeconds;
    final cuenta =
        '${segundos ~/ 60}:${(segundos % 60).toString().padLeft(2, '0')}';
    final contacto = c.primerContacto;
    final aviso = contacto.telefono.isNotEmpty
        ? 'Si no responde, llamamos a ${contacto.nombre}'
        : 'Si no responde, avisamos a su familia';

    return AnimatedBuilder(
      animation: _latido,
      builder: (context, child) => Scaffold(
        backgroundColor: Color.lerp(
          Colores.amarillo,
          Colores.amarilloClaro,
          _latido.value,
        ),
        body: child,
      ),
      child: SafeArea(
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
                        '¿Está bien, ${c.casa.nombre}?',
                        style: const TextStyle(
                          fontSize: 44,
                          height: 1.05,
                          fontWeight: FontWeight.w700,
                          color: Colores.tinta,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        alerta.motivo.frase,
                        style: const TextStyle(
                          fontSize: 22,
                          color: Colores.tinta,
                        ),
                      ),
                      // Para quien está lejos del teléfono o en el suelo.
                      const Text(
                        'O diga «$nombreDeLaCasa, estoy bien»',
                        style: TextStyle(fontSize: 20, color: Colores.tinta),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          SizedBox(
                            width: 124,
                            height: 124,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                CircularProgressIndicator(
                                  value: total.inMilliseconds == 0
                                      ? 0
                                      : restante.inMilliseconds /
                                            total.inMilliseconds,
                                  strokeWidth: 12,
                                  color: Colores.tinta,
                                  backgroundColor: Colores.tinta.withValues(
                                    alpha: 0.15,
                                  ),
                                ),
                                Center(
                                  child: Text(
                                    cuenta,
                                    style: const TextStyle(
                                      fontSize: 38,
                                      fontWeight: FontWeight.w700,
                                      color: Colores.tinta,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 18),
                          Flexible(
                            child: Text(
                              aviso,
                              style: const TextStyle(
                                fontSize: 20,
                                height: 1.3,
                                color: Colores.tinta,
                              ),
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
                width: 380,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // «Estoy bien» se desliza, no se toca: así no se apaga por reflejo.
                    // «Necesito ayuda» sí es un toque: pedir ayuda tiene que ser fácil.
                    Deslizador(
                      texto: 'Deslice si está bien',
                      alto: 112,
                      fondo: Colores.verde,
                      boton: Colors.white,
                      color: Colors.white,
                      alCompletar: c.estoyBien,
                    ),
                    const SizedBox(height: 18),
                    BotonGrande(
                      texto: 'Necesito ayuda',
                      alto: 100,
                      tamano: 32,
                      fondo: Colores.rojo,
                      color: Colors.white,
                      alTocar: c.necesitoAyuda,
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
