import 'dart:async';

import 'package:flutter/foundation.dart';

import '../datos/frases.dart';
import '../datos/llamadas.dart';
import '../datos/nube.dart';
import '../datos/camara.dart';
import '../datos/sirena.dart';
import '../datos/voz.dart';
import '../dominio/alerta.dart';
import '../dominio/comandos.dart';
import '../dominio/pastillas.dart';
import '../dominio/pedidos.dart';
import '../dominio/respuesta.dart';
import '../dominio/rutina.dart';
import '../dominio/tipos.dart';
import '../oido/filtro.dart';
import '../oido/nivel.dart';
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
    this.camara,
    this.fotos,
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
    _finDeTelefono = telefono?.finDeTelefono.listen(_alTerminarTelefono);
    _ventanas = sirena?.ventanas.listen(_alAbrirseLaVentana);
    _hablando = sirena?.hablando.listen(_alHablarElTelefono);
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

  /// Cuando falta esto para avisar, la voz de la alarma dice a quién va a llamar.
  static const avisoFinal = Duration(seconds: 20);

  /// Con los 10 s de la tarima no hay un segundo turno de voz: si el aviso final reemplazara la
  /// frase, nunca se oiría «¿Está bien?». Ahí solo pregunta, y la pantalla dice a quién llama.
  static final diceElFinal = esperaConfirmacion > avisoFinal;

  /// Cuánto se ignoran los sonidos después de callar la alarma: el anillo es de 5 s.
  static const sordoTrasLaAlarma = Duration(seconds: 5);

  /// Lo que se descarta del audio justo después de que el teléfono termina de hablar: lo que
  /// todavía suena del parlante y lo que el anillo recibe con retraso.
  static const colaDeLaVozPropia = Duration(milliseconds: 600);

  /// Lo más que una llamada de emergencia espera a la foto. Si la cámara tarda más o falla, se
  /// llama igual: la foto nunca puede retrasar una emergencia.
  static const esperaFoto = Duration(seconds: 4);

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

  /// La cámara de adelante y la subida de su foto a la web de la familia. Solo se usan justo
  /// antes de llamar por una emergencia. Null sin configurar (y en la web).
  final Camara? camara;
  final Fotos? fotos;

  /// True mientras el reconocimiento de voz escucha la respuesta.
  bool escuchandoVoz = false;
  StreamSubscription<int>? _finDeWhatsApp;
  StreamSubscription<int>? _finDeTelefono;
  bool _esperandoWhatsApp = false;
  bool _esperandoTelefono = false;

  /// True si «¿Pudo hablar con…?» se pregunta después de la llamada por teléfono: si no hablaron,
  /// lo siguiente es emergencias.
  bool preguntaTrasTelefono = false;

  /// True desde que la casa llamó a emergencias porque el hijo no contestó.
  bool llamandoAEmergencias = false;
  DateTime? _preguntaHasta;
  late final Timer _tic;
  StreamSubscription<Escucha>? _oyendo;
  Alerta? _alerta;
  Escucha? _ultimaEscucha;
  final _ultimaVez = <TipoSonido, DateTime>{};
  DateTime? _ultimoPedido;

  /// Lo de siempre que suena en la casa, y el silencio de día que no es normal.
  final rutina = Rutina();

  StreamSubscription<bool>? _ventanas;
  StreamSubscription<bool>? _hablando;

  /// True mientras la sirena se calla para que la persona conteste: la pantalla dice «Le
  /// escucho…».
  bool ventanaParaHablar = false;
  DateTime? _ventanaDesde;

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

  /// Lo que dice el botón rojo del reposo: a quién llama de verdad. Sin número configurado no
  /// promete una llamada.
  String get textoDelBotonRojo => primerContacto.telefono.isNotEmpty
      ? 'Llamar a ${primerContacto.nombre}'
      : 'Pedir ayuda';

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
    await _fotoAntesDeLlamar(
      '${_alerta?.motivo.frase ?? 'Pidió ayuda'}: llamando a ${primerContacto.nombre}',
    );
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
    // Si es la llamada de una alerta, al terminar se pregunta otra vez si hablaron.
    _esperandoTelefono = _alerta?.estado == EstadoAlerta.escalada;
  }

  /// El hijo no contestó ni por WhatsApp ni por teléfono: llamada normal a emergencias, en
  /// altavoz y con el volumen al máximo. La familia ya recibió el Telegram al escalar.
  Future<void> llamarEmergencias() async {
    _preguntaHasta = null;
    preguntaTrasTelefono = false;
    _esperandoTelefono = false;
    final t = telefono;
    if (t == null || numeroEmergencias.isEmpty) return notifyListeners();
    llamandoAEmergencias = true;
    notifyListeners();
    await _fotoAntesDeLlamar(
      '${primerContacto.nombre} no contestó: llamando a emergencias',
    );
    if (!await t.llamarEnAltavoz(numeroEmergencias)) {
      await t.llamar(numeroEmergencias);
    }
  }

  // Igual que con WhatsApp, Android no dice si contestaron la llamada telefónica: se pregunta. Si
  // no hablaron, o nadie responde en 15 s, se llama a emergencias. Sin número de emergencias
  // configurado no se pregunta nada: no habría nada que prometer.
  void _alTerminarTelefono(int segundos) {
    if (!_esperandoTelefono) return;
    _esperandoTelefono = false;
    if (_alerta?.estado != EstadoAlerta.escalada || numeroEmergencias.isEmpty) {
      return;
    }
    preguntaTrasTelefono = true;
    _preguntaHasta = ahora.add(esperaPregunta);
    notifyListeners();
    unawaited(_preguntarPorVoz());
  }

  /// No hablaron: después del WhatsApp se llama por teléfono; después del teléfono, a emergencias.
  Future<void> _siNoHablaron() =>
      preguntaTrasTelefono ? llamarEmergencias() : llamarPorTelefono();

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
        await _siNoHablaron();
      case null:
        notifyListeners();
    }
  }

  void _alOir(Escucha escucha) {
    _escuchasDelMinuto++;
    _ultimaEscucha = escucha;
    final sordo = _sordoHasta;
    final sonido = sordo != null && ahora.isBefore(sordo)
        ? null
        : escucha.sonido;
    final evento = sonido == null ? null : eventoDeSonido(sonido.tipo);
    // Lo que no es alerta (la cocina, la puerta, la TV) cuenta como rutina.
    if (sonido != null && evento == null) {
      for (final e in rutina.oir(sonido.clase.nombre, ahora)) {
        nube?.rutina(e);
      }
    }
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
  /// un «ayuda» débil de una persona mayor puede no pasar el umbral de dB. También durante la
  /// alarma: ahí se puede decir «Lucero, estoy bien» o pedir ayuda.
  bool _hablanEnLaCasa(Escucha e) {
    if (frases == null || microfono == null || escuchandoVoz || _reconociendo) {
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
    // No solo el habla tranquila: un «¡auxilio!» gritado o un quejido YAMNet lo llama grito o
    // llanto, y ahí también hay que escuchar qué dice.
    final voz = [
      'Speech',
      'Shout',
      'Yell',
      'Screaming',
      'Crying, sobbing',
      'Wail, moan',
    ].map(puntaje).fold(0.0, (a, b) => a + b);
    return voz >= 0.4 && tv < 0.2;
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
      final limpio = _sinLaVozPropia(cuanto);
      if (limpio == null) return;
      _actuar(await frases.reconocer(_paraVosk(microfono.ultimoAudio(limpio))));
    } finally {
      _reconociendo = false;
      notifyListeners();
    }
  }

  /// La sirena se calló para escuchar (true) o volvió (false). Al cerrarse la ventana, se
  /// reconoce justo lo que se dijo en ella, aunque YAMNet no haya llegado a marcarlo como voz.
  void _alAbrirseLaVentana(bool abierta) {
    ventanaParaHablar = abierta && _alerta?.estado == EstadoAlerta.pendiente;
    if (abierta) {
      _ventanaDesde = ahora;
    } else {
      final desde = _ventanaDesde;
      _ventanaDesde = null;
      final frases = this.frases;
      final microfono = this.microfono;
      if (desde != null &&
          frases != null &&
          microfono != null &&
          _alerta?.estado == EstadoAlerta.pendiente) {
        var cuanto = ahora.difference(desde);
        if (cuanto > audioDelPedido) cuanto = audioDelPedido;
        final limpio = _sinLaVozPropia(cuanto);
        if (limpio != null) {
          unawaited(
            frases
                .reconocer(_paraVosk(microfono.ultimoAudio(limpio)))
                .then(_actuar, onError: (_) {}),
          );
        }
      }
    }
    notifyListeners();
  }

  bool _telefonoHablando = false;
  DateTime? _calloElTelefono;

  void _alHablarElTelefono(bool hablando) {
    _telefonoHablando = hablando;
    if (!hablando) _calloElTelefono = ahora;
  }

  /// Cuánto de los últimos [cuanto] puede oír Vosk sin oír al propio teléfono, o null si no queda
  /// nada. La frase de la alarma dice «Lucero, estoy bien»: oída por Vosk, la alarma se callaba
  /// sola a los 10 s (Samsung, sábado 23:55).
  Duration? _sinLaVozPropia(Duration cuanto) {
    if (_telefonoHablando) return null;
    final callo = _calloElTelefono;
    if (callo == null) return cuanto;
    final desde = ahora.difference(callo) - colaDeLaVozPropia;
    if (desde <= Duration.zero) return null;
    return desde < cuanto ? desde : cuanto;
  }

  /// Mientras suena la sirena, Vosk recibe el audio sin ella (filtro.dart). YAMNet sigue oyendo
  /// todo: el filtro es solo para entender lo que se dice encima.
  Uint8List _paraVosk(Uint8List pcm) {
    if (_alerta?.estado != EstadoAlerta.pendiente) return pcm;
    return pcm16DeMuestras(quitarSirena(LectorPcm16().leer(pcm)));
  }

  /// Lo que se entendió: una orden, un pedido de ayuda, o nada.
  void _actuar(List<String> versiones) {
    final orden = ordenPorVoz(versiones);
    if (orden != null && _obedecer(orden)) return;
    final pedido = pedidoPorVoz(versiones);
    if (pedido == null) return;
    // Pedir ayuda mientras «¿Está bien?» pregunta es la respuesta: no está bien. Llama ya.
    if (_alerta?.estado == EstadoAlerta.pendiente) {
      necesitoAyuda();
    } else {
      oirEvento(pedido);
    }
  }

  /// True si la orden se cumplió; false si no venía al caso (un «no» sin llamada por salir).
  bool _obedecer(Orden orden) {
    switch (orden) {
      case Orden.cancelar:
        // «No» a «¿Está bien?» es que no está bien.
        if (porLlamar == null) {
          if (_alerta?.estado != EstadoAlerta.pendiente) return false;
          necesitoAyuda();
        } else {
          noLlamar();
        }
      case Orden.estoyBien:
        switch (_alerta?.estado) {
          case EstadoAlerta.pendiente:
            estoyBien();
          // Ya estaba llamando: queda atendida por la casa y no sale la llamada por teléfono que
          // sigue al WhatsApp. Un WhatsApp que ya está timbrando no se puede colgar desde aquí.
          case EstadoAlerta.escalada:
            fueSinQuerer();
          default:
            return false;
        }
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
      await _fotoAntesDeLlamar('Pidió en voz alta: llamando a emergencias');
    }
    if (l.porWhatsApp) {
      await llamarPrimeroPorWhatsApp(l.numero, t);
    } else if (!await t.llamarEnAltavoz(l.numero)) {
      await t.llamar(l.numero);
    }
  }

  /// Una foto de la sala para la familia, justo antes de una llamada de emergencia: con la llamada
  /// abierta, la app queda atrás y Android ya no presta la cámara. Se espera la foto [esperaFoto]
  /// como mucho y se sube sin esperar; si algo falla, se llama igual.
  Future<void> _fotoAntesDeLlamar(String motivo) async {
    final camara = this.camara;
    final fotos = this.fotos;
    if (camara == null || fotos == null) return;
    try {
      final jpg = await camara.foto().timeout(esperaFoto);
      if (jpg == null) return;
      unawaited(
        fotos
            .subir(jpg, motivo)
            .then(
              (ok) => debugPrint('casa.foto: ${ok ? 'subida' : 'no se subió'}'),
              onError: (Object e) => debugPrint('casa.foto: $e'),
            ),
      );
    } on Object catch (e) {
      debugPrint('casa.foto: sin foto ($e)');
    }
  }

  /// Lo primero que dice Lucero apenas nace la alerta: corto, para oír la respuesta de una vez.
  String get preguntaCorta => '${casa.nombre}, ¿está bien?';

  /// Lo que dice en los turnos siguientes de «¿Está bien?».
  String get fraseDeLaAlarma =>
      '${casa.nombre}, ¿está bien? Diga «$nombreDeLaCasa, estoy bien», o deslice el botón.';

  /// Lo que dice cuando quedan [avisoFinal]: lo mismo que promete la pantalla.
  String get fraseDelFinal => primerContacto.telefono.isNotEmpty
      ? '${casa.nombre}, si no responde, voy a llamar a ${primerContacto.nombre}.'
      : '${casa.nombre}, si no responde, voy a avisar a su familia.';

  bool _dijoElFinal = false;
  bool _sonoElTono = false;

  // Una línea por minuto en el log (make logs), para saber qué se trabó si algo se traba: si deja
  // de aparecer, se trabó la app; si el oído da 0, se cayó el micrófono; si la cola crece, no hay
  // internet.
  int _escuchasDelMinuto = 0;
  int _segundos = 0;

  void _salud() {
    if (++_segundos % 60 != 0) return;
    final hhmm = '${ahora.hour}:${ahora.minute.toString().padLeft(2, '0')}';
    debugPrint(
      'casa.salud $hhmm · oído: $_escuchasDelMinuto escuchas/min · '
      'cola: ${nube?.enCola ?? '-'} · alerta: ${_alerta?.estado.name ?? 'ninguna'}',
    );
    _escuchasDelMinuto = 0;
  }

  void _alPasarUnSegundo() {
    _salud();
    final silencio = rutina.revisar(ahora);
    if (silencio != null) nube?.rutina(silencio);
    final pendiente = _alerta;
    if (diceElFinal &&
        !_dijoElFinal &&
        pendiente?.estado == EstadoAlerta.pendiente &&
        pendiente!.restante(ahora) <= avisoFinal) {
      _dijoElFinal = true;
      unawaited(sirena?.decir(fraseDelFinal));
    }
    // Los últimos segundos antes de llamar, el tono y la vibración, para quien no oyó la voz.
    if (!_sonoElTono &&
        pendiente?.estado == EstadoAlerta.pendiente &&
        pendiente!.restante(ahora) <= sirenaAlFinal) {
      _sonoElTono = true;
      unawaited(sirena?.tono());
    }
    final llamada = porLlamar;
    if (llamada != null && porLlamarRestante == Duration.zero) {
      unawaited(_llamarYa(llamada));
    }
    final hasta = _preguntaHasta;
    if (hasta != null && !ahora.isBefore(hasta)) unawaited(_siNoHablaron());
    _cambiar(_alerta?.revisar(ahora));
  }

  void _cambiar(Alerta? nueva, {bool naciendo = false}) {
    final antes = _alerta?.estado;
    _alerta = nueva;
    // Suena mientras pregunta; al responder, vencer o escalar, se calla.
    final ahoraPendiente = nueva?.estado == EstadoAlerta.pendiente;
    if (ahoraPendiente && (naciendo || antes != EstadoAlerta.pendiente)) {
      _dijoElFinal = false;
      _sonoElTono = false;
      unawaited(sirena?.sonar(fraseDeLaAlarma, primera: preguntaCorta));
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
      _esperandoTelefono = false;
      preguntaTrasTelefono = false;
      llamandoAEmergencias = false;
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
    _finDeTelefono?.cancel();
    _ventanas?.cancel();
    _hablando?.cancel();
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
