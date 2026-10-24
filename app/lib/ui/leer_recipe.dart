import 'package:flutter/material.dart';

import '../tema.dart';
import 'componentes/boton_grande.dart';

/// Aquí irá la cámara para leer un récipe o un informe médico: se toma la foto, se lee el texto
/// y la familia confirma las pastillas antes de guardarlas (docs/pendientes.md, P1). Mientras no
/// exista, la pantalla lo dice: no promete lo que la app no hace.
class LeerRecipe extends StatelessWidget {
  const LeerRecipe({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colores.noche,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 22, 28, 22),
          child: Row(
            children: [
              const Icon(
                Icons.document_scanner_rounded,
                size: 96,
                color: Colores.textoTenue,
              ),
              const SizedBox(width: 28),
              const Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Leer un récipe o un informe',
                      style: TextStyle(
                        fontSize: 34,
                        height: 1.1,
                        fontWeight: FontWeight.w700,
                        color: Colores.textoClaro,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Todavía no está lista. Por ahora, su familia anota las pastillas.',
                      style: TextStyle(fontSize: 22, color: Colores.textoTenue),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 28),
              SizedBox(
                width: 220,
                child: BotonGrande(
                  texto: 'Volver',
                  alto: 96,
                  tamano: 28,
                  fondo: Colores.nocheBoton,
                  color: Colores.textoClaro,
                  borde: Colores.nocheBorde,
                  alTocar: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
