import 'dart:async';

import 'package:flutter/foundation.dart';

import '../datos/llamadas.dart';
import '../datos/nube.dart';
import '../datos/voz.dart';
import '../dominio/alerta.dart';
import '../dominio/pastillas.dart';
import '../dominio/respuesta.dart';
import '../dominio/tipos.dart';
import '../oido/oido.dart';
import '../oido/sonidos.dart';

/// El estado de la casa que ven las pantallas: la hora, lo último que oyó y la alerta abierta.
class Controlador extends ChangeNotifier {
  Controlador({
    required this.casa,
    DateTime Function()? reloj,
    Stream<Escucha>? escuchas,
    this.telefono,
    this.voz,
    this.microfono,
    this.nube,
    List<Pastilla> pastillas = const [],
  }) : _reloj = reloj ?? DateTime.now,
       plan = PlanDelDia(pastillas) {
    _tic = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _alPasarUnSegundo(),
    );
    _oyendo = escuchas?.listen(_alOir);
    _finDeWhatsApp = telefono?.finDeWhatsApp.listen(_alTerminarWhatsApp);
  }

  /// El mismo sonido no vuelve a preguntar «¿Está bien?» antes de este tiempo.
  static const _repetir = Duration(seconds: 3);

  /// Una llamada de WhatsApp que terminó antes de esto no llegó a timbrar de verdad: rechazada,
  /// sin internet o caída. Se llama por teléfono sin preguntar.
  static const finCorto = Duration(seconds: 10);

  /// Cuánto se espera a que la persona diga «Sí, ya hablamos» antes de llamar por teléfono.
  static const esperaPregunta = Duration(seconds: 15);

  /// Cuánto escucha la voz cuando el oído oye hablar a alguien, y cada cuánto puede volver a
  /// hacerlo. Mientras la voz escucha, YAMNet no oye: por eso no puede ser seguido.
  static const escuchaPedido = Duration(seconds: 6);
  static const repetirPedido = Duration(seconds: 20);

  final Casa casa;

  /// Las pastillas del día y cuáles ya tomó.
  final PlanDelDia plan;
  Pastilla? _forzada;
  final DateTime Function() _reloj;
  final Telefono? telefono;

  /// Para responder «¿Pudo hablar con…?» por voz, además del botón.
  final Voz? voz;

  /// El oído, que se pausa mientras la voz escucha.
  final Microfono? microfono;

  /// Supabase, para que la familia vea lo que pasa. Null sin configurar (y en la web).
  final Nube? nube;

  /// True mientras el reconocimiento de voz escucha la respuesta.
  bool escuchandoVoz = false;
  StreamSubscription<int>? _finDeWhatsApp;
  bool _esperandoWhatsApp = false;
  DateTime? _preguntaHasta;
  late final Timer _tic;
  StreamSubscription<Escucha>? _oyendo;
  Alerta? _alerta;
  Escucha? _ultimaEscucha;
  final _ultimaVez = <TipoSonido, DateTime>{};
  DateTime? _ultimoPedido;

  DateTime get ahora => _reloj();

  /// Lo último que oyó el teléfono, para la línea de diagnóstico.
  Escucha? get ultimaEscucha => _ultimaEscucha;

  /// La alerta que manda en pantalla, o null si la casa está en reposo.
  Alerta? get alerta => (_alerta?.abierta ?? false) ? _alerta : null;

  /// La pastilla que le toca ahora, para resaltarla en el reposo.
  Pastilla? get pastillaQueToca => _forzada ?? plan.leToca(ahora);

  /// La pastilla que se recuerda en pantalla completa, o null.
  Pastilla? get recordatorio => _forzada ?? plan.recordar(ahora);

  /// Para probar sin esperar a la hora: la próxima pastilla pendiente se recuerda ya.
  void recordarAhora() {
    _forzada = plan.siguientePendiente(ahora);
    notifyListeners();
  }

  void yaLaTome(Pastilla p) {
    plan.marcarTomada(p, ahora);
    if (_forzada == p) _forzada = null;
    notifyListeners();
  }

  void recordarLuego(Pastilla p) {
    plan.posponer(p, ahora);
    if (_forzada == p) _forzada = null;
    notifyListeners();
  }

  /// El primero de la lista, al que se llama cuando la alerta escala.
  Contacto get primerContacto =>
      ([...casa.contactos]..sort((a, b) => a.orden.compareTo(b.orden))).first;

  /// Un evento que pide confirmación, como la alarma de humo. Si ya hay una alerta abierta, se
  /// ignora: no se pregunta dos veces a la vez.
  void oirEvento(TipoEvento tipo) {
    if (alerta != null) return;
    _nacer(Alerta.preguntar(tipo, ahora));
  }

  /// El pánico y los reportes de la persona avisan a la familia sin esperar.
  void pedirAyuda(TipoEvento motivo) => _nacer(Alerta.urgente(motivo, ahora));

  void _nacer(Alerta a) {
    nube?.nuevaAlerta(a);
    _cambiar(a, naciendo: true);
  }

  void estoyBien() => _cambiar(_alerta?.cancelar(ahora));

  void necesitoAyuda() => _cambiar(_alerta?.escalar(ahora));

  void fueSinQuerer() => _cambiar(_alerta?.atender(ahora, casa.nombre));

  /// Después de una llamada de WhatsApp larga, lo que falta para llamar por teléfono si nadie
  /// responde «Sí, ya hablamos». Null si no se está preguntando.
  Duration? get preguntaRestante {
    final hasta = _preguntaHasta;
    if (hasta == null) return null;
    return ahora.isBefore(hasta) ? hasta.difference(ahora) : Duration.zero;
  }

  /// «Sí, ya hablamos»: el contacto contestó, la alerta queda atendida.
  void siHablamos() => _cambiar(_alerta?.atender(ahora, primerContacto.nombre));

  /// Llama al primer contacto, WhatsApp primero. Sin número configurado no hace nada.
  Future<void> llamarPrimerContacto() async {
    final t = telefono;
    final numero = primerContacto.telefono;
    if (t == null || numero.isEmpty) return;
    _preguntaHasta = null;
    final via = await llamarPrimeroPorWhatsApp(numero, t);
    _esperandoWhatsApp = via == ViaLlamada.whatsapp;
    notifyListeners();
  }

  /// La llamada telefónica normal, sin pasar por WhatsApp.
  Future<void> llamarPorTelefono() async {
    final t = telefono;
    final numero = primerContacto.telefono;
    _preguntaHasta = null;
    _esperandoWhatsApp = false;
    notifyListeners();
    if (t == null || numero.isEmpty) return;
    await t.llamar(numero);
  }

  // Android no dice si contestaron el WhatsApp. Si terminó muy rápido, no timbró: se llama por
  // teléfono ya. Si duró más, pudo haber timbrado sin respuesta o haber una conversación: se
  // pregunta, y si nadie responde a tiempo, se llama por teléfono.
  void _alTerminarWhatsApp(int segundos) {
    if (!_esperandoWhatsApp) return;
    _esperandoWhatsApp = false;
    if (_alerta?.estado != EstadoAlerta.escalada) return;
    if (Duration(seconds: segundos) < finCorto) {
      unawaited(llamarPorTelefono());
    } else {
      _preguntaHasta = ahora.add(esperaPregunta);
      notifyListeners();
      unawaited(_preguntarPorVoz());
    }
  }

  /// La respuesta también puede venir por voz: «sí» cierra la alerta y «no» llama por teléfono
  /// ya. Si no se entiende, sigue la cuenta regresiva y la llamada sale igual.
  Future<void> _preguntarPorVoz() async {
    final voz = this.voz;
    if (voz == null) return;
    escuchandoVoz = true;
    notifyListeners();
    List<String> versiones = const [];
    try {
      await microfono?.pausar();
      versiones = await voz.escuchar(
        hasta: esperaPregunta - const Duration(seconds: 2),
      );
    } finally {
      escuchandoVoz = false;
      await microfono?.reanudar();
    }
    // Si ya se respondió con el botón o se llamó mientras escuchaba, no hay nada que hacer.
    if (_preguntaHasta == null) return notifyListeners();
    switch (interpretarRespuesta(versiones)) {
      case Respuesta.si:
        siHablamos();
      case Respuesta.no:
        await llamarPorTelefono();
      case null:
        notifyListeners();
    }
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
    if (_hablanEnLaCasa(escucha)) unawaited(_escucharPedido());
    notifyListeners();
  }

  /// YAMNet oye a una persona hablar, y no es la TV. No se pide que la compuerta esté abierta:
  /// un «ayuda» débil de una persona mayor puede no pasar el umbral de dB.
  bool _hablanEnLaCasa(Escucha e) {
    if (voz == null || alerta != null || escuchandoVoz) return false;
    final antes = _ultimoPedido;
    if (antes != null && ahora.difference(antes) < repetirPedido) return false;
    double puntaje(String clase) =>
        e.top.where((c) => c.nombre == clase).firstOrNull?.puntaje ?? 0;
    final tv = puntaje('Television') + puntaje('Radio');
    return puntaje('Speech') >= 0.4 && tv < 0.2;
  }

  /// «Huele a gas», «me siento mal» o «ayuda», dichos en voz alta. El reconocedor empieza a
  /// escuchar después de que el oído oyó hablar, así que entiende lo que la persona dice a
  /// continuación o repite. Lo que pide pasa por «¿Está bien?» y no llama directo: así, si la voz
  /// venía de la TV o se entendió mal, la persona lo apaga deslizando, y si no responde, escala.
  Future<void> _escucharPedido() async {
    final voz = this.voz;
    if (voz == null) return;
    _ultimoPedido = ahora;
    escuchandoVoz = true;
    notifyListeners();
    List<String> versiones = const [];
    try {
      await microfono?.pausar();
      versiones = await voz.escuchar(hasta: escuchaPedido);
    } finally {
      escuchandoVoz = false;
      await microfono?.reanudar();
    }
    final pedido = pedidoPorVoz(versiones);
    if (pedido != null) oirEvento(pedido);
    notifyListeners();
  }

  void _alPasarUnSegundo() {
    final hasta = _preguntaHasta;
    if (hasta != null && !ahora.isBefore(hasta)) unawaited(llamarPorTelefono());
    _cambiar(_alerta?.revisar(ahora));
  }

  void _cambiar(Alerta? nueva, {bool naciendo = false}) {
    final antes = _alerta?.estado;
    _alerta = nueva;
    // La base hace las mismas transiciones que Alerta: se le cuenta cada cambio de estado.
    if (!naciendo && nueva != null && nueva.estado != antes) {
      nube?.cambioDeEstado(nueva.estado);
    }
    // Si la alerta se cerró, ya no hay nada que preguntar ni llamada que esperar.
    if (!(nueva?.abierta ?? false)) {
      _preguntaHasta = null;
      _esperandoWhatsApp = false;
    }
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
    _finDeWhatsApp?.cancel();
    super.dispose();
  }
}
