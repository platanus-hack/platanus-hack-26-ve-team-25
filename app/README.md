# App de la casa (Flutter, Android)

El teléfono viejo que queda enchufado en la casa del adulto mayor. Hoy tiene:

- **El oído:** micrófono → nivel y compuerta → YAMNet en el teléfono, en otro isolate. Si oye una
  alarma, un vidrio, un golpe, un grito o un quejido, pregunta «¿Está bien?». El audio entra crudo
  (fuente `UNPROCESSED`) y nunca sale del teléfono.
- **La alerta:** una máquina de estados en Dart puro. «Estoy bien» se desliza para no apagarla por
  reflejo; «Necesito ayuda» es un toque.
- **La llamada de emergencia:** al escalar, la casa hace una llamada telefónica normal y directa al
  primer contacto, una sola vez. WhatsApp queda como opción futura ([futuro.md](../docs/futuro.md)).

Falta Supabase, el aviso por Telegram, el tono de 520 Hz, la vibración y la vista horizontal de
reloj de mesa: ver [docs/pantallas.md](../docs/pantallas.md).

## Correrla en un Android

Desde la raíz del repo hay atajos: `make` muestra todos. Los más usados son `make run`,
`make run-demo`, `make test` y `make build-appbundle`. El App Bundle de release se firma por ahora
con la llave de debug: para subirlo a Google Play hace falta una llave propia.

1. En el teléfono: Ajustes → Acerca del teléfono → tocar 7 veces «Número de compilación». Luego,
   en Opciones de desarrollador, activar «Depuración USB».
2. Conectarlo por USB, aceptar el aviso de depuración y comprobar que aparece:

```bash
flutter devices
```

3. Correr la app (con `r` en la terminal se recargan los cambios al instante):

```bash
flutter run
```

**El número de emergencia** no va en el código, porque el repo es público. Se copia
`config/local.example.json` a `config/local.json` (que git ignora) y se pone el número real. `make run`
lo pasa solo; con `flutter run` directo hay que agregar `--dart-define-from-file=config/local.json`.
Sin número, la app no llama y lo dice en pantalla.

Para el demo, con la cuenta regresiva de 15 s en vez de 60 s:

```bash
flutter run --dart-define=DEMO=true
```

## Cómo probar las pantallas

El oído ya escucha. Además hay dos toques largos de prueba:

| Gesto | Qué hace |
|---|---|
| Hacer sonar una alarma, romper algo o gritar cerca | El oído lo detecta y abre «¿Está bien?» |
| Mantener presionado el reloj | Simula una alarma de humo sin hacer ruido |
| Mantener presionado «Cuidando la casa» | Abre la configuración, que en el producto usa el familiar |
| Tocar «Pedir ayuda», «Huele a gas» o «Me siento mal» | No espera los 60 s: llama al primer contacto y abre la pantalla de ayuda |

Si la cuenta regresiva llega a cero, la alerta escala sola y **la casa llama de verdad** al número
configurado. En modo debug, debajo de la fecha se ve lo que oye el modelo y su puntaje.

## Dónde está cada cosa

```text
lib/dominio/tipos.dart      el contrato compartido con la web de la familia
lib/dominio/alerta.dart     la máquina de estados de la alerta, en Dart puro
lib/oido/                   micrófono, nivel, compuerta y YAMNet (la misma lógica que web/src/lib/escucha)
assets/modelos/             YAMNet (Apache 2.0) y sus 521 etiquetas
lib/datos/simulado.dart     la casa inventada de «Carmen»
lib/ui/raiz.dart            elige la pantalla según el estado: no hay menús
lib/ui/                     reposo, alarma («¿Está bien?»), ayuda y configuración
lib/tema.dart               colores y tipografía Atkinson Hyperlegible, que va dentro de la app
test/                       pruebas de la alerta y de las pantallas
```

```bash
flutter analyze
flutter test
```
