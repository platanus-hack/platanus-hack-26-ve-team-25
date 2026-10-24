import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import 'datos/llamadas.dart';
import 'datos/simulado.dart';
import 'oido/oido.dart';
import 'tema.dart';
import 'ui/controlador.dart';
import 'ui/raiz.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // El teléfono de la casa vive acostado y enchufado, como un reloj de mesa.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  final oido = Oido();
  final controlador = Controlador(
    casa: casaSimulada,
    pastillas: pastillasSimuladas,
    escuchas: oido.escuchas,
    // WhatsApp primero (los hijos suelen estar afuera); si no se puede, llamada normal.
    llamar: llamarEnElTelefono,
  );
  runApp(AppCasa(controlador: controlador));

  // Los permisos se piden con la app ya en pantalla: Android solo los muestra así.
  await [Permission.phone, Permission.contacts].request();
  await oido.iniciar();
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
