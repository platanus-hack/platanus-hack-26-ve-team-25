import 'package:flutter/material.dart';

/// El botón de la casa: grande, de un solo toque y con el texto en negrita.
class BotonGrande extends StatelessWidget {
  const BotonGrande({
    super.key,
    required this.texto,
    required this.alTocar,
    required this.fondo,
    required this.color,
    this.alto = 104,
    this.tamano = 32,
    this.icono,
    this.borde,
  });

  final String texto;
  final VoidCallback alTocar;
  final Color fondo;
  final Color color;
  final double alto;
  final double tamano;
  final IconData? icono;
  final Color? borde;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: alto,
      width: double.infinity,
      child: FilledButton(
        onPressed: alTocar,
        style: FilledButton.styleFrom(
          backgroundColor: fondo,
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
            side: borde == null
                ? BorderSide.none
                : BorderSide(color: borde!, width: 2),
          ),
          textStyle: TextStyle(
            fontSize: tamano,
            fontWeight: FontWeight.w700,
            height: 1.15,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icono != null) ...[
              Icon(icono, size: tamano * 1.15),
              const SizedBox(width: 14),
            ],
            Flexible(child: Text(texto, textAlign: TextAlign.center)),
          ],
        ),
      ),
    );
  }
}
