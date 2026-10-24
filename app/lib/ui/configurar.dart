import 'package:flutter/material.dart';

import '../dominio/tipos.dart';
import '../tema.dart';

/// La configuración la hace el familiar, no la persona mayor. Por ahora solo muestra los
/// datos simulados: guardar va cuando exista Supabase (P1, ver docs/pantallas.md).
class Configurar extends StatelessWidget {
  const Configurar({super.key, required this.casa});

  final Casa casa;

  static const _condiciones = {
    'oxigeno': 'Usa oxígeno',
    'hipertension': 'Hipertensión',
    'diabetes': 'Diabetes',
    'caidas': 'Se cae seguido',
  };

  @override
  Widget build(BuildContext context) {
    final contactos = [...casa.contactos]
      ..sort((a, b) => a.orden.compareTo(b.orden));
    const titulo = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: Colors.black87,
    );

    return Scaffold(
      backgroundColor: Colores.papel,
      appBar: AppBar(
        backgroundColor: Colores.papel,
        foregroundColor: Colors.black87,
        title: Text(
          'Casa de ${casa.nombre}',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
        children: [
          const Text(
            'LO HACE EL FAMILIAR',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colores.textoGris,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: casa.nombre,
            style: const TextStyle(fontSize: 18),
            decoration: const InputDecoration(
              labelText: 'Cómo la llamamos',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          const Text('A quién avisamos, en orden', style: titulo),
          const SizedBox(height: 8),
          for (final contacto in contactos)
            Card(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: Colores.borde, width: 1.5),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colores.verde,
                  foregroundColor: Colors.white,
                  child: Text(
                    '${contacto.orden}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                title: Text(
                  '${contacto.nombre}, ${contacto.relacion}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  '${contacto.donde} · ${contacto.canal == Canal.whatsapp ? 'WhatsApp y la web' : 'llamada en altavoz'}',
                ),
              ),
            ),
          const SizedBox(height: 20),
          const Text('Su salud cambia qué es urgente', style: titulo),
          const SizedBox(height: 4),
          for (final MapEntry(key: clave, value: texto) in _condiciones.entries)
            CheckboxListTile(
              value: casa.condiciones.contains(clave),
              onChanged: (_) {},
              title: Text(texto, style: const TextStyle(fontSize: 17)),
              activeColor: Colores.verde,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colores.borde, width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 92,
                  height: 92,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colores.textoGris, width: 2),
                  ),
                  child: const Text(
                    '[QR]',
                    style: TextStyle(color: Colores.textoGris),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Quien escanee este código ve la casa de ${casa.nombre} desde su teléfono',
                    style: const TextStyle(fontSize: 16, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 60,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colores.verde,
                textStyle: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  fontFamily: fuente,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Empezar a cuidar'),
            ),
          ),
        ],
      ),
    );
  }
}
