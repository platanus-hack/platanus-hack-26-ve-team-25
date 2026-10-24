# App de la casa (Flutter, Android)

El teléfono viejo que queda enchufado y **acostado como reloj de mesa** en la casa del adulto
mayor. Las pantallas son las de los mockups horizontales aprobados. Hoy tiene:

- **El oído:** micrófono → nivel y compuerta → YAMNet en el teléfono, en otro isolate. Si oye una
  alarma, un vidrio, un golpe, un grito o un quejido, pregunta «¿Está bien?». El audio entra crudo
  (fuente `UNPROCESSED`) y nunca sale del teléfono.
- **La alerta:** una máquina de estados en Dart puro. «Estoy bien» se desliza para no apagarla por
  reflejo; «Necesito ayuda» es un toque.
- **El reposo:** el reloj grande y, a la derecha, «Pedir ayuda» de arriba abajo. Abajo, en chico,
  la pastilla que le toca o la próxima, y «Leer récipe», que todavía solo dice que no está lista.
- **Pedir en voz alta:** cuando YAMNet oye hablar a alguien (y no es la TV), Vosk lee los últimos
  5 s del mismo anillo de audio y busca un banco de unas 70 frases
  ([`pedidos.dart`](lib/dominio/pedidos.dart)): «huele a gas», «me siento malita», «no me puedo
  parar», «llamen a mi hijo»… El banco es la gramática de Vosk, así que solo reconoce esas
  palabras, y descarta las de confianza menor a 0,6. No pausa el oído ni pierde la primera frase.
  Lo que se pide abre «¿Está bien?» con ese motivo en vez de llamar directo: si era la TV, se apaga
  deslizando. El modelo chico de español de Vosk (Apache 2.0, ~40 MB) no va en git: lo baja
  `make deps` con [`tool/descargar_vosk.sh`](tool/descargar_vosk.sh). El lado nativo está en
  [`Frases.kt`](android/app/src/main/kotlin/ve/equipo25/casa/Frases.kt).
- **Órdenes por voz:** «Lucero, llama a mi hijo», «… al vecino» o «… a emergencias». La pantalla
  cuenta 5 s y se cancela con «No llamar» o diciendo «no». Al hijo lo llama por WhatsApp primero;
  al vecino y a emergencias, por llamada normal en altavoz y con el volumen al máximo. Sin
  «Lucero» no llama: puede ser la TV. Los números van en `config/local.json`
  (`TELEFONO_VECINO`, `NUMERO_EMERGENCIAS`); para probar, nunca el 911 de verdad.
- **La alarma de «¿Está bien?»:** un tono de 520 Hz en onda cuadrada, que las personas mayores
  oyen mejor que un pitido agudo, con el ritmo de las alarmas de humo, y vibración. Cada dos
  ciclos la voz del teléfono dice «Carmen, ¿está bien? Si está bien, deslice el botón», y a 20 s
  del final, a quién va a llamar. Suena por el canal de alarma, aunque el teléfono esté en
  silencio.
- **La rutina:** cuenta lo de siempre que suena por franja del día (cocina, agua, puerta, baño,
  TV, voces) y lo manda como «Su día» a la familia, una vez por hábito y franja. Si de día no suena
  nada en 3 horas, avisa una vez como «día distinto» ([`rutina.dart`](lib/dominio/rutina.dart)).
- **El recordatorio de la pastilla:** en toda la pantalla, y solo se quita con «Ya me la tomé»,
  con el botón o en voz alta.
  Si pasan 2 horas se va solo y queda como olvidada, para no empujar a tomar dos dosis.
- **Las pastillas del día:** a la hora, una pantalla verde la recuerda («Es hora de la losartán»)
  con la pastilla dibujada en sus colores. Pasadas 2 horas sin tomarla queda como olvidada.
- **La llamada de emergencia:** al escalar, la casa llama al primer contacto, una sola vez,
  **primero por WhatsApp**, porque los hijos suelen estar fuera del país. Si no se puede, hace una
  llamada telefónica normal. WhatsApp no tiene una vía oficial para esto: la app abre la fila de
  «llamada de voz» que WhatsApp crea en la agenda, así que **el contacto tiene que estar guardado
  en los contactos del teléfono de la casa** y la app pide permiso para leerlos
  ([futuro.md](../docs/futuro.md)).
