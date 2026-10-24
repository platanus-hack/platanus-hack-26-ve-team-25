// Prueba Nube contra la base de verdad, con una casa de prueba: no toca la de Carmen.
// Se salta sola sin las claves. La corre `make test-integracion`, que crea la casa y la borra
// (tool/integracion.py).
import 'package:casa/datos/nube.dart';
import 'package:casa/dominio/alerta.dart';
import 'package:casa/dominio/tipos.dart';
import 'package:flutter_test/flutter_test.dart';

const _url = String.fromEnvironment('SUPABASE_URL');
const _llave = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
const _clave = String.fromEnvironment('PRUEBA_CLAVE');
const _token = String.fromEnvironment('PRUEBA_TOKEN');

void main() {
  final hayClaves = [_url, _llave, _clave, _token].every((v) => v.isNotEmpty);
  late Supabase supabase;
  late Nube nube;

  setUp(() {
    supabase = Supabase(url: _url, llave: _llave);
    nube = Nube(supabase, clave: _clave);
  });
  tearDown(() => nube.dispose());

  Future<Map<String, dynamic>> laFamiliaVe() async =>
      (await supabase.rpc('familia_casa', {'p_token': _token}))
          as Map<String, dynamic>;

  test('el latido llega con la batería', () async {
    await Nube(
      supabase,
      clave: _clave,
      energia: () async => (enchufado: false, bateria: 37),
    ).latir();
    final casa = (await laFamiliaVe())['casa'] as Map<String, dynamic>;
    expect(casa['bateria'], 37);
    expect(casa['enchufado'], false);
  }, skip: !hayClaves);

  test('«Estoy bien»: la familia ve el evento y la alerta cancelada', () async {
    final a = Alerta.preguntar(TipoEvento.hueleGas, DateTime.now());
    nube.nuevaAlerta(a);
    nube.cambioDeEstado(a.cancelar(DateTime.now()).estado);
    await nube.vaciar();

    final datos = await laFamiliaVe();
    final evento = (datos['eventos'] as List).first as Map<String, dynamic>;
    final alerta = (datos['alertas'] as List).first as Map<String, dynamic>;
    expect(evento['tipo'], 'huele_gas');
    expect(alerta['eventoId'], evento['id']);
    expect(alerta['estado'], 'cancelada');
  }, skip: !hayClaves);

  test('el pánico nace escalado y «Fue sin querer» lo atiende', () async {
    final a = Alerta.urgente(TipoEvento.panico, DateTime.now());
    nube.nuevaAlerta(a);
    await nube.vaciar();
    var alerta = ((await laFamiliaVe())['alertas'] as List).first as Map;
    expect(alerta['estado'], 'escalada');

    nube.cambioDeEstado(a.atender(DateTime.now(), 'Prueba').estado);
    await nube.vaciar();
    alerta = ((await laFamiliaVe())['alertas'] as List).first as Map;
    expect(alerta['estado'], 'atendida');
    expect(alerta['atendidaPor'], 'la casa');
  }, skip: !hayClaves);

  test(
    '«Ya me la tomé» descuenta una del inventario, una sola vez por día',
    () async {
      final losartan = await supabase.rpc('familia_recetar', {
        'p_token': _token,
        'p_nombre': 'Losartán',
        'p_concentracion': '50 mg',
        'p_tomas': [
          {'clave': 'losartan-manana', 'hora': '08:00', 'cantidad': 1},
        ],
      });
      await supabase.rpc('familia_ajustar', {
        'p_token': _token,
        'p_medicamento': losartan,
        'p_quedan': 8,
      });

      nube.tomada('losartan-manana', DateTime.now());
      nube.tomada('losartan-manana', DateTime.now());
      await nube.vaciar();

      final inventario = (await laFamiliaVe())['inventario'] as List;
      final m = inventario.cast<Map<String, dynamic>>().firstWhere(
        (m) => m['id'] == losartan,
      );
      expect(m['quedan'], 7);
    },
    skip: !hayClaves,
  );
}
