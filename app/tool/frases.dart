// Imprime la gramática de Vosk (las frases del banco y las órdenes) como JSON, para revisar con el
// modelo qué palabras no conoce. Uso: dart run tool/frases.dart. Revisado el sábado 24 con el
// modelo vosk-model-small-es-0.42: solo faltaba «mareé», que se sacó del banco.
import 'dart:convert';
import 'dart:io';

import 'package:casa/dominio/comandos.dart';
import 'package:casa/dominio/pedidos.dart';

void main() =>
    stdout.writeln(jsonEncode([...todasLasFrases, ...frasesDeOrdenes]));
