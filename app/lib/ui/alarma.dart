import 'package:flutter/material.dart';

import '../dominio/alerta.dart';
import '../tema.dart';
import 'componentes/boton_grande.dart';
import 'componentes/deslizador.dart';
import 'controlador.dart';

/// «¿Está bien?»: la casa pregunta antes de avisar. Nunca dice «ALERTA»: pregunta.
/// Solo dos controles grandes. Si nadie responde a tiempo, la alerta escala sola.
///
/// Por hacer: el tono de 520 Hz y la vibración. Ver docs/pantallas.md.
class Alarma extends StatefulWidget {
  const Alarma({super.key, required this.c, required this.alerta});

  final Controlador c;
  final Alerta alerta;

  @override
  State<Alarma> createState() => _AlarmaState();
}

class _AlarmaState extends State<Alarma> with SingleTickerProviderStateMixin {
  // El fondo late despacio, una vez por segundo y sin destellos fuertes.
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
    final primero = c.casa.contactos.first.nombre;

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
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '¿Está bien, ${c.casa.nombre}?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 46,
                  height: 1.05,
                  fontWeight: FontWeight.w700,
                  color: Colores.tinta,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                alerta.motivo.frase,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, color: Colores.tinta),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(
                          width: 168,
                          height: 168,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CircularProgressIndicator(
                                value: total.inMilliseconds == 0
                                    ? 0
                                    : restante.inMilliseconds /
                                          total.inMilliseconds,
                                strokeWidth: 14,
                                color: Colores.tinta,
                                backgroundColor: Colores.tinta.withValues(
                                  alpha: 0.15,
                                ),
                              ),
                              Center(
                                child: Text(
                                  cuenta,
                                  style: const TextStyle(
                                    fontSize: 52,
                                    fontWeight: FontWeight.w700,
                                    color: Colores.tinta,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Si no responde, le avisamos a $primero',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            color: Colores.tinta,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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
              const SizedBox(height: 16),
              BotonGrande(
                texto: 'Necesito ayuda',
                alto: 104,
                tamano: 32,
                fondo: Colores.rojo,
                color: Colors.white,
                alTocar: c.necesitoAyuda,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
