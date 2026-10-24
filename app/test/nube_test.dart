import 'dart:convert';

import 'package:casa/datos/nube.dart';
import 'package:casa/datos/simulado.dart';
import 'package:casa/dominio/alerta.dart';
import 'package:casa/dominio/rutina.dart';
import 'package:casa/dominio/tipos.dart';
import 'package:casa/ui/controlador.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Una base falsa que anota cada llamada y responde como las funciones de supabase/migrations/.
class BaseFalsa {
  final llamadas = <(String, Map<String, dynamic>)>[];
  bool sinInternet = false;
  int _id = 0;

  late final cliente = MockClient((req) async {
    if (sinInternet) throw http.ClientException('sin internet');
    final funcion = req.url.pathSegments.last;
    final args = jsonDecode(req.body) as Map<String, dynamic>;
    llamadas.add((funcion, args));
    if (req.headers['apikey'] != 'publica') return http.Response('{}', 401);
    final respuesta = switch (funcion) {
      'casa_latido' => true,
      'casa_evento' || 'casa_alerta' => 'id-${++_id}',
      'casa_responder' => 'cancelada',
      'casa_tomar' => {'medicamento': 'Losartán', 'quedan': 7},
      _ => null,
    };
    return http.Response(jsonEncode(respuesta), 200);
  });

  List<String> get funciones => [for (final (f, _) in llamadas) f];
  Map<String, dynamic> ultima(String funcion) =>
      llamadas.lastWhere((l) => l.$1 == funcion).$2;
}

void main() {
  final ahora = DateTime.utc(2026, 10, 24, 14, 5);
  late BaseFalsa base;
  late Nube nube;

  setUp(() {
    base = BaseFalsa();
    nube = Nube(
      Supabase(
        url: 'https://x.supabase.co',
        llave: 'publica',
        cliente: base.cliente,
      ),
      clave: 'clave-casa',
      reloj: () => ahora,
      energia: () async => (enchufado: false, bateria: 41),
      reintento: const Duration(hours: 1),
    );
  });
  tearDown(() => nube.dispose());

  test(
    'los nombres de los eventos van en snake_case, como el enum de la base',
    () {
      expect(tipoEnLaBase(TipoEvento.hueleGas), 'huele_gas');
      expect(tipoEnLaBase(TipoEvento.meSientoMal), 'me_siento_mal');
      expect(tipoEnLaBase(TipoEvento.vidrio), 'vidrio');
    },
  );

  test(
    'una alerta manda primero su evento y cuelga la alerta del id que devolvió',
    () async {
      nube.nuevaAlerta(Alerta.preguntar(TipoEvento.alarma, ahora));
      await nube.vaciar();

      expect(base.funciones, ['casa_evento', 'casa_alerta']);
      expect(base.ultima('casa_evento'), {
        'p_clave': 'clave-casa',
        'p_tipo': 'alarma',
        'p_descripcion': 'Oímos una alarma de humo',
        'p_hora': '2026-10-24T14:05:00.000Z',
      });
      expect(base.ultima('casa_alerta'), {
        'p_clave': 'clave-casa',
        'p_evento': 'id-1',
        'p_espera_s': esperaConfirmacion.inSeconds,
        'p_urgente': false,
      });
    },
  );

  test('«Estoy bien» responde a la alerta con su id de la base', () async {
    final a = Alerta.preguntar(TipoEvento.golpe, ahora);
    nube.nuevaAlerta(a);
    nube.cambioDeEstado(a.cancelar(ahora).estado);
    await nube.vaciar();

    expect(base.ultima('casa_responder'), {
      'p_clave': 'clave-casa',
      'p_alerta': 'id-2',
      'p_respuesta': 'cancelar',
    });
  });

  test('el pánico nace escalado: la base no espera', () async {
    nube.nuevaAlerta(Alerta.urgente(TipoEvento.panico, ahora));
    await nube.vaciar();
    expect(base.ultima('casa_alerta')['p_urgente'], true);
    expect(base.ultima('casa_evento')['p_tipo'], 'panico');
  });

  test('sin internet guarda todo en orden y lo manda cuando vuelve', () async {
    base.sinInternet = true;
    final a = Alerta.preguntar(TipoEvento.vidrio, ahora);
    nube.nuevaAlerta(a);
    nube.cambioDeEstado(a.escalar(ahora).estado);
    await nube.vaciar();
    expect(base.llamadas, isEmpty);
    expect(nube.enCola, 3);

    base.sinInternet = false;
    await nube.latir();
    expect(base.funciones, [
      'casa_latido',
      'casa_evento',
      'casa_alerta',
      'casa_responder',
    ]);
    expect(nube.enCola, 0);
  });

  test('el latido manda si está enchufado y la batería', () async {
    await nube.latir();
    expect(base.ultima('casa_latido'), {
      'p_clave': 'clave-casa',
      'p_enchufado': false,
      'p_bateria': 41,
    });
  });

  test('un rechazo de la base no tapa la cola para siempre', () async {
    final mala = Nube(
      Supabase(
        url: 'https://x.supabase.co',
        llave: 'otra',
        cliente: base.cliente,
      ),
      clave: 'clave-casa',
      reloj: () => ahora,
    );
    addTearDown(mala.dispose);
    mala.nuevaAlerta(Alerta.preguntar(TipoEvento.grito, ahora));
    await mala.vaciar();
    expect(mala.enCola, 0);
    // Sin evento en la base, la alerta no tiene a qué colgarse y no se manda.
    expect(base.funciones, ['casa_evento']);
  });

  test(
    'la rutina va como evento, sin alerta, y el silencio con su porqué',
    () async {
      nube.rutina(EventoDeRutina(ahora, 'Oímos la cocina'));
      nube.rutina(
        EventoDeRutina(
          ahora,
          'No se oye movimiento',
          distinto: 'Desde las 9:00',
        ),
      );
      await nube.vaciar();
      expect(base.funciones, ['casa_evento', 'casa_evento']);
      expect(base.llamadas.first.$2, {
        'p_clave': 'clave-casa',
        'p_tipo': 'rutina',
        'p_descripcion': 'Oímos la cocina',
        'p_hora': '2026-10-24T14:05:00.000Z',
      });
      expect(base.ultima('casa_evento')['p_distinto'], 'Desde las 9:00');
    },
  );

  test('«Ya me la tomé» manda la toma con su hora', () async {
    nube.tomada('losartan-manana', ahora);
    await nube.vaciar();
    expect(base.ultima('casa_tomar'), {
      'p_clave': 'clave-casa',
      'p_pastilla': 'losartan-manana',
      'p_hora': '2026-10-24T14:05:00.000Z',
    });
  });

  test('una toma repetida en la casa se manda una sola vez', () async {
    final c = Controlador(
      casa: casaSimulada,
      pastillas: pastillasSimuladas,
      reloj: () => ahora,
      nube: nube,
    );
    addTearDown(c.dispose);
    c.yaLaTome(pastillasSimuladas.first);
    c.yaLaTome(pastillasSimuladas.first);
    await nube.vaciar();
    expect(base.funciones, ['casa_tomar']);
  });

  test('el controlador le cuenta a la nube la alerta y cada cambio', () async {
    final c = Controlador(casa: casaSimulada, reloj: () => ahora, nube: nube);
    addTearDown(c.dispose);
    c.oirEvento(TipoEvento.alarma);
    c.estoyBien();
    await nube.vaciar();

    expect(base.funciones, ['casa_evento', 'casa_alerta', 'casa_responder']);
    expect(base.ultima('casa_responder')['p_respuesta'], 'cancelar');
  });
}
