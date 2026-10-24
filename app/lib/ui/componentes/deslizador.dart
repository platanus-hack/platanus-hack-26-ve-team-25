import 'package:flutter/material.dart';

/// «Deslice para…»: un riel recto y ancho con un botón que se arrastra hasta el final.
///
/// Cuesta un poco más que un toque, así nadie apaga la alarma por reflejo aunque esté mal.
/// Pero es fácil con temblor: el riel es alto, el botón es grande, no hay que seguir un camino
/// preciso y basta llegar al 85% del recorrido. Si se suelta antes, vuelve al inicio.
class Deslizador extends StatefulWidget {
  const Deslizador({
    super.key,
    required this.texto,
    required this.alCompletar,
    required this.fondo,
    required this.boton,
    required this.color,
    this.alto = 104,
  });

  final String texto;
  final VoidCallback alCompletar;
  final Color fondo;
  final Color boton;
  final Color color;
  final double alto;

  @override
  State<Deslizador> createState() => _DeslizadorState();
}

class _DeslizadorState extends State<Deslizador> {
  static const _umbral = 0.85;
  double _avance = 0; // 0 = al inicio, 1 = al final

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, limites) {
        final margen = 8.0;
        final lado = widget.alto - margen * 2;
        final recorrido = limites.maxWidth - lado - margen * 2;

        return Semantics(
          button: true,
          label: widget.texto,
          // Con lector de pantalla, un toque doble basta.
          onTap: widget.alCompletar,
          child: Container(
            height: widget.alto,
            decoration: BoxDecoration(
              color: widget.fondo,
              borderRadius: BorderRadius.circular(widget.alto / 2),
            ),
            child: Stack(
              children: [
                Center(
                  child: Padding(
                    padding: EdgeInsets.only(left: lado * 0.9),
                    child: Opacity(
                      opacity: (1 - _avance * 1.6).clamp(0, 1),
                      child: Text(
                        widget.texto,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: widget.color,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: margen + recorrido * _avance,
                  top: margen,
                  child: GestureDetector(
                    onHorizontalDragUpdate: (d) => setState(
                      () => _avance = (_avance + d.delta.dx / recorrido).clamp(
                        0,
                        1,
                      ),
                    ),
                    onHorizontalDragEnd: (_) {
                      if (_avance >= _umbral) widget.alCompletar();
                      setState(() => _avance = 0);
                    },
                    child: Container(
                      width: lado,
                      height: lado,
                      decoration: BoxDecoration(
                        color: widget.boton,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: lado * 0.5,
                        color: widget.fondo,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
