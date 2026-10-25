import 'dart:async';
import 'dart:typed_data';

import 'package:casa/datos/camara.dart';
import 'package:casa/dominio/tipos.dart';
import 'package:casa/oido/oido.dart';
import 'package:casa/oido/sonidos.dart';
import 'package:casa/ui/controlador.dart';
import 'package:flutter_test/flutter_test.dart';

import 'telefono_falso.dart';
import 'voz_falsa.dart';

/// Una cámara falsa: anota cuántas fotos tomó y qué llamadas habían salido en ese momento.
class CamaraFalsa implements Camara {
  CamaraFalsa(this.telefono, {this.falla = false, this.colgada = false});

  final TelefonoFalso telefono;
  final bool falla;
  final bool colgada;
  final llamadasAlTomar = <List<String>>[];

  @override
  Future<Uint8List?> foto() async {
    llamadasAlTomar.add([...telefono.porWhatsApp, ...telefono.enAltavoz]);
    if (falla) throw StateError('la cámara está ocupada');
    if (colgada) return Completer<Uint8List?>().future;
    return Uint8List.fromList([0xff, 0xd8, 0xff, 0xd9]);
  }
}

class FotosFalsas implements Fotos {
  final motivos = <String>[];

  @override
  String get urlWeb => 'https://prueba';

  @override
  String get clave => 'clave';

  @override
  Future<bool> subir(Uint8List jpg, String motivo) async {
    motivos.add(motivo);
    return true;
  }
}

void main() {
  const casa = Casa(
    id: 'prueba',
    nombre: 'Carmen',
    condiciones: [],
    contactos: [
      Contacto(
        nombre: 'Josuep',
        relacion: 'hijo',
        canal: Canal.llamada,
        orden: 1,
        telefono: '04120000000',
      ),
    ],
  );
  // Alguien habla, como lo vería YAMNet.
  const voz = Escucha(
    db: -30,
    fondo: -50,
    compuerta: true,
    top: [Clase('Speech', 0.8)],
  );

  late TelefonoFalso t;
  late FotosFalsas fotos;
  var ahora = DateTime(2026, 10, 25, 10);

  setUp(() {
    t = TelefonoFalso();
    fotos = FotosFalsas();
  });

  Controlador casaCon(
    Camara camara, {
    Stream<Escucha>? escuchas,
    FrasesFalsas? frases,
  }) => Controlador(
    casa: casa,
    reloj: () => ahora,
    telefono: t,
    camara: camara,
    fotos: fotos,
    escuchas: escuchas,
    frases: frases,
    microfono: frases == null ? null : MicrofonoFalso(),
    numeroEmergencias: '04129999999',
  );

  testWidgets(
    'al pedir ayuda toma la foto antes de llamar a Josuep, y la sube',
    (tester) async {
      final camara = CamaraFalsa(t);
      final c = casaCon(camara);
      c.pedirAyuda(TipoEvento.panico);
      await tester.pump();
      expect(camara.llamadasAlTomar, [<String>[]]);
      expect(t.porWhatsApp, ['04120000000']);
      expect(fotos.motivos, ['Pidió ayuda: llamando a Josuep']);
      c.dispose();
    },
  );

  testWidgets('si la cámara falla, llama igual y no sube nada', (tester) async {
    final c = casaCon(CamaraFalsa(t, falla: true));
    c.pedirAyuda(TipoEvento.panico);
    await tester.pump();
    expect(t.porWhatsApp, ['04120000000']);
    expect(fotos.motivos, isEmpty);
    c.dispose();
  });

  testWidgets('si la cámara se cuelga, la llamada sale a los 4 s', (
    tester,
  ) async {
    final c = casaCon(CamaraFalsa(t, colgada: true));
    c.pedirAyuda(TipoEvento.panico);
    await tester.pump(Controlador.esperaFoto - const Duration(seconds: 1));
    expect(t.porWhatsApp, isEmpty);
    await tester.pump(const Duration(seconds: 2));
    expect(t.porWhatsApp, ['04120000000']);
    expect(fotos.motivos, isEmpty);
    c.dispose();
  });

  Future<Controlador> decir(
    WidgetTester tester,
    CamaraFalsa camara,
    String frase,
  ) async {
    final oido = StreamController<Escucha>.broadcast(sync: true);
    final c = casaCon(
      camara,
      escuchas: oido.stream,
      frases: FrasesFalsas([frase]),
    );
    oido.add(voz);
    await tester.pump(Controlador.finDeFrase);
    await tester.pump();
    // Pasan los 5 s para decir «no», y sale la llamada.
    ahora = ahora.add(Controlador.esperaLlamada + const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    return c;
  }

  testWidgets('«Lucero, llama a emergencias» toma la foto antes de llamar', (
    tester,
  ) async {
    final camara = CamaraFalsa(t);
    final c = await decir(tester, camara, 'lucero llama a emergencias');
    expect(camara.llamadasAlTomar, [<String>[]]);
    expect(t.enAltavoz, ['04129999999']);
    expect(fotos.motivos, ['Pidió en voz alta: llamando a emergencias']);
    c.dispose();
  });

  testWidgets('«Lucero, llama a mi hijo» es una llamada normal: sin foto', (
    tester,
  ) async {
    final camara = CamaraFalsa(t);
    final c = await decir(tester, camara, 'lucero llama a mi hijo');
    expect(t.porWhatsApp, ['04120000000']);
    expect(camara.llamadasAlTomar, isEmpty);
    expect(fotos.motivos, isEmpty);
    c.dispose();
  });
}
