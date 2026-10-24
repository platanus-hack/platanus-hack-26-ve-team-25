import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'datos/simulado.dart';
import 'tema.dart';
import 'ui/controlador.dart';
import 'ui/raiz.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // El teléfono de la casa vive de pie y enchufado; el reloj de mesa acostado va después.
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(AppCasa(controlador: Controlador(casa: casaSimulada)));
}

class AppCasa extends StatelessWidget {
  const AppCasa({super.key, required this.controlador});

  final Controlador controlador;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Casa',
      debugShowCheckedModeBanner: false,
      theme: temaCasa(),
      home: Raiz(c: controlador),
    );
  }
}
