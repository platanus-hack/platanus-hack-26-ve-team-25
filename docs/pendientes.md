# Pendientes

Lo que falta para el demo del domingo, en orden. Escrito el sábado 24-oct a las 07:00. Cada punto
dice dónde está el código, qué falta y cómo saber que quedó. Quien tome uno, que ponga su nombre
y lo tache al terminar. Las preguntas de investigación por persona siguen en
[investigacion.md](investigacion.md), y lo que va después del hackatón, en [futuro.md](futuro.md).

## Estado al cerrar la noche

- **App de la casa ([`app/`](../app/README.md)):** está en horizontal como reloj de mesa. Ya
  oye con YAMNet en el teléfono, pregunta «¿Está bien?» con deslizador, llama primero por WhatsApp
  y si no por teléfono, y si no contestan el WhatsApp pregunta «¿Pudo hablar con…?» por botón o
  por voz. Recuerda las pastillas del día. Tiene 51 pruebas. **Nada de eso se ha probado todavía
  en un teléfono real con sonidos, llamadas o voz de verdad.**
- **Web de la familia:** solo existen la prueba `/escucha` y el manifiesto instalable. Las
  pantallas de la familia están diseñadas en el lienzo, pero no programadas.
- **Supabase y Telegram:** nada todavía.
- **Lienzo de mockups:** [claude.ai/artifact/BgbTMPcFXsC9qxitsmk1f2](https://claude.ai/artifact/BgbTMPcFXsC9qxitsmk1f2).

## P0: sin esto no hay demo

### 1. Probar la app en el teléfono real · *quien tenga el Android*

Se instala con `make run` desde la raíz. Antes hay que copiar
`app/config/local.example.json` a `app/config/local.json` y poner el número de emergencia: ese
archivo no se sube, porque el repo es público.

- [ ] Aceptar los permisos al abrir: micrófono, llamadas, contactos y «Mostrar sobre otras apps».
      El último abre una pantalla de ajustes aparte.
- [ ] **El oído:** alarma de humo (un video de YouTube), un vaso que se rompe, un golpe, un grito
      y la TV. En modo debug, debajo de la fecha se ve qué oye y con qué puntaje.
- [ ] **WhatsApp:** guardar el número de emergencia en los contactos del teléfono, con WhatsApp.
      Tocar «Pedir ayuda»: tiene que abrirse una llamada de voz de WhatsApp, no el chat. Avisarle
      antes a la persona a la que se llama.
- [ ] **Si no contestan:** dejar timbrar sin contestar. Al terminar, la app tiene que volver sola
      al frente con «¿Pudo hablar con…?» y, a los 15 s, llamar por teléfono normal.
      **Es lo más incierto:** Android 16 restringe que una app se abra sola desde segundo plano,
      y no se ha comprobado. Si no vuelve, revisar `terminar()` en
      [`MainActivity.kt`](../app/android/app/src/main/kotlin/ve/equipo25/casa/MainActivity.kt).
- [ ] **Si WhatsApp falla:** borrar el contacto de la agenda y repetir. Tiene que llamar por
      teléfono directo.
- [ ] **Por voz:** en «¿Pudo hablar con…?», decir «sí» (cierra) y «no» (llama por teléfono). Probar
      con wifi y sin wifi.
- [ ] **Pastillas:** mantener presionado «Pastillas de hoy» para forzar el recordatorio, y probar
      «Ya la tomé» y «Recuérdame en 10 min».
- [ ] Anotar aquí lo que falló, con el modelo del teléfono y su versión de Android.

### 2. Pasar a Flutter el reposo nuevo · *por asignar*

En el lienzo, la pantalla «Casa · En reposo» ya tiene el diseño nuevo: un **listón de la
pastilla arriba**, el **reloj centrado** y más arriba que abajo, y **solo «Pedir ayuda»**,
grande. Abrahan pidió verlo; **falta que lo apruebe** antes de programarlo.

- [ ] Que Abrahan apruebe el mockup.
- [ ] Reescribir [`app/lib/ui/reposo.dart`](../app/lib/ui/reposo.dart) con ese diseño.
- [ ] **Decidir con el equipo** qué pasa con «Huele a gas» y «Me siento mal»: el mockup nuevo los
      quita, pero «la persona como sensor» es una decisión de [contexto.md](contexto.md). Si se
      quitan, actualizar esa decisión y [preguntas-tecnicas.md](preguntas-tecnicas.md).
- [ ] Dejar los toques largos de prueba (reloj → alarma, «Pastillas de hoy» → recordatorio) y
      actualizar las pruebas de [`widget_test.dart`](../app/test/widget_test.dart).

### 3. Supabase: que la casa y la familia hablen · *Josuep, alertas y conexión*

El contrato de datos ya existe en Dart ([`tipos.dart`](../app/lib/dominio/tipos.dart),
[`alerta.dart`](../app/lib/dominio/alerta.dart)) y está descrito en
[pantallas.md](pantallas.md#el-contrato-la-misma-forma-en-dart-y-en-typescript).

- [ ] Tablas `casas`, `invitaciones`, `eventos`, `alertas` y `latidos`.
- [ ] El paso de «pendiente» a «escalada» de una alerta, con una sola escritura que gane
      (`escalar_alerta()`).
- [ ] **Seguridad:** el enlace de invitación lleva un token aleatorio de al menos 128 bits, guardado
      en hash, y reglas RLS para que cada token vea solo su casa. Lo va a preguntar el jurado.
- [ ] La app de la casa manda eventos, alertas y el latido, con una cola local si no hay internet.
- [ ] Decidir el latido y quién declara «sin señal»
      ([investigacion-alertas.md](investigacion-alertas.md#el-dead-mans-switch-pendiente-de-decidir)).

### 4. Telegram · *Josuep*

- [ ] Crear el bot y una Edge Function de Supabase que mande la alerta 🔴. La llave del bot vive
      en Supabase, nunca en el repo.
- [ ] El botón «Recibir avisos en Telegram» de la pantalla de invitación tiene que enlazar el chat
      con la casa.

### 5. La web de la familia · *Rogelio*

Las pantallas están en el lienzo, en la fila «Teléfono de la familia». El plan de estructura está
en [pantallas.md](pantallas.md#web-de-la-familia-nextjs-en-web).

- [ ] `/f/[token]`: todo bien, alerta urgente, para saber y sin señal, según los datos.
- [ ] La invitación que se ve al escanear el QR, con «Recibir avisos en Telegram».
- [ ] `/demo`, con el QR gigante para el público.
- [ ] La raíz lleva a la última casa abierta, para que la web instalada no abra la plantilla.
- [ ] Escenarios simulados por URL (`?escenario=alerta`) como respaldo del demo.

## P1: si P0 está listo

- [ ] **El tono de 520 Hz y la vibración** en «¿Está bien?»
      ([investigacion-audio.md §1.1](investigacion-audio.md)). Ya está marcado «Por hacer» en
      [`alarma.dart`](../app/lib/ui/alarma.dart).
- [ ] **Que la app no se muera:** servicio en primer plano tipo `microphone` con
      `flutter_foreground_task`, pantalla encendida mientras carga y la app como pantalla de
      inicio ([riesgos.md §3](riesgos.md)).
- [ ] **Pastilla olvidada:** si pasan 2 horas sin «Ya la tomé», aviso 🟡 a la familia. La lógica ya
      existe (`EstadoToma.olvidada` en [`pastillas.dart`](../app/lib/dominio/pastillas.dart)); falta
      mandarlo.
- [ ] **Las pastillas desde la foto del récipe:** la familia sube la foto en la web, Claude la lee
      y la familia confirma antes de guardar. Hoy las pastillas son datos inventados en
      [`simulado.dart`](../app/lib/datos/simulado.dart).
- [ ] **La rutina:** conteos de qué suena en cada franja del día, y aviso si falta lo de siempre.
- [ ] **Configuración que guarde de verdad,** con el QR real de invitación.
- [ ] Un `make demo` que levante la web y la conecte con el teléfono (`adb reverse tcp:3000
      tcp:3000`), para probar los avisos sin desplegar.

## Probar con voces mayores · *Abrahan*

- [ ] Clips de Common Voice de 60 años o más contra clips de 20: ¿YAMNet ve la voz igual?
- [ ] Notas de voz donadas: la meta es 10 personas, y el mensaje para pedirlas está en
      [investigacion-audio.md](investigacion-audio.md).
- [ ] Medir en el teléfono viejo cuánto tarda YAMNet por ventana, y cuánta batería y calor gasta.
- [ ] Si sobra tiempo: probar sherpa-onnx CED con ventanas de 5 s, que en la comparación acertó
      más ([experimentos/modelos-audio](../experimentos/modelos-audio/README.md)).

## Para el pitch y el jurado

- [ ] **Cifras con fuente** ([investigacion.md](investigacion.md#anttony--antecedentes-y-usuarios)).
- [ ] **El nombre del producto.** Hoy la web instalable dice «En casa» de relleno
      ([`web/src/lib/app.ts`](../web/src/lib/app.ts)) y la app, «Casa».
- [ ] Actualizar [preguntas-tecnicas.md](preguntas-tecnicas.md) con lo que ya pasó a código: el
      oído en el teléfono, la llamada por WhatsApp y su respaldo, y la respuesta por voz.
- [ ] Que la tabla de estado del README y la de [AGENTS.md](../AGENTS.md) digan lo mismo que el
      código.
- [ ] Contar las limitaciones en voz alta ([riesgos.md](riesgos.md#cómo-contar-la-verdad)): la
      llamada de WhatsApp va por una vía no oficial, y Android no dice si la contestaron.
- [ ] En el lienzo, la fila «Teléfono de la casa de pie» es la versión anterior: se puede borrar.
- [ ] Llave propia para firmar el App Bundle, si se quiere subir a Google Play.
