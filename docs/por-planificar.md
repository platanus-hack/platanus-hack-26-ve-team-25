# Por planificar

> Lo que Abrahan quiere agregar y que vamos pensando de a poco, antes de construirlo. Cada punto
> dice qué se quiere, qué se puede hacer de verdad y qué falta decidir. Cuando un punto se decide,
> pasa a [pendientes.md](pendientes.md) si entra en el hackatón, o a [futuro.md](futuro.md) si es
> proyección. Lo construido de verdad está en la tabla de estado de [AGENTS.md](../AGENTS.md).
>
> Empezado el sábado 24-oct a las 13:00.

| # | Punto | Tipo | Estado |
|---|---|---|---|
| 1 | [Proyección: seguros, ficha médica, farmacia, 911 y ambulancia](#1-proyección-para-el-pitch) | Pitch | Casi todo ya está en futuro.md |
| 2 | [Tres vistas: de mesa, personal y familia](#2-tres-vistas-y-cómo-se-conectan) | Producto | Por decidir |
| 3 | [Mejorar los mockups de la vista de mesa](#3-mejorar-los-mockups-de-mesa) | Diseño | Por hacer |
| 4 | [Cámara y fotos que la IA describe](#4-cámara-y-fotos-que-la-ia-describe) | Producto e investigación | Investigar permisos primero |
| 5 | [Altavoz y volumen al máximo en la llamada](#5-altavoz-y-volumen-al-máximo-en-la-llamada) | Técnico | Se puede probar ya |
| 6 | [Que el teléfono del hijo suene aunque esté en silencio](#6-que-el-teléfono-del-hijo-suene-aunque-esté-en-silencio) | Técnico | Depende del punto 2 |
| 7 | [Probar y afinar las IAs: voz y OCR](#7-probar-y-afinar-las-ias-voz-y-ocr) | Prueba | Por hacer |

## 1. Proyección para el pitch

**Qué se quiere:** contar que la app se puede conectar con seguros médicos, guardar la
información médica del abuelo, comprar las medicinas por una farmacia como Farmatodo y, en una
emergencia grave, llamar al 911 o a una ambulancia de una sola vez.

**Qué hay:** casi todo ya está en [futuro.md](futuro.md#conectar-con-quien-atiende): la ficha de
emergencia, pedir la ambulancia, las pastillas a domicilio y las aseguradoras como canal. El
inventario de pastillas ya calcula cuándo comprar y deja el enganche en `pedido()` de
[`inventario.ts`](../web/src/lib/familia/inventario.ts).

**Lo nuevo del sábado 24:** Farmatodo no tiene una API gratis, y Yummy tampoco tiene una que se
pueda usar. Queda como proyección, no como demo.

- [ ] Agregar a futuro.md lo de Farmatodo y Yummy, y que el 911 y la ambulancia salgan **en una
      sola acción** cuando la emergencia es grave (no un paso después del otro).
- [ ] Decidir qué de esto se dice en el pitch y en qué orden. Hoy futuro.md lo ordena en tres
      pasos: lo que se ve en el demo, conectar con quien atiende, y la app de cuidado completa.

## 2. Tres vistas y cómo se conectan

**Qué se quiere:**

- **De mesa** (nombre interno): el teléfono viejo, fijo en la casa. Es la app de hoy.
- **Personal:** el teléfono que el abuelo usa y lleva encima.
- **Familia:** la web de la familia de hoy, pero como app, reutilizando sus pantallas.

**Propuesta: dos roles de persona y tres vistas.** Los roles son quién es la persona (el que es
cuidado y el que cuida). Las vistas son qué hace cada teléfono. El abuelo es un solo rol con dos
vistas, porque sus dos teléfonos hacen cosas distintas:

| Vista | Rol | Teléfono | Qué hace |
|---|---|---|---|
| De mesa | Persona cuidada | Android viejo, enchufado, siempre en pantalla | Oye la casa, pregunta «¿Está bien?», recuerda las pastillas, llama. Es el centro de la casa |
| Personal | Persona cuidada | El suyo, que lleva encima | «Pedir ayuda» grande, la pastilla, tomar una foto, y a futuro la caída por acelerómetro ([futuro.md](futuro.md#cobertura-de-la-casa)). No oye todo el día: gastaría su batería |
| Familia | El que cuida | El del hijo, muchas veces en otro país y con iPhone | Ver cómo está, recibir la alerta, llamar, «Ya hablé con ella», las pastillas y la compra |

**Cómo se mantiene la conexión:**

- **La casa es el centro, y cada teléfono es un dispositivo de la casa.** Hoy la casa tiene una
  sola clave. Con dos teléfonos del abuelo hace falta una tabla de dispositivos: cada uno con su
  tipo (mesa o personal), su propia clave en hash y su propio latido. Así se puede apagar uno
  sin tocar el otro, y la familia ve cuál dejó de reportar.
- **Se emparejan con un QR que muestra el de mesa**, como ya hace la invitación de la familia.
  Nadie escribe claves. **Decidido por Abrahan el sábado 24:** todo tiene que ser lo más
  sencillo posible para el abuelo, y el QR es eso.
- **Supabase sigue siendo la única fuente de verdad.** Los dos teléfonos del abuelo escriben
  eventos y alertas a la misma casa, y la misma alerta se ve en todos. Si el personal pide ayuda,
  el de mesa también lo muestra.
- **Del sondeo a los avisos.** Hoy la web pregunta cada 5 s. Para que el teléfono del hijo se
  entere con la app cerrada hacen falta notificaciones push (Firebase en Android, APNs en iPhone),
  que es justo lo que pide el punto 6.
- **Sin internet**, cada teléfono guarda en cola, como ya hace el de mesa
  ([`nube.dart`](../app/lib/datos/nube.dart)).

**Reutilizar las pantallas de la web:** la web es Next.js y la app es Flutter, así que no se
copian tal cual. Hay tres caminos:

| Camino | A favor | En contra |
|---|---|---|
| La familia sigue siendo la web instalable (PWA) | Ya está hecha, sirve en iPhone sin App Store | La web no puede hacer sonar el teléfono en silencio (punto 6) |
| App Flutter que muestra la web adentro (WebView) y agrega lo nativo | Reutiliza las pantallas y suma push y sonido fuerte | Dos tecnologías en la misma app |
| Pasar las pantallas de la familia a Flutter | Una sola app para las tres vistas, como dice futuro.md | Rehacer lo que ya funciona |

- [x] Emparejar los teléfonos con un QR.
- [ ] Decidir si son dos roles o tres. Propuesta: dos roles y tres vistas.
- [ ] Diseñar el emparejamiento: quién muestra el QR, quién lo escanea, y qué pasa si se pierde
      un teléfono (revocar su clave sin tocar los demás).
- [ ] Decidir el camino de la vista de familia. Para el hackatón, la web como está. Para el
      producto, depende del punto 6.
- [ ] Qué tiene la vista personal además de «Pedir ayuda», y si tiene que funcionar en iPhone.
- [ ] Mockups de la vista personal y de la familia como app.

## 3. Mejorar los mockups de mesa

**Qué se quiere:** la vista de mesa son los mockups del
[lienzo](https://claude.ai/artifact/BgbTMPcFXsC9qxitsmk1f2), y hay que mejorarlos.

**Ojo:** el código ya cambió el sábado: «Pedir ayuda» ocupa el panel derecho, las pastillas van
chicas con «Leer récipe», «Huele a gas» y «Me siento mal» se dicen en voz alta, y el
recordatorio solo se quita con «Ya me la tomé». El lienzo no tiene nada de eso todavía.

- [ ] Pasar al lienzo lo que ya está en el código.
- [ ] Anotar qué no le gusta a Abrahan de cada pantalla.

## 4. Cámara y fotos que la IA describe

**Qué se quiere:**

- Si el abuelo no apagó el recordatorio de la primera pastilla del día, el teléfono de mesa
  graba un video corto y una IA lo describe con un prompt: si hay alguien en el suelo, por ejemplo.
- Desde el teléfono personal, tomar una o dos fotos que la IA también describe.
- Que la IA diga en voz alta lo que ve, para el servicio de emergencia o para el familiar.

**Primero los permisos y la privacidad, como pidió Abrahan.** Lo que se sabe:

| Dónde | Cámara sin que nadie la toque | Qué hace falta |
|---|---|---|
| Android, teléfono de mesa | Sí, si la app está en pantalla, que es el caso del de mesa | Permiso de cámara. Desde Android 11 no se puede abrir la cámara con la app en segundo plano, y desde Android 14 un servicio con cámara necesita el tipo `camera`. Android 12 y posteriores muestran un punto verde mientras la cámara está prendida, y no se puede esconder |
| Android, teléfono personal | Solo con la app abierta | Lo normal es que el abuelo toque «Tomar foto» |
| iPhone | No: iOS nunca deja usar la cámara en segundo plano | La persona abre la app y toca |
| Web instalable (PWA) | Solo con la página abierta y en pantalla, en Android y en iPhone | `getUserMedia` o el selector de fotos. Sirve para «tomar una foto», no para grabar sola |

**Lo que choca con una decisión que ya tomamos:** el audio nunca sale del teléfono
([AGENTS.md](../AGENTS.md)), y futuro.md propone que la imagen tampoco salga («un modelo de pose
en el teléfono»). Mandar el video a una IA en la nube rompe esa regla. Hay opciones intermedias:

- Un modelo de pose en el teléfono decide si hay alguien en el suelo, y solo esa etiqueta sale.
- Solo sale una foto, no un video, y solo cuando la alerta ya escaló, para quien atiende.
- Que la familia lo active a sabiendas y que el abuelo sepa que existe.

- [ ] Investigar: la ley y el consentimiento en Venezuela, y qué pide Google Play para una app
      que usa la cámara sin que la toquen.
- [ ] Decidir qué sale del teléfono: nada, una etiqueta, una foto o un video.
- [ ] Decidir qué IA describe la imagen (Claude ya lee las facturas) y con qué voz habla (la voz
      del teléfono o una de la nube).
- [ ] Qué hacer con la imagen después: cuánto se guarda y quién la ve.

## 5. Altavoz y volumen al máximo en la llamada

**Qué se quiere:** que la llamada de emergencia salga en altavoz sola, o que se active por voz, y
con el volumen al máximo. Así, si el abuelo está en el suelo lejos del teléfono, igual puede
hablar.

**Qué se puede:**

- **Llamada telefónica normal:** Android tiene un extra para pedir el altavoz al iniciar la
  llamada (`TelecomManager.EXTRA_START_CALL_WITH_SPEAKERPHONE`). Respetarlo depende de la app de
  teléfono de cada marca: hay que probarlo en el Infinix. El volumen de la llamada se puede subir
  al máximo desde la app (`AudioManager.setStreamVolume`).
- **Lo seguro en el teléfono de mesa:** que la app sea la app de teléfono predeterminada. Como es
  un teléfono dedicado, se puede, y entonces la app controla el altavoz de toda llamada.
- **Llamada de WhatsApp:** WhatsApp no deja que otra app le prenda el altavoz. Se podría con un
  servicio de accesibilidad que toque el botón, pero es frágil y Google Play lo revisa con lupa.
- **Por voz:** Vosk ya escucha frases; se puede agregar «altavoz» al banco. Pero durante una
  llamada el micrófono lo tiene la llamada, así que hay que probar si Vosk sigue oyendo.

- [ ] Probar el extra de altavoz y el volumen máximo en el Infinix. Es poco código y se puede
      hacer ya.
- [ ] Decidir si la emergencia sale por llamada normal en altavoz, o por WhatsApp sin altavoz.
      Hoy sale primero por WhatsApp.

## 6. Que el teléfono del hijo suene aunque esté en silencio

**Qué se quiere:** cuando llame el teléfono de mesa o el del abuelo, que el teléfono del hijo
suene al máximo aunque esté en silencio. Si una app no puede hacerlo, configurar ese número como
contacto de emergencia, como las rutinas de Samsung.

**Qué se puede:**

| Dónde | Con una app propia | Sin app, solo configurando el teléfono |
|---|---|---|
| Android | La alerta suena como alarma, que se oye aunque el teléfono esté en silencio, y la persona puede dejar que salte el «No molestar» | Agregar el número a favoritos y permitir sus llamadas en «No molestar». En Samsung, una rutina de Modos y rutinas: «si llama este número, volumen al máximo» |
| iPhone | Las «alertas críticas» suenan en silencio, pero Apple tiene que aprobar la app (las da a apps de salud y seguridad) | En Contactos, el tono del contacto tiene «Omitir modo silencioso» (Emergency Bypass): suena aunque el iPhone esté en silencio o en Concentración |
| Web (PWA) | No: una notificación web nunca salta el silencio | — |

**Las alertas críticas de Apple, en detalle:** sí se pueden, con tres condiciones. Una app
nativa de iPhone (no la web), la cuenta de Apple Developer ($99 al año) y un formulario en que
Apple decide si la aprueba. Las da a apps de salud, médicas, de seguridad del hogar y de
seguridad pública; esta encaja, pero no hay garantía y puede tardar semanas. Aun aprobada, el
iPhone le pregunta al hijo si las permite, aparte del permiso normal de notificaciones.

**Samsung, en detalle:** no tiene un «Omitir modo silencioso» por contacto como el iPhone. Lo
que sí tiene:

- **Modos y rutinas** (One UI 5 o posterior; antes se llamaba Rutinas de Bixby): una rutina «si
  entra una llamada de este contacto, el modo de sonido pasa a sonido y el volumen al máximo».
  Hay que comprobar en un Samsung real que la condición deja elegir el contacto, porque cambia
  entre versiones.
- **No molestar → excepciones:** deja pasar las llamadas de los favoritos y las repetidas. Eso
  salta el «No molestar», pero **no** el modo silencio ni el de vibración.

Lo que sí sirve **en todos los Android, Samsung incluidos**, es una app propia para la familia:
la alerta suena por el canal de alarma, que Android hace sonar aunque el teléfono esté en
silencio o en vibración, y con el permiso de «No molestar» que da el hijo una vez, también salta
ese modo. Es lo mismo que hacen los despertadores.

**Conclusión:** lo que sirve ya, sin escribir código, es una **guía al invitar a la familia**:
«guarda este número y márcalo como emergencia». Con instrucciones para iPhone, Android y Samsung.
Para hacerlo desde la app, la familia necesita una app nativa: eso empuja el punto 2 hacia una
app de verdad para la familia.

- [ ] Agregar la guía a la invitación (`/f/[token]/bienvenida`): guardar el número de la casa y
      ponerlo como emergencia.
- [ ] Probar «Omitir modo silencioso» en un iPhone y la rutina en un Samsung.
- [ ] Decidir si se pide la aprobación de Apple para alertas críticas (después del hackatón).
- [ ] Probar en un Samsung que Modos y rutinas deja elegir el contacto que llama.

## 7. Probar y afinar las IAs: voz y OCR

**Qué se quiere:** agregar las IAs, probar que funcionan y afinarlas. Es trabajo de prueba y
ajuste, no de construir de cero.

**Lo que ya existe:**

| IA | Dónde | Qué falta probar |
|---|---|---|
| YAMNet: los sonidos de la casa | [`oido.dart`](../app/lib/oido/oido.dart) | Alarma, vidrio, golpe, grito y quejido en el teléfono real, con la TV prendida |
| Vosk: las frases de ayuda, sin internet | [`pedidos.dart`](../app/lib/dominio/pedidos.dart), [`Frases.kt`](../app/android/app/src/main/kotlin/ve/equipo25/casa/Frases.kt) | Qué palabras del banco no conoce el modelo, cuántos falsos positivos da la TV y si 0,6 es buen umbral de confianza |
| Reconocimiento de voz de Android: «¿Pudo hablar con…?» | [`voz.dart`](../app/lib/datos/voz.dart) | «Sí» y «no» con y sin internet |
| Claude: leer la factura | `web/` (lo hizo la sesión de facturas) | Facturas de verdad de Farmatodo y Locatel, fotos torcidas o con poca luz |
| Claude: leer el récipe | Por hacer: hoy se carga con un script | Letra de médico a mano |

- [ ] Medir cada una con un conjunto chico de pruebas propio (por ejemplo, 20 frases dichas por
      personas mayores y 10 facturas), anotando aciertos y errores. Nada de eso va al repo:
      es público y son voces y datos reales.
- [ ] Con voces mayores de verdad, como pide [pendientes.md](pendientes.md#probar-con-voces-mayores--abrahan).
