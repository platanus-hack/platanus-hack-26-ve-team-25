import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:permission_handler/permission_handler.dart';

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
    // Llamada telefónica normal, directa, sin pasar por el marcador. WhatsApp va a futuro.
    llamar: (numero) => FlutterPhoneDirectCaller.callNumber(numero),
  );
  runApp(AppCasa(controlador: controlador));

  // Los permisos se piden con la app ya en pantalla: Android solo los muestra así.
  await Permission.phone.request();
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
