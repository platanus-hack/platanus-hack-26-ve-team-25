import 'dart:async';

import 'package:flutter/foundation.dart';

import '../dominio/alerta.dart';
import '../dominio/tipos.dart';
import '../oido/oido.dart';
import '../oido/sonidos.dart';

/// Cómo se llama a un número. En la app es una llamada directa; en las pruebas, una falsa.
typedef Llamar = Future<void> Function(String numero);

/// El estado de la casa que ven las pantallas: la hora, lo último que oyó y la alerta abierta.
class Controlador extends ChangeNotifier {
  Controlador({
    required this.casa,
    DateTime Function()? reloj,
    Stream<Escucha>? escuchas,
    this.llamar,
  }) : _reloj = reloj ?? DateTime.now {
    _tic = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _alPasarUnSegundo(),
    );
    _oyendo = escuchas?.listen(_alOir);
  }

  /// El mismo sonido no vuelve a preguntar «¿Está bien?» antes de este tiempo.
  static const _repetir = Duration(seconds: 3);

  final Casa casa;
  final DateTime Function() _reloj;
  final Llamar? llamar;
  late final Timer _tic;
  StreamSubscription<Escucha>? _oyendo;
  Alerta? _alerta;
  Escucha? _ultimaEscucha;
  final _ultimaVez = <TipoSonido, DateTime>{};

  DateTime get ahora => _reloj();

  /// Lo último que oyó el teléfono, para la línea de diagnóstico.
  Escucha? get ultimaEscucha => _ultimaEscucha;

  /// La alerta que manda en pantalla, o null si la casa está en reposo.
  Alerta? get alerta => (_alerta?.abierta ?? false) ? _alerta : null;

  /// El primero de la lista, al que se llama cuando la alerta escala.
  Contacto get primerContacto =>
      ([...casa.contactos]..sort((a, b) => a.orden.compareTo(b.orden))).first;

  /// Un evento que pide confirmación, como la alarma de humo. Si ya hay una alerta abierta, se
  /// ignora: no se pregunta dos veces a la vez.
  void oirEvento(TipoEvento tipo) {
    if (alerta != null) return;
    _cambiar(Alerta.preguntar(tipo, ahora));
  }

  /// El pánico y los reportes de la persona avisan a la familia sin esperar.
  void pedirAyuda(TipoEvento motivo) => _cambiar(Alerta.urgente(motivo, ahora));

  void estoyBien() => _cambiar(_alerta?.cancelar(ahora));

  void necesitoAyuda() => _cambiar(_alerta?.escalar(ahora));

  void fueSinQuerer() => _cambiar(_alerta?.atender(ahora, casa.nombre));

  /// Llama al primer contacto. Sin número configurado no hace nada.
  Future<void> llamarPrimerContacto() async {
    final numero = primerContacto.telefono;
    if (numero.isEmpty) return;
    await llamar?.call(numero);
  }

  void _alOir(Escucha escucha) {
    _ultimaEscucha = escucha;
    final sonido = escucha.sonido;
    final evento = sonido == null ? null : eventoDeSonido(sonido.tipo);
    if (sonido != null && evento != null) {
      final antes = _ultimaVez[sonido.tipo];
      if (antes == null || ahora.difference(antes) >= _repetir) {
        _ultimaVez[sonido.tipo] = ahora;
        oirEvento(evento);
      }
    }
    notifyListeners();
  }

  void _alPasarUnSegundo() {
    _cambiar(_alerta?.revisar(ahora));
  }

  void _cambiar(Alerta? nueva) {
    final antes = _alerta?.estado;
    _alerta = nueva;
    // Al escalar, una sola vez, la casa llama al primer contacto.
    if (antes != EstadoAlerta.escalada &&
        nueva?.estado == EstadoAlerta.escalada) {
      unawaited(llamarPrimerContacto());
    }
    // El reloj de la pantalla y la cuenta regresiva se redibujan cada segundo.
    notifyListeners();
  }

  @override
  void dispose() {
    _tic.cancel();
    _oyendo?.cancel();
    super.dispose();
  }
}
