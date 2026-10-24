import 'package:flutter/material.dart';

/// Los colores y tamaños de los mockups. Pensados para quien ve poco y le tiembla la mano:
/// letra grande, alto contraste y botones de 100 px o más.
abstract final class Colores {
  static const noche = Color(0xFF0B0B0C);
  static const nocheBoton = Color(0xFF18181A);
  static const nocheBorde = Color(0xFF3F3F3B);
  static const relojTenue = Color(0xFFD4D4CF);
  static const textoTenue = Color(0xFFA3A39E);
  static const textoClaro = Color(0xFFF4F4F0);

  static const verde = Color(0xFF14532D);
  static const verdeClaro = Color(0xFFBBF7D0);
  static const verdeFondo = Color(0xFF17241C);
  static const verdePunto = Color(0xFF4ADE80);

  static const rojo = Color(0xFFC4211A);
  static const rojoOscuro = Color(0xFF8F1712);
  static const rojoTarjeta = Color(0xFFA8211A);
  static const rojoTexto = Color(0xFFFDE8E7);

  static const amarillo = Color(0xFFFDB022);
  static const amarilloClaro = Color(0xFFFEC84B);
  static const tinta = Color(0xFF1A1206);

  static const papel = Color(0xFFF7F7F4);
  static const borde = Color(0xFFE2E2DA);
  static const textoGris = Color(0xFF57574F);
}

const fuente = 'AtkinsonHyperlegible';

ThemeData temaCasa() => ThemeData(
  fontFamily: fuente,
  colorScheme: ColorScheme.fromSeed(seedColor: Colores.verde),
  scaffoldBackgroundColor: Colores.noche,
);
