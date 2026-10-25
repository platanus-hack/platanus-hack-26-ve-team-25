import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import 'datos/frases.dart';
import 'datos/llamadas.dart';
import 'datos/nube.dart';
import 'datos/sirena.dart';
import 'datos/voz.dart';
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
  final nube = _nube();
  final frases = kIsWeb ? null : FrasesVosk();
  final controlador = Controlador(
    casa: casaSimulada,
    pastillas: pastillasSimuladas,
    escuchas: oido.escuchas,
    // WhatsApp primero (los hijos suelen estar afuera); si no se puede o no contestan,
    // llamada telefónica normal. En la web no hay ni lo uno ni lo otro.
    telefono: kIsWeb ? null : TelefonoAndroid(),
    voz: kIsWeb ? null : VozAndroid(),
    microfono: oido,
    frases: frases,
    numeroEmergencias: numeroEmergencias,
    sirena: kIsWeb ? null : SirenaAndroid(),
    nube: nube,
  );
  runApp(AppCasa(controlador: controlador));

  // La web es la vista previa de las pantallas: sin oído ni llamadas (ver oido/tflite_web.dart).
  if (kIsWeb) return;

  nube?.iniciar();

  // Los permisos se piden con la app ya en pantalla: Android solo los muestra así.
  await [
    Permission.phone,
    Permission.contacts,
    Permission.notification,
  ].request();
  // «Mostrar sobre otras apps»: para volver sola al frente cuando termina el WhatsApp. Android lo
  // pide en una pantalla de ajustes aparte; se activa una vez al configurar la casa.
  if (!await Permission.systemAlertWindow.isGranted) {
    await Permission.systemAlertWindow.request();
  }
  // El servicio en primer plano (Guardia.kt) mantiene vivo el oído con la pantalla apagada.
  // Android solo deja arrancarlo con el permiso de micrófono ya dado y la app a la vista.
  if (await oido.iniciar()) {
    await const MethodChannel('casa/guardia').invokeMethod<void>('iniciar');
  }
  await frases?.iniciar();
  // El teléfono de mesa es dedicado: que el ahorro de batería no lo mate (docs/riesgos.md §3).
  if (!await Permission.ignoreBatteryOptimizations.isGranted) {
    await Permission.ignoreBatteryOptimizations.request();
  }
}

/// Supabase, si local.json trae la URL, la llave pública y la clave de la casa. La web de la casa
/// se compila sin local.json: es una vista previa y no escribe en la base.
Nube? _nube() {
  const url = String.fromEnvironment('SUPABASE_URL');
  const llave = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  const clave = String.fromEnvironment('CASA_CLAVE');
  if (kIsWeb || url.isEmpty || llave.isEmpty || clave.isEmpty) return null;
  const canal = MethodChannel('casa/energia');
  return Nube(
    Supabase(url: url, llave: llave),
    clave: clave,
    energia: () async {
      final m = await canal.invokeMapMethod<String, Object?>('leer');
      return (
        enchufado: m?['enchufado'] as bool? ?? true,
        bateria: m?['bateria'] as int? ?? 100,
      );
    },
  );
}

class AppCasa extends StatelessWidget {
  const AppCasa({super.key, required this.controlador});

  final Controlador controlador;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Presente',
      debugShowCheckedModeBanner: false,
      theme: temaCasa(),
      // Atrás no cierra la app: si se cierra, la casa deja de oír. Las pantallas que se abren
      // encima (configurar) sí vuelven con Atrás.
      home: PopScope(canPop: false, child: Raiz(c: controlador)),
    );
  }
}
