import 'dart:async';

import 'package:flutter/foundation.dart';
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
/// Algo que usa el micrófono y puede soltarlo un momento. El controlador lo pausa mientras el
/// reconocimiento de voz escucha una respuesta, y le pide lo último que oyó para buscar ahí las
/// frases de ayuda.
abstract interface class Microfono {
  Future<void> pausar();
  Future<void> reanudar();

  /// Lo último que oyó, en PCM de 16 bits a 16 kHz. Sale del anillo: nunca deja el teléfono.
  Uint8List ultimoAudio(Duration duracion);
}

class Oido implements Microfono {
  static const _sr = 16000;
  static const _muestrasYamnet = 15600; // 0,975 s: lo que YAMNet mira por vez
  static const _cada = Duration(milliseconds: 500);

  final _recorder = AudioRecorder();
  final _pcm = LectorPcm16();
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
  Timer? _vigilante;
  int _ultimoBloque = 0;
  int? _pausadoDesde;
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

    await _grabar();
    _vigilante = Timer.periodic(const Duration(seconds: 5), (_) => _vigilar());
    return true;
  }

  /// Si dejó de llegar audio sin que nadie lo pausara (una llamada que se quedó con el micrófono,
  /// un error de Android), o si una pausa duró demasiado, vuelve a abrir el micrófono. Sin esto,
  /// la casa podía quedarse sorda en silencio después de una llamada.
  Future<void> _vigilar() async {
    final ahora = _reloj.elapsedMilliseconds;
    final pausado = _pausadoDesde;
    if (_audio == null) {
      if (pausado != null && ahora - pausado > 30000) {
        debugPrint('casa.oido: la pausa duró más de 30 s; se vuelve a oír');
        await reanudar();
      }
      return;
    }
    if (ahora - _ultimoBloque < 5000) return;
    debugPrint(
      'casa.oido: no llega audio hace ${(ahora - _ultimoBloque) ~/ 1000} s; se reabre',
    );
    _tic?.cancel();
    await _audio?.cancel();
    _audio = null;
    try {
      await _recorder.stop();
    } on Object catch (_) {}
    await _grabar();
  }

  /// Suelta el micrófono un momento, para que otro lo use: por ejemplo, el reconocimiento de voz
  /// que escucha «sí» o «no». Dos usos del micrófono a la vez se pisan en Android.
  @override
  Future<void> pausar() async {
    if (_audio == null) return;
    _pausadoDesde = _reloj.elapsedMilliseconds;
    _tic?.cancel();
    await _audio?.cancel();
    _audio = null;
    await _recorder.stop();
  }

  @override
  Uint8List ultimoAudio(Duration duracion) =>
      pcm16DeMuestras(_anillo.ultimas(_sr * duracion.inMilliseconds ~/ 1000));

  /// Vuelve a oír después de una pausa.
  @override
  Future<void> reanudar() async {
    if (_audio != null || _isolate == null) return;
    _pausadoDesde = null;
    await _grabar();
  }

  Future<void> _grabar() async {
    final audio = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: _sr,
        numChannels: 1,
        autoGain: false,
        echoCancel: false,
        noiseSuppress: false,
        // Por defecto, el paquete pausa la grabación cuando otro toma el audio (una llamada, la voz
        // de la alarma) y no la retoma sola: la casa quedaba sorda después de llamar. Así sigue.
        audioInterruption: AudioInterruptionMode.none,
        androidConfig: AndroidRecordConfig(
          audioSource: AndroidAudioSource.unprocessed,
        ),
      ),
    );
    _ultimoBloque = _reloj.elapsedMilliseconds;
    _audio = audio.listen(_alLlegarAudio);
    _tic = Timer.periodic(_cada, (_) => _clasificar());
  }

  // Lo barato corre con cada bloque de audio.
  void _alLlegarAudio(Uint8List bytes) {
    _ultimoBloque = _reloj.elapsedMilliseconds;
    final bloque = _pcm.leer(bytes);
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
    _vigilante?.cancel();
    _tic?.cancel();
    await _audio?.cancel();
    await _recorder.stop();
    await _isolate?.close();
    _modelo?.close();
    await _recorder.dispose();
    await _escuchas.close();
  }
}
