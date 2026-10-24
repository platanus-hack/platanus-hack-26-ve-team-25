// TFLite usa dart:ffi, que no existe en el navegador. Esta versión vacía deja compilar la app
// para la web instalable (la vista previa de las pantallas): ahí el oído no arranca y la alarma
// se prueba con el toque largo sobre el reloj. En Android se usa tflite_flutter de verdad.

class InterpreterOptions {
  int threads = 1;
}

class Interpreter {
  Interpreter._();

  static Future<Interpreter> fromAsset(
    String asset, {
    InterpreterOptions? options,
  }) => throw UnsupportedError('YAMNet con TFLite no corre en el navegador');

  int get address => 0;

  void close() {}
}

class IsolateInterpreter {
  IsolateInterpreter._();

  static Future<IsolateInterpreter> create({required int address}) =>
      throw UnsupportedError('YAMNet con TFLite no corre en el navegador');

  Future<void> run(Object entrada, Object salida) async {}

  Future<void> close() async {}
}