- **Si no contestan el WhatsApp:** Android no dice si contestaron, solo cuánto duró la llamada,
  timbre incluido. Si terminó en menos de 10 s (rechazada o sin internet), la app llama por
  teléfono de inmediato. Si duró más, la app vuelve sola al frente y pregunta «¿Pudo hablar con
  Josuep?»; si nadie toca «Sí, ya hablamos» en 15 s, llama por teléfono. Volver sola al frente
  necesita el permiso «Mostrar sobre otras apps», que la app pide al abrirse.
- **Se puede contestar por voz:** mientras pregunta «¿Pudo hablar con Josuep?», la app pausa el
  oído y escucha. «Sí» o «ya hablamos» cierra la alerta; «no» llama por teléfono sin esperar. Si no
  entiende, sigue la cuenta regresiva y la llamada sale igual: el botón sigue estando. Usa el
  reconocimiento de voz del teléfono, sin internet si tiene descargado el paquete de español.

- **Le cuenta a Supabase lo que pasa** ([`nube.dart`](lib/datos/nube.dart)): cada alerta manda
  su evento y la alerta (`casa_evento`, `casa_alerta`), cada cambio de estado la respuesta
  (`casa_responder`) y cada 90 s un latido con la batería y si está enchufado (`casa_latido`). Si
  no hay internet, lo guarda en orden y reintenta cada 10 s, con la hora real del evento. La cola
  vive en memoria: si la app se cierra sin internet, se pierde. Necesita `SUPABASE_URL`,
  `SUPABASE_PUBLISHABLE_KEY` y `CASA_CLAVE` en `config/local.json`; sin eso no escribe.

Falta el aviso por WhatsApp a la familia, el tono de 520 Hz, la vibración y cargar las pastillas desde
la foto del récipe: ver [docs/pantallas.md](../docs/pantallas.md).

## Correrla en un Android

`make run` busca solo el teléfono Android conectado por adb; si no hay ninguno, lo dice y no
compila (antes compilaba para Linux de escritorio y fallaba). **`make logs`** muestra en vivo el
log de la app, se vuelve a enganchar si la app se reinicia, avisa si Android la cierra o dice que
no responde, y guarda una copia en `app/build/logs/`. Cada minuto aparece una línea
`casa.salud` (escuchas del oído, cola y alerta), y cada reconocimiento de Vosk dice cuánto tardó
(`casa.vosk`).

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

## Verla en el navegador

https://platanus-hack-26-ve-team-25-casa.vercel.app es la misma app compilada para web e
instalable desde el navegador. Sirve para ver y probar las pantallas sin un Android, con los mismos
toques largos de abajo. **No oye ni llama:** TFLite usa `dart:ffi`, que no existe en el navegador,
así que la web compila contra [`lib/oido/tflite_web.dart`](lib/oido/tflite_web.dart), una versión
vacía. Tampoco lleva el número de emergencia, porque el sitio es público.

`make casa-deploy` la publica. Vercel no trae Flutter: [`tool/vercel_build.sh`](tool/vercel_build.sh)
baja la misma versión del equipo (3.47.5) y compila allá, así que no hace falta Flutter en la
laptop. Con Flutter instalado, `make casa-web` la arma en `build/web`.

## Cómo probar las pantallas

El oído ya escucha. Además hay dos toques largos de prueba:

| Gesto | Qué hace |
|---|---|
| Hacer sonar una alarma, romper algo o gritar cerca | El oído lo detecta y abre «¿Está bien?» |
| Mantener presionado el reloj | Simula una alarma de humo sin hacer ruido |
| Mantener presionado «Cuidando la casa» | Abre la configuración, que en el producto usa el familiar |
| Mantener presionado «Pastillas de hoy» | Recuerda ya la próxima pastilla, sin esperar a su hora |
| Tocar «Pedir ayuda» | No espera los 60 s: llama al primer contacto y abre la pantalla de ayuda |
| Decir «me huele a gas», «me siento mal» o «ayuda» | Abre «¿Está bien?» con ese motivo, 1,5 s después de terminar la frase |
| Decir «Lucero, llama a mi hijo» (o «al vecino», «a emergencias») | Cuenta 5 s y llama. «No» lo cancela |
| En «¿Está bien?», decir «Lucero, estoy bien» | Calla la alarma, como deslizar. Si ya estaba llamando, cierra el aviso |
| En «¿Está bien?», decir «ayuda», «me caí» o «no» | Llama al hijo de una vez |

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
