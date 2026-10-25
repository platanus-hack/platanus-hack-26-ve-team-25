import 'dart:async';
import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// La cámara de adelante del teléfono de mesa, que mira hacia la sala. Solo se prende justo antes
/// de llamar por una emergencia, toma una foto y se apaga. El audio nunca sale del teléfono; esta
/// foto sí (decidido el sábado 24, ver docs/por-planificar.md §4).
abstract interface class Camara {
  /// Un JPEG chico, o null si no hay cámara o Android no la presta.
  Future<Uint8List?> foto();
}

class CamaraAndroid implements Camara {
  /// La cámara mide la luz al prenderse: una foto tomada al instante sale oscura.
  static const ajusteDeLuz = Duration(milliseconds: 600);

  @override
  Future<Uint8List?> foto() async {
    final camaras = await availableCameras();
    if (camaras.isEmpty) return null;
    final adelante = camaras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => camaras.first,
    );
    // 720×480 en JPEG: unos 60 KB, se sube rápido aun con datos móviles.
    final controlador = CameraController(
      adelante,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    try {
      await controlador.initialize();
      await Future<void>.delayed(ajusteDeLuz);
      final archivo = await controlador.takePicture();
      return await archivo.readAsBytes();
    } finally {
      await controlador.dispose();
    }
  }
}

/// Manda la foto a la web de la familia (web/src/app/api/casa/foto), que la guarda, la hace
/// describir por Claude y la reenvía por Telegram. Sin internet se pierde: no entra en la cola.
class Fotos {
  Fotos({required this.urlWeb, required this.clave, http.Client? cliente})
    : _cliente = cliente ?? http.Client();

  final String urlWeb;
  final String clave;
  final http.Client _cliente;

  Future<bool> subir(Uint8List jpg, String motivo) async {
    final r = await _cliente
        .post(
          Uri.parse('$urlWeb/api/casa/foto')
              .replace(queryParameters: {'motivo': motivo}),
          headers: {
            'Authorization': 'Bearer $clave',
            'Content-Type': 'image/jpeg',
          },
          body: jpg,
        )
        .timeout(const Duration(seconds: 20));
    if (r.statusCode != 201) {
      debugPrint('casa.foto: ${r.statusCode} ${utf8.decode(r.bodyBytes)}');
    }
    return r.statusCode == 201;
  }
}
