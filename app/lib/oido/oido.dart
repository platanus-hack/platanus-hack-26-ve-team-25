import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:record/record.dart';
import 'package:tflite_flutter/tflite_flutter.dart'
    if (dart.library.js_interop) 'tflite_web.dart';

import 'anillo.dart';
import 'nivel.dart';
import 'sonidos.dart';

/// Lo que oye la casa en un instante. `sonido` es null si nada que nos importe pasó el umbral.
class Escucha {
  const Escucha({
    required this.db,
    required this.fondo,
    required this.compuerta,
    required this.top,
    this.sonido,
  });

  final double db;
  final double fondo;
  final bool compuerta;
  final List<Clase> top;
  final Sonido? sonido;
}

/// El oído del teléfono: micrófono → nivel y compuerta → YAMNet → sonido.
///
/// El audio entra crudo (sin supresión de ruido ni control de volumen, que borran golpes y
/// alarmas), vive solo en un anillo de 5 s en memoria y nunca sale del teléfono.
/// YAMNet corre en otro isolate para no trabar la pantalla.
///
/// Por ahora YAMNet clasifica dos veces por segundo siempre, como en /escucha. Despertarlo
/// solo cuando la compuerta se abre, para ahorrar batería, va después.
class Oido {
  static const _sr = 16000;
  static const _muestrasYamnet = 15600; // 0,975 s: lo que YAMNet mira por vez
  static const _cada = Duration(milliseconds: 500);

  final _recorder = AudioRecorder();
  final _anillo = Anillo(_sr * 5);
  final _lineaBase = LineaBase();
  final _compuerta = Compuerta();
  final _escuchas = StreamController<Escucha>.broadcast();
  final _reloj = Stopwatch()..start();

  Interpreter? _modelo;
  IsolateInterpreter? _isolate;
  List<String> _etiquetas = const [];
  StreamSubscription<Uint8List>? _audio;
  Timer? _tic;
  bool _clasificando = false;
  double _db = -100;
  bool _abierta = false;

  Stream<Escucha> get escuchas => _escuchas.stream;

  /// Pide el micrófono y empieza a oír. Devuelve false si la persona no dio permiso.
  Future<bool> iniciar() async {
    if (!await _recorder.hasPermission()) return false;

    _etiquetas = leerEtiquetas(
      await rootBundle.loadString('assets/modelos/yamnet_class_map.csv'),
    );
    _modelo = await Interpreter.fromAsset(
      'assets/modelos/yamnet.tflite',
      options: InterpreterOptions()..threads = 2,
    );
    _isolate = await IsolateInterpreter.create(address: _modelo!.address);

    final audio = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: _sr,
        numChannels: 1,
        autoGain: false,
        echoCancel: false,
        noiseSuppress: false,
        androidConfig: AndroidRecordConfig(
          audioSource: AndroidAudioSource.unprocessed,
        ),
      ),
    );
    _audio = audio.listen(_alLlegarAudio);
    _tic = Timer.periodic(_cada, (_) => _clasificar());
    return true;
  }

  // Lo barato corre con cada bloque de audio.
  void _alLlegarAudio(Uint8List bytes) {
    final pcm = Int16List.view(
      bytes.buffer,
      bytes.offsetInBytes,
      bytes.lengthInBytes ~/ 2,
    );
    final bloque = Float32List(pcm.length);
    for (var i = 0; i < pcm.length; i++) {
      bloque[i] = pcm[i] / 32768;
    }
    _anillo.escribir(bloque);
    _db = rmsDb(bloque);
    _abierta = _compuerta.evaluar(
      _db,
      _lineaBase.actualizar(_db),
      _reloj.elapsedMilliseconds,
    );
  }

  // El modelo, dos veces por segundo, sobre el último segundo de audio.
  Future<void> _clasificar() async {
    final isolate = _isolate;
    if (isolate == null ||
        _clasificando ||
        _anillo.disponibles < _muestrasYamnet) {
      return;
    }
    _clasificando = true;
    try {
      final entrada = _anillo.ultimas(_muestrasYamnet);
      final salida = [List<double>.filled(521, 0)];
      await isolate.run(entrada, salida);
      final clases = ordenar(salida[0], _etiquetas);
      _escuchas.add(
        Escucha(
          db: _db,
          fondo: _lineaBase.actual,
          compuerta: _abierta,
          top: clases.take(3).toList(),
          sonido: sonidoDe(clases),
        ),
      );
    } finally {
      _clasificando = false;
    }
  }

  Future<void> detener() async {
    _tic?.cancel();
    await _audio?.cancel();
    await _recorder.stop();
    await _isolate?.close();
    _modelo?.close();
    await _recorder.dispose();
    await _escuchas.close();
  }
}
