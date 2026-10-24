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
- **Web de la familia:** las cuatro pantallas, la invitación y `/demo` con el QR, con datos
  simulados (sábado 08:50).
- **Supabase:** esquema, funciones y casa de demo listos. La app de la casa ya escribe
  (sábado, mediodía), probada contra la base real; falta verlo en el teléfono.
- **WhatsApp:** nada todavía.
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
      «Ya me la tomé», que es la única forma de quitarlo.
- [ ] Anotar aquí lo que falló, con el modelo del teléfono y su versión de Android.

### 2. El reposo nuevo · *Abrahan*

Decidido por Abrahan el sábado 24: **«Pedir ayuda» ocupa el panel derecho** de arriba abajo, las
**pastillas van en chico** abajo del reloj, y al lado un botón chico **«Leer récipe»**.
**«Huele a gas» y «Me siento mal» dejan de ser botones y se dicen en voz alta.**

- [x] [`reposo.dart`](../app/lib/ui/reposo.dart) con ese diseño, con los toques largos de prueba.
- [x] Pedir por voz con Vosk sin internet: banco de ~70 frases en
      [`pedidos.dart`](../app/lib/dominio/pedidos.dart), `_reconocerPedido` en el
      [controlador](../app/lib/ui/controlador.dart) y [`Frases.kt`](../app/android/app/src/main/kotlin/ve/equipo25/casa/Frases.kt).
      Lee el mismo anillo que YAMNet: no lo pausa. Pasa por «¿Está bien?», no llama directo.
- [x] El recordatorio de la pastilla solo se quita con «Ya me la tomé» (sin «más tarde»).
- [x] [contexto.md](contexto.md) actualizado: la persona sigue siendo sensor, por voz.
- [ ] **Probarlo en el teléfono:** decir frases del banco cerca y lejos, con la TV apagada y
      prendida. Mirar en los registros si Vosk ignora palabras que no están en su vocabulario
      («malita»), y ajustar `confianzaMinima` en [`frases.dart`](../app/lib/datos/frases.dart).
- [ ] Probar el banco con voces mayores reales (ver «Probar con voces mayores»).
- [ ] «Leer récipe» abre una pantalla que dice que todavía no está lista: falta la cámara y el
      OCR (ver P1, «Las pastillas desde la foto del récipe»).

### 3. Supabase: que la casa y la familia hablen · *Josuep, alertas y conexión*

