import 'package:flutter/material.dart';

import '../dominio/alerta.dart';
import 'alarma.dart';
import 'ayuda.dart';
import 'controlador.dart';
import 'hora_pastilla.dart';
import 'llamada_por_voz.dart';
import 'reposo.dart';

/// La casa no navega: muestra una sola pantalla según el estado. Así la persona nunca se
/// pierde en un menú. Una alerta siempre gana; después, una llamada pedida en voz alta, y
/// después el recordatorio de una pastilla.
class Raiz extends StatelessWidget {
  const Raiz({super.key, required this.c});

  final Controlador c;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        final alerta = c.alerta;
        final pastilla = c.recordatorio;
        final llamada = c.porLlamar;
        return switch (alerta?.estado) {
          EstadoAlerta.pendiente => Alarma(c: c, alerta: alerta!),
          EstadoAlerta.escalada => Ayuda(c: c, alerta: alerta!),
          _ when llamada != null => LlamadaPorVozPantalla(
            c: c,
            llamada: llamada,
          ),
          _ when pastilla != null => HoraPastilla(c: c, pastilla: pastilla),
          _ => Reposo(c: c),
        };
      },
    );
  }
}
