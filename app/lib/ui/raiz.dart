import 'package:flutter/material.dart';

import '../dominio/alerta.dart';
import 'alarma.dart';
import 'ayuda.dart';
import 'controlador.dart';
import 'reposo.dart';

/// La casa no navega: muestra una sola pantalla según el estado de la alerta.
/// Así la persona nunca se pierde en un menú.
class Raiz extends StatelessWidget {
  const Raiz({super.key, required this.c});

  final Controlador c;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        final alerta = c.alerta;
        return switch (alerta?.estado) {
          EstadoAlerta.pendiente => Alarma(c: c, alerta: alerta!),
          EstadoAlerta.escalada => Ayuda(c: c, alerta: alerta!),
          _ => Reposo(c: c),
        };
      },
    );
  }
}