El contrato de datos ya existe en Dart ([`tipos.dart`](../app/lib/dominio/tipos.dart),
[`alerta.dart`](../app/lib/dominio/alerta.dart)) y está descrito en
[pantallas.md](pantallas.md#el-contrato-la-misma-forma-en-dart-y-en-typescript).

Esquema aplicado el sábado 09:40: [`supabase/migrations/`](../supabase/migrations/). Las
pruebas contra la base real corren con `cd web && bun run test:integracion`.

- [x] Tablas `casas`, `invitaciones`, `eventos` y `alertas`. El latido es una columna de `casas`
      (`ultimo_latido`), no una tabla: solo importa el último.
- [x] El paso de «pendiente» a «escalada» con una sola escritura que gana (`escalar_vencidas()`).
      Corre además cada vez que alguien lee la casa, así no depende del vigilante.
- [x] **Seguridad:** RLS activado sin políticas: la llave pública no toca las tablas. Todo pasa
      por funciones que piden la clave de la casa o el token de la familia, de 128 bits y
      guardados como hash SHA-256. El token `demo` es público a propósito: es el del QR.
- [x] Casa de demo creada (Carmen, token `demo`). Su clave la tiene Rogelio; va en
      `app/config/local.json` (ver [`local.example.json`](../app/config/local.example.json)).
- [x] **La app de la casa llama a las funciones** (`POST {SUPABASE_URL}/rest/v1/rpc/<nombre>` con
      el header `apikey`): `casa_latido(p_clave, p_enchufado, p_bateria)` cada 90 s,
      `casa_evento(p_clave, p_tipo, p_descripcion)` → id, `casa_alerta(p_clave, p_evento,
      p_espera_s, p_urgente)` → id, `casa_responder(p_clave, p_alerta, 'cancelar' | 'escalar' |
      'atender')`. Ejemplos de uso: [`supabase.integracion.test.ts`](../web/src/lib/familia/supabase.integracion.test.ts).
- [x] La app de la casa manda eventos, alertas y el latido, con una cola en memoria si no hay
      internet ([`nube.dart`](../app/lib/datos/nube.dart), 8 pruebas con una base falsa). El
      latido lee `EXTRA_PLUGGED` en [`MainActivity.kt`](../app/android/app/src/main/kotlin/ve/equipo25/casa/MainActivity.kt),
      como pide [investigacion-carga.md](investigacion-carga.md).
- [x] Probado contra la base real con `make test-integracion` (3 pruebas con una casa de prueba
      que se crea y se borra; usa la llave secreta de `web/.env.local`). La clave de Carmen se
      cambió el sábado 10:30: la nueva está solo en el `app/config/local.json` de Abrahan.
- [ ] **En el teléfono:** `make run`, disparar una alarma (toque largo en el reloj) y ver que
      aparece en `/f/demo`.
- [ ] Guardar la cola en disco: hoy, si la app se cierra sin internet, lo que esperaba se pierde.
- [ ] Decidir el latido y quién declara «sin señal»
      ([investigacion-alertas.md](investigacion-alertas.md#el-dead-mans-switch-pendiente-de-decidir)).

### 4. WhatsApp por Kapso · *Josuep*

Decidido el sábado 08:40: **el aviso va por WhatsApp con Kapso**, usando los créditos del evento.
Telegram sale del P0.

- [ ] Número de Kapso y `KAPSO_API_KEY` en Vercel y en `web/.env.local`, nunca en el repo.
- [ ] Poner el número en `NEXT_PUBLIC_WHATSAPP_NUMERO` (solo dígitos): con eso aparece el botón
      «Recibir avisos por WhatsApp» de la invitación. Hoy dice «pronto».
- [ ] Webhook de Kapso: el mensaje «Quiero cuidar a Carmen (casa demo)» registra el teléfono con
      la casa. Ese mensaje abre la ventana de 24 h de Meta.
- [ ] Cuando la alerta escala, a todos les llega un WhatsApp con el enlace a `/f/[token]`.

### 5. La web de la familia · *Rogelio*

Hecho con datos simulados: el estado se deriva en
[`estado.ts`](../web/src/lib/familia/estado.ts) (13 pruebas) y las pantallas están en
[`components/familia/`](../web/src/components/familia/). Para verla:
`/f/demo?escenario=todo-bien | alerta | para-saber | sin-senal`.

- [x] `/f/[token]`: todo bien, alerta urgente, para saber y sin señal, según los datos.
- [x] La invitación que se ve al escanear el QR (`/f/demo/bienvenida`), con WhatsApp.
- [x] `/demo`, con el QR gigante para el público.
- [x] La raíz lleva a la última casa abierta.
- [x] Escenarios simulados por URL (`?escenario=alerta`) como respaldo del demo.
- [x] Lee de Supabase cada 5 s ([`datos.ts`](../web/src/lib/familia/datos.ts)). Con
      `?escenario=` siguen los simulados, y la casa de demo cae a ellos si la base no responde.
- [x] «Ya hablé con Carmen» escribe en Supabase (`familia_atender`).

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
      [`simulado.dart`](../app/lib/datos/simulado.dart). Sigue el mismo patrón que la factura (abajo)
      y guarda con `familia_recetar(p_token, p_nombre, p_concentracion, p_comerciales, p_tomas)`.
- [ ] **Inventario de pastillas desde la factura** · *hecho en la web el sábado 24, falta conectarlo*.
      La familia sube la foto en `/f/[token]/pastillas/factura`, Claude la lee
      ([`route.ts`](../web/src/app/f/[token]/pastillas/factura/leer/route.ts)), `cruzar` la compara
      con el récipe ([`factura.ts`](../web/src/lib/familia/factura.ts)) y la familia confirma: solo
      se guarda lo del récipe. [`inventario.ts`](../web/src/lib/familia/inventario.ts) calcula
      cuántos días alcanzan y, con **menos de 7 días** (`AVISO_DIAS`), sale el aviso 🟡 «Hay que
      comprar» en `/f/[token]` con qué comprar para un mes. Para verlo: `/f/demo?escenario=para-saber`.
      Lo que falta, en orden:
  - [ ] **Aplicar la migración** [`20261024160000_pastillas_e_inventario.sql`](../supabase/migrations/20261024160000_pastillas_e_inventario.sql):
        pegarla en el SQL Editor del proyecto en Supabase, como la primera. Después,
        `cd web && bun run test:integracion` tiene que dar 11 pruebas en verde (6 de alertas y 5 de
        pastillas), y `bun --env-file=.env.local scripts/recipe-demo.ts` carga el récipe inventado
        de Carmen en la casa de demo.
  - [ ] **`ANTHROPIC_API_KEY`** en Vercel y en `web/.env.local`. Sin ella la página dice que la
        lectura no está activada y deja probar con la factura de ejemplo. Nunca en el repo.
  - [ ] **La app de la casa llama `casa_tomar`** al tocar «Ya me la tomé» (no se tocó `app/`
        porque otra sesión cambiaba esa pantalla): `POST {SUPABASE_URL}/rest/v1/rpc/casa_tomar`
        con `{"p_clave": <clave de la casa>, "p_pastilla": <Pastilla.id>, "p_hora": <ISO de la
        toma>}`. `p_pastilla` es el id de la pastilla en la app (`losartan-manana`,
        `losartan-noche`, `metformina`), que en la base es `tomas.clave`. Devuelve
        `{"medicamento": "Losartán", "quedan": 59}` (`quedan` es null si todavía no se cargó
        ninguna factura) o null si la clave o la pastilla no existen. Puede ir por la misma cola de
        [`nube.dart`](../app/lib/datos/nube.dart): una toma repetida el mismo día no descuenta otra
        vez. **El descuento vive en la base y no en la app** para que la casa y la web no tengan dos
        números.
  - [ ] **El aviso de compra por WhatsApp** cuando esté Kapso: el texto ya lo arma
        `mensajeDeCompra(nombre, inventario, ahora)` en [`inventario.ts`](../web/src/lib/familia/inventario.ts).
        Mandarlo al primer contacto una vez al día como mucho, junto con los otros avisos 🟡.
  - [ ] **Comprar por una farmacia con entrega** (Yummy, Farmatodo): el equipo está viendo si
        tienen API. El punto de enganche es `pedido(inventario, ahora)`, que devuelve qué comprar
        para un mes: genérico, concentración, nombres comerciales, cajas y pastillas por caja. No
        hay nada integrado ni supuesto de ninguna API.
  - [ ] El récipe se carga hoy con `familia_recetar` (el script de demo). Cuando exista la lectura
        del récipe por foto, que llame a esa misma función después de que la familia confirme.
  - [ ] El token `demo` es público: cualquiera puede gastar lecturas de Claude con él. Si se
        abusa en el demo, poner un tope por minuto en el route handler.
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
      Revisadas el sábado 10:00 contra la fuente original. **Para el pitch, solo estas:**

      | Cifra | Fuente |
      |---|---|
      | 7,9 millones de venezolanos fuera del país (nov-2024) | [R4V](https://www.r4v.info/es/situaciones/platform), vía [El Diario](https://eldiario.com/2024/12/06/r4v-mas-4-millones-venezolanos-regularizaron-su-situacion-migratoria-desde-2019-latam/) |
      | Entre 300.000 y 380.000 mayores viven solos en Venezuela (may-2026) | [Convite, vía El Diario](https://eldiario.com/2026/05/29/adultos-mayores-solos-venezuela/) |
      | Las caídas son la 2.ª causa de muerte por lesión no intencional: 684.000 al año | [OMS](https://www.who.int/news-room/fact-sheets/detail/falls) |
      | De los mayores de 90 años, el 30 % quedó una hora o más en el piso tras caerse | [Fleming y Brayne, BMJ 2008](https://pmc.ncbi.nlm.nih.gov/articles/PMC2590903) |

      **No usar** hasta encontrar la fuente original (vienen de
      [`dashboard/investigacion_sustento_problematica.md`](../dashboard/investigacion_sustento_problematica.md)):
      «842.000 muertes por caídas» (la OMS dice 684.000), «el long lie duplica la mortalidad, según
      el NIH» (viene de un estudio de 1997 con hospitalizados, no del NIH), los porcentajes de causas
      de accidentes, la tabla de tiempos de respuesta, los porcentajes de mayores solos por país, los
      31 millones del mercado global y el 65,6 % con hijos fuera. Ese documento también dice
      Telegram y latido por minuto: hoy son WhatsApp con Kapso y latido cada 90 s.
- [ ] **En el pitch se dice «golpe», no «caída».** El modelo oye un golpe y por eso pregunta antes
      de avisar. El escenario de demo (`/f/demo?escenario=alerta`) ya es «Un golpe fuerte en casa
      de Carmen».
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
