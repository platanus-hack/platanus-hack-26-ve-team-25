import 'dart:async';

import 'package:flutter/foundation.dart';

import '../dominio/alerta.dart';
import '../dominio/tipos.dart';

/// El estado de la casa que ven las pantallas: la hora y la alerta abierta, si hay una.
/// Hoy los eventos llegan de botones de prueba; después llegarán del oído y de Supabase.
class Controlador extends ChangeNotifier {
  Controlador({required this.casa, DateTime Function()? reloj})
    : _reloj = reloj ?? DateTime.now {
    _tic = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _alPasarUnSegundo(),
    );
  }

  final Casa casa;
  final DateTime Function() _reloj;
  late final Timer _tic;
  Alerta? _alerta;

  DateTime get ahora => _reloj();

  /// La alerta que manda en pantalla, o null si la casa está en reposo.
  Alerta? get alerta => (_alerta?.abierta ?? false) ? _alerta : null;

  /// Un evento que pide confirmación, como la alarma de humo.
  void oirEvento(TipoEvento tipo) => _cambiar(Alerta.preguntar(tipo, ahora));

  /// El pánico y los reportes de la persona avisan a la familia sin esperar.
  void pedirAyuda(TipoEvento motivo) => _cambiar(Alerta.urgente(motivo, ahora));

  void estoyBien() => _cambiar(_alerta?.cancelar(ahora));

  void necesitoAyuda() => _cambiar(_alerta?.escalar(ahora));

  void fueSinQuerer() => _cambiar(_alerta?.atender(ahora, casa.nombre));

  void _alPasarUnSegundo() {
    _alerta = _alerta?.revisar(ahora);
    // El reloj de la pantalla y la cuenta regresiva se redibujan cada segundo.
    notifyListeners();
  }

  void _cambiar(Alerta? nueva) {
    _alerta = nueva;
    notifyListeners();
  }

  @override
  void dispose() {
    _tic.cancel();
    super.dispose();
  }
}
