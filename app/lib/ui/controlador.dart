import 'dart:async';

import 'package:flutter/foundation.dart';

import '../datos/frases.dart';
import '../datos/llamadas.dart';
import '../datos/nube.dart';
import '../datos/sirena.dart';
import '../datos/voz.dart';
import '../dominio/alerta.dart';
import '../dominio/comandos.dart';
import '../dominio/pastillas.dart';
import '../dominio/pedidos.dart';
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
    this.frases,
    this.nube,
    this.numeroEmergencias = '',
    this.sirena,
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

  /// Cuando el oído oye hablar, cuánto se espera a que termine la frase, cuánto audio se le
  /// pasa a Vosk y cada cuánto se puede volver a reconocer. Vosk no pausa el oído, así que puede
  /// ser seguido; el límite es la CPU del teléfono viejo.
  static const finDeFrase = Duration(milliseconds: 1500);
  static const audioDelPedido = Duration(seconds: 5);
  static const repetirPedido = Duration(seconds: 4);

  /// Cuánto se ignoran los sonidos después de callar la alarma: el anillo es de 5 s.
  static const sordoTrasLaAlarma = Duration(seconds: 5);

  /// Cuánto se espera antes de una llamada pedida en voz alta, para decir «no».
  static const esperaLlamada = Duration(seconds: 5);

  final Casa casa;

  /// Las pastillas del día y cuáles ya tomó.
  final PlanDelDia plan;
  Pastilla? _forzada;
  final DateTime Function() _reloj;
  final Telefono? telefono;

  /// Para responder «¿Pudo hablar con…?» por voz, además del botón.
  final Voz? voz;

  /// El oído, que se pausa mientras la voz escucha y guarda lo último que oyó.
  final Microfono? microfono;

  /// El tono de 520 Hz y la vibración de «¿Está bien?». Null en la web.
  final Sirena? sirena;

  /// Al que llama «Lucero, llama a emergencias». Vacío si no está configurado.
  final String numeroEmergencias;

  /// Las frases de ayuda dichas en voz alta, reconocidas con Vosk sobre el audio del oído.
  final Frases? frases;

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

  /// Hasta cuándo no se hace caso a los sonidos: justo después de callar la alarma, el oído
  /// todavía tiene el tono de 520 Hz en el anillo y abriría otro «¿Está bien?».
  DateTime? _sordoHasta;
  bool _reconociendo = false;

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
    if (!plan.tomada(p)) nube?.tomada(p.id, ahora);
    plan.marcarTomada(p, ahora);
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
    final sordo = _sordoHasta;
    final sonido = sordo != null && ahora.isBefore(sordo)
        ? null
        : escucha.sonido;
    final evento = sonido == null ? null : eventoDeSonido(sonido.tipo);
    if (sonido != null && evento != null) {
      final antes = _ultimaVez[sonido.tipo];
      if (antes == null || ahora.difference(antes) >= _repetir) {
        _ultimaVez[sonido.tipo] = ahora;
        oirEvento(evento);
      }
    }
    if (_hablanEnLaCasa(escucha)) unawaited(_reconocerVoz());
    notifyListeners();
  }

  /// YAMNet oye a una persona hablar, y no es la TV. No se pide que la compuerta esté abierta:
  /// un «ayuda» débil de una persona mayor puede no pasar el umbral de dB.
  bool _hablanEnLaCasa(Escucha e) {
    if (frases == null ||
        microfono == null ||
        alerta != null ||
        _reconociendo) {
      return false;
    }
    final antes = _ultimoPedido;
    // Mientras corren los 5 s antes de una llamada, el «no» tiene que llegar a tiempo.
    if (porLlamar == null &&
        antes != null &&
        ahora.difference(antes) < repetirPedido) {
      return false;
    }
    double puntaje(String clase) =>
        e.top.where((c) => c.nombre == clase).firstOrNull?.puntaje ?? 0;
    final tv = puntaje('Television') + puntaje('Radio');
    return puntaje('Speech') >= 0.4 && tv < 0.2;
  }

  /// Busca en los últimos segundos que oyó la casa una orden (comandos.dart) o un pedido de
  /// ayuda (pedidos.dart). Vosk lee el mismo anillo que YAMNet, así que el oído nunca se pausa y
  /// la frase que despertó al reconocedor también cuenta.
  ///
  /// Un pedido pasa por «¿Está bien?» y no llama directo: si la voz era de la TV o se entendió
  /// mal, la persona lo apaga deslizando; si no responde, escala. Una orden de llamar sí llama,
  /// pero solo si empezó con el nombre de la casa y después de 5 s para decir «no».
  Future<void> _reconocerVoz() async {
    final frases = this.frases;
    final microfono = this.microfono;
    if (frases == null || microfono == null) return;
    _ultimoPedido = ahora;
    _reconociendo = true;
    try {
      // Que la frase termine de entrar al anillo antes de leerlo.
      await Future<void>.delayed(finDeFrase);
      // Durante los 5 s antes de una llamada, solo lo que se dijo desde que empezaron: si no, la
      // orden misma volvería a leerse.
      final llamada = porLlamar;
      var cuanto = audioDelPedido;
      if (llamada != null) {
        final desde = ahora.difference(llamada.desde);
        if (desde < cuanto) cuanto = desde;
      }
      final versiones = await frases.reconocer(microfono.ultimoAudio(cuanto));
      final orden = ordenPorVoz(versiones);
      if (orden != null && _obedecer(orden)) return;
      final pedido = pedidoPorVoz(versiones);
      if (pedido != null) oirEvento(pedido);
    } finally {
      _reconociendo = false;
      notifyListeners();
    }
  }

  /// True si la orden se cumplió; false si no venía al caso (un «no» sin llamada por salir).
  bool _obedecer(Orden orden) {
    switch (orden) {
      case Orden.cancelar:
        if (porLlamar == null) return false;
        noLlamar();
      case Orden.yaMeLaTome:
        final p = recordatorio;
        if (p == null) return false;
        yaLaTome(p);
      case Orden.llamarEmergencias:
        _prepararLlamada(
          LlamadaPorVoz(
            quien: 'emergencias',
            numero: numeroEmergencias,
            emergencias: true,
            desde: ahora,
          ),
        );
      case Orden.llamarHijo || Orden.llamarVecino:
        final relaciones = orden == Orden.llamarHijo
            ? const {'hijo', 'hija'}
            : const {'vecino', 'vecina'};
        final contacto =
            ([...casa.contactos]..sort((a, b) => a.orden.compareTo(b.orden)))
                .where((c) => relaciones.contains(c.relacion))
                .firstOrNull;
        if (contacto == null) return false;
        _prepararLlamada(
          LlamadaPorVoz(
            quien: contacto.nombre,
            numero: contacto.telefono,
            porWhatsApp: contacto.relacion.startsWith('hij'),
            desde: ahora,
          ),
        );
    }
    return true;
  }

  /// La llamada que se pidió en voz alta y sale cuando pasen [esperaLlamada], o null.
  LlamadaPorVoz? porLlamar;

  /// Lo que falta para que salga la llamada pedida en voz alta.
  Duration get porLlamarRestante {
    final l = porLlamar;
    if (l == null) return Duration.zero;
    final hasta = l.desde.add(esperaLlamada);
    return ahora.isBefore(hasta) ? hasta.difference(ahora) : Duration.zero;
  }

  void _prepararLlamada(LlamadaPorVoz llamada) {
    if (alerta != null) return; // la alerta ya tiene su propia llamada
    porLlamar = llamada;
    notifyListeners();
  }

  /// «No llamar», con el botón o diciendo «no».
  void noLlamar() {
    porLlamar = null;
    notifyListeners();
  }

  Future<void> _llamarYa(LlamadaPorVoz l) async {
    porLlamar = null;
    notifyListeners();
    final t = telefono;
    if (t == null || l.numero.isEmpty) return;
    if (l.emergencias) {
      // La familia también se entera, como un pedido de ayuda ya escalado. No se cambia la
      // alerta de la casa: si no, la casa llamaría además al primer contacto encima del 911.
      nube?.nuevaAlerta(Alerta.urgente(TipoEvento.panico, ahora));
    }
    if (l.porWhatsApp) {
      await llamarPrimeroPorWhatsApp(l.numero, t);
    } else if (!await t.llamarEnAltavoz(l.numero)) {
      await t.llamar(l.numero);
    }
  }

  void _alPasarUnSegundo() {
    final llamada = porLlamar;
    if (llamada != null && porLlamarRestante == Duration.zero) {
      unawaited(_llamarYa(llamada));
    }
    final hasta = _preguntaHasta;
    if (hasta != null && !ahora.isBefore(hasta)) unawaited(llamarPorTelefono());
    _cambiar(_alerta?.revisar(ahora));
  }

  void _cambiar(Alerta? nueva, {bool naciendo = false}) {
    final antes = _alerta?.estado;
    _alerta = nueva;
    // Suena mientras pregunta; al responder, vencer o escalar, se calla.
    final ahoraPendiente = nueva?.estado == EstadoAlerta.pendiente;
    if (ahoraPendiente && (naciendo || antes != EstadoAlerta.pendiente)) {
      unawaited(sirena?.sonar());
    } else if (!ahoraPendiente && antes == EstadoAlerta.pendiente) {
      unawaited(sirena?.callar());
      _sordoHasta = ahora.add(sordoTrasLaAlarma);
    }
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
    if (_alerta?.estado == EstadoAlerta.pendiente) unawaited(sirena?.callar());
    _tic.cancel();
    _oyendo?.cancel();
    _finDeWhatsApp?.cancel();
    super.dispose();
  }
}

/// Una llamada pedida en voz alta («Lucero, llama a mi hijo») que espera sus 5 s.
class LlamadaPorVoz {
  const LlamadaPorVoz({
    required this.quien,
    required this.numero,
    required this.desde,
    this.emergencias = false,
    this.porWhatsApp = false,
  });

  /// Cómo se dice en pantalla: «emergencias» o el nombre del contacto.
  final String quien;

  /// Vacío si no hay número configurado: la pantalla lo dice y no llama.
  final String numero;
  final DateTime desde;
  final bool emergencias;

  /// Al hijo, WhatsApp primero (suele estar afuera); al vecino y a emergencias, llamada normal
  /// en altavoz.
  final bool porWhatsApp;
}
