import 'package:flutter/material.dart';

/// Una pastilla dibujada con sus colores, para reconocerla sin leer el nombre.
class Capsula extends StatelessWidget {
  const Capsula({
    super.key,
    required this.colores,
    this.ancho = 52,
    this.alto = 24,
  });

  final List<int> colores;
  final double ancho;
  final double alto;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(alto),
      child: SizedBox(
        width: ancho,
        height: alto,
        // Sin stretch, las franjas de color quedan de alto 0 y la cápsula no se ve.
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final c in colores)
              Expanded(child: ColoredBox(color: Color(c))),
          ],
        ),
      ),
    );
  }
}
