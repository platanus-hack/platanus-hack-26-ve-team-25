# Pendientes

Lo que falta para el demo del domingo, en orden. Escrito el sábado 24-oct a las 07:00. Cada punto
dice dónde está el código, qué falta y cómo saber que quedó. Quien tome uno, que ponga su nombre
y lo tache al terminar. Las preguntas de investigación por persona siguen en
[investigacion.md](investigacion.md), y lo que va después del hackatón, en [futuro.md](futuro.md).

## Estado (sábado 24-oct, tarde)

Se marca `[x]` lo que está hecho y comprobado. Lo que sigue abierto lleva escrito **por qué**:
casi nada está sin hacer por olvido, casi todo espera a algo concreto.

- **App de la casa ([`app/`](../app/README.md)):** horizontal como reloj de mesa, con el oído
  (YAMNet), los pedidos por voz (Vosk sin internet), la llamada por WhatsApp con respaldo
  telefónico y el recordatorio de pastillas. **78 pruebas** en `app/test/`. Le manda eventos,
  alertas y latido a Supabase, con cola si no hay internet. **Sigue sin probarse en un teléfono
  real.**
- **Web de la familia:** las pantallas, la invitación y `/demo` con el QR. Lee de Supabase cada 5 s
  y `?escenario=` fuerza los datos simulados. 13 pruebas del estado derivado. El inventario de
  pastillas desde la factura está hecho en la web, con su migración aplicada.
- **Supabase:** esquema, funciones, casa de demo y 11 pruebas de integración contra la base real
  (6 de alertas y 5 de pastillas). La migración de avisos quedó **aplicada y verificada** el
  sábado (las tres funciones existen y responden). La de pastillas, aplicada el sábado ~16:20,
  con el récipe inventado de Carmen cargado.
- **WhatsApp (Kapso):** código escrito y **sin desplegar**. Meta restringió la cuenta
  (`#2655121`); lo único operativo es el sandbox, con el teléfono de Josuep ya activado.
- **Telegram:** hecho, **desplegado y con el webhook registrado** (sábado, tarde). Es el canal
  general. Probado a mano de punta a punta contra la base real: suscripción, cola, envío con
  enlace y sello que evita repetir. **El vigilante corre desde las 16:21:** la base llama a
  `/api/vigilar` cada 5 s con pg_cron ([`20261024200000_vigilante.sql`](../supabase/migrations/20261024200000_vigilante.sql))
  y recibe 200. Falta la prueba de punta a punta con el teléfono de la casa y un segundo teléfono.
- **Alcance congelado el sábado 14:30:** lo que se presenta y quién hace qué está en
  [plan.md](plan.md#alcance-congelado-lo-que-se-presenta). Lo que no está ahí no se construye.
- **Lienzo de mockups:** [claude.ai/artifact/BgbTMPcFXsC9qxitsmk1f2](https://claude.ai/artifact/BgbTMPcFXsC9qxitsmk1f2).

## P0: sin esto no hay demo

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
      *Sin hacer: depende de tener la app instalada, y eso no ha pasado (punto 1).*
- [ ] Probar el banco con voces mayores reales (ver «Probar con voces mayores»).
      *Sin hacer: hacen falta personas mayores grabando y no se ha conseguido ninguna todavía.*
- [x] Órdenes por voz con «Lucero»: «llama a emergencias», «a mi hijo», «al vecino», con 5 s para
      decir «no»; y «ya me la tomé» en el recordatorio (ver
      [por-planificar.md](por-planificar.md#8-comandos-de-voz)).
- [ ] «Leer récipe» abre una pantalla que dice que todavía no está lista: falta la cámara y el
      OCR (ver P1, «Las pastillas desde la foto del récipe»).
      *Sin hacer: la lectura terminó resolviéndose subiendo la foto por la web (la factura), y el
      récipe no se ha llevado a ese mismo flujo.*

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
      aparece en `/f/demo`. *Sin hacer: es la misma prueba pendiente del punto 1; la app no se ha
      instalado en el teléfono.*
- [ ] Guardar la cola en disco: hoy, si la app se cierra sin internet, lo que esperaba se pierde.
      *Sin hacer: se eligió la cola en memoria para llegar al demo, y no se ha añadido ningún
      paquete de almacenamiento.*
- [ ] Decidir el latido y quién declara «sin señal»
      ([investigacion-alertas.md](investigacion-alertas.md#el-dead-mans-switch-pendiente-de-decidir)).
      *Sin hacer: es una decisión de equipo (C4 y C5, ya marcadas como pendientes en esa
      investigación). La web ya tiene la pantalla «Sin señal» y podría calcularlo con
      `ultimoLatido`, pero nadie lo ha decidido.*

### 4. WhatsApp por Kapso · *Josuep*

Decidido el sábado 08:40: **el aviso va por WhatsApp con Kapso**, usando los créditos del evento.
Telegram salió del P0 ese día y **volvió a entrar como 4b** cuando Meta restringió la cuenta.

**Estado real (sábado, tarde):** la cuenta de Meta quedó **restringida** (`#2655121`): el portafolio
tiene una cuenta publicitaria deshabilitada desde 2019 y Meta no deja conectar un número nuevo sin
verificación de negocio. Lo único que funciona hoy es el **sandbox de Kapso**, y el sandbox exige
**activar cada teléfono a mano** (sesión con un código de 6 caracteres que caduca en 15 minutos).
Sirve para el demo con los teléfonos de la tarima; no para que el público escanee el QR y reciba.
El código ya está escrito y desplegado: [`web/src/lib/kapso.ts`](../web/src/lib/kapso.ts),
[`api/kapso/webhook`](../web/src/app/api/kapso/webhook/route.ts),
[`api/vigilar`](../web/src/app/api/vigilar/route.ts) y
[`supabase/migrations/20261024180000_avisos.sql`](../supabase/migrations/20261024180000_avisos.sql)
— la misma migración sirve a los dos canales. **El circuito completo ya se probó, pero con
Telegram**: el camino de WhatsApp sigue sin ejecutarse ni una vez.

- [x] Credenciales de Kapso en `web/.env.local`: `KAPSO_PHONE_NUMBER_ID`, `KAPSO_API_KEY` y
      `KAPSO_WEBHOOK_SECRET`, comprobadas contra la API (responde 200) y fuera de Git
      (`.env.local` está ignorado). Las de Supabase y Telegram ya están en Vercel; **falta
      confirmar que las tres de Kapso también** para el demo del sandbox.
- [x] Un teléfono activado en el sandbox (*Add test number*): el de Josuep ya tiene sesión y sirve
      para las pruebas de envío.
- [ ] Poner el número en `NEXT_PUBLIC_WHATSAPP_NUMERO` (solo dígitos): con eso aparece el botón
      «Recibir avisos por WhatsApp» de la invitación. Hoy dice «pronto».
      *Sin hacer: el sandbox no publica un número marcable. La API devuelve
      `display_phone_number: null` y el dashboard solo muestra el Phone Number ID y el WABA ID,
      que no sirven en `wa.me`. Hasta que aparezca el número, el botón se queda en «pronto» y el
      demo no lo usa.*
- [ ] Webhook de Kapso: el mensaje «Quiero cuidar a Carmen (casa demo)» registra el teléfono con
      la casa.
      *Listo para probar, sin probar: la URL ya apunta a `/api/kapso/webhook` (verificado por API)
      y las rutas están desplegadas, responden 401 sin firma válida. Falta mandar un mensaje real
      desde el sandbox.*
- [ ] Cuando la alerta escala, a todos les llega un WhatsApp con el enlace a `/f/[token]`.
      *El circuito está probado, pero con Telegram: `/api/vigilar` escala, lee `avisos_pendientes`,
      manda y sella. Para WhatsApp falta que haya un teléfono suscrito por ese canal, y el sandbox
      solo lo permite activándolo a mano.*
- [ ] Activar en el sandbox cada teléfono que vaya a la tarima, y decirlo en el guion: el público
      no recibe.
      *A medias: solo el teléfono de Josuep tiene sesión. Cada uno más necesita su código de 6
      caracteres, que caduca en 15 minutos.*
- [x] Aplicar la migración en la base real: `20261024180000_avisos.sql` (antes
      `…_whatsapp.sql`), pegada en el SQL Editor el sábado y verificada contra el catálogo de la
      API: `familia_suscribir`, `avisos_pendientes` y `marcar_avisada` existen y responden.
- [ ] Probar el ciclo de WhatsApp: mensaje entrante → `suscripciones` → `GET /api/vigilar` envía.
      *Sin hacer: hace falta un mensaje real desde el sandbox. El mismo ciclo ya se probó con
      Telegram.*

### 4b. El mismo aviso por Telegram · *Josuep*

**Hecho el sábado 15:25** (`5ad9671`, `24a0bd8`), **desplegado y con el webhook registrado**.
El vigilante corre desde las 16:21: pg_cron llama a `/api/vigilar` cada 5 s, con el secreto en
Vault (`cron_secret`, el mismo valor de `CRON_SECRET` en Vercel). Si responde 401, los dos
secretos no coinciden: `select status_code, content from net._http_response order by created desc limit 5;`

El sandbox no sirve para «que le llegue a todos»: cada teléfono necesita sesión activa y la
apelación de Meta tarda 24-48 h. **Telegram sí llega a cualquiera sin verificación de negocio**, y
es el canal que ya describen [plan.md](plan.md) e
[investigacion-alertas.md](investigacion-alertas.md). La familia se registra desde la invitación y
recibe el aviso con el enlace a su panel.

Lo único que Telegram no permite: **el bot no puede escribirle primero a nadie**. Cada familiar
tiene que abrir el bot y pulsar `/start` una vez, con un deep link `t.me/<bot>?start=<token>`.

- [x] Bot creado con @BotFather (`@CasaAvisoBot`, «Casa • Avisos») y token en `TELEGRAM_BOT_TOKEN`,
      en Vercel y en `web/.env.local`. Sin verificación ni cuenta de negocio.
- [x] `web/src/lib/telegram.ts` con el mismo contrato que `kapso.ts` (`hayTelegram`, `enviarTexto`):
      `POST https://api.telegram.org/bot<token>/sendMessage`.
- [x] `web/src/app/api/telegram/webhook/route.ts`: recibe `/start <token>`, llama a
      `familia_suscribir` y contesta. **`setWebhook` ejecutado**: la URL quedó registrada, con
      `allowed_updates: ["message"]` y el secreto puesto; `getWebhookInfo` sin errores.
- [x] Botón «Recibir avisos por Telegram» en la invitación (comprobado en producción:
      `/f/demo/bienvenida` lleva a `t.me/CasaAvisoBot?start=demo`).
- [x] `/api/vigilar` manda por los dos canales: Telegram a todos los suscritos y WhatsApp a los
      teléfonos con sesión de sandbox. `avisos_pendientes` sirve igual para los dos.
- [ ] **El cron que llame a `/api/vigilar`.** *Sin hacer: nadie lo llama todavía. En el plan gratis
      de Vercel los cron corren una vez al día, así que para el demo se usa `cron-job.org` cada
      minuto o un `curl` en bucle desde la laptop.*
- [ ] Probar sin wifi: el aviso tiene que llegar por datos móviles.
      *Sin hacer: la prueba de esta tarde fue con la laptop por cable.*
- [ ] Probar con un segundo teléfono, no solo con el de Josuep.
      *Sin hacer: solo hay un chat suscrito, y es el del que programó el canal.*

**Cómo se probó el circuito** (sábado, tarde, contra la base real): se creó una casa «Prueba de
avisos», se suscribió el chat de Josuep como `telegram`, se creó un evento con `casa_evento` y una
alerta urgente con `casa_alerta`, `avisos_pendientes` devolvió una fila, se envió el mensaje con su
enlace, `marcar_avisada` la selló y la segunda consulta devolvió **cero filas**. Esa casa **sigue en
la base** (no hay función de borrado) con el token `8c6e2b92…`; es inofensiva pero conviene saberlo.


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

**Cerrada:** los ocho puntos están hechos. Lo que todavía no se puede ver es el *envío* del aviso,
que no es de esta web: es el punto 4 (WhatsApp) y el 4b (Telegram).

## P1: si P0 está listo

**Nada de esto se ha empezado.** El tiempo se fue en el oído, en las dos pantallas y en la base de
datos. Cada punto lleva su motivo.

**Sábado 14:30:** del P1 entran al alcance solo el tono y la vibración, y conectar el inventario de
pastillas. Lo demás va como proyección ([futuro.md](futuro.md#hacia-dónde-va)).

- [x] **El tono de 520 Hz y la vibración** en «¿Está bien?» (sábado 24). Onda cuadrada con el
      patrón temporal-3 de las alarmas de humo, por el canal de alarma (suena aunque el teléfono
      esté en silencio) y con su volumen al máximo mientras dura; la vibración sigue el mismo
      ritmo. En Kotlin, sin paquetes: [`Sirena.kt`](../app/android/app/src/main/kotlin/ve/equipo25/casa/Sirena.kt).
      Después de callarse, el oído ignora los sonidos 5 s, para no oír su propio tono.
      Falta oírlo en el teléfono: si satura el parlante, bajar `AMPLITUD`.
- [ ] **Que la app no se muera:** servicio en primer plano tipo `microphone` con
      `flutter_foreground_task`, pantalla encendida mientras carga y la app como pantalla de
      inicio ([riesgos.md §3](riesgos.md)).
      *Sin hacer: `flutter_foreground_task` no está en `pubspec.yaml` y el manifiesto no declara
      ningún servicio. Hoy la app escucha solo con la pantalla encendida y la app abierta.*
- [ ] **Pastilla olvidada:** si pasan 2 horas sin «Ya la tomé», aviso 🟡 a la familia. La lógica ya
      existe (`EstadoToma.olvidada` en [`pastillas.dart`](../app/lib/dominio/pastillas.dart)); falta
      mandarlo.
      *Sin hacer: falta el envío, y el envío es el punto 4 o el 4b. La lógica está y probada.*
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
  - [x] **Aplicar la migración** [`20261024160000_pastillas_e_inventario.sql`](../supabase/migrations/20261024160000_pastillas_e_inventario.sql):
        pegada en el SQL Editor el sábado ~16:20. `bun run test:integracion` da 11 en verde, y
        `scripts/recipe-demo.ts` cargó el récipe de Carmen: losartán (08:00 y 20:00) y metformina
        (14:00). **Todavía no tiene cuántas quedan:** falta cargar una factura o contarlas a mano en
        `/f/demo/pastillas`.
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
      *Sin hacer: el oído ya produce los eventos; falta agruparlos por franja. No se empezó.*
- [ ] **Configuración que guarde de verdad,** con el QR real de invitación.
      *Sin hacer: la app lee datos fijos de [`simulado.dart`](../app/lib/datos/simulado.dart) y no
      persiste nada; el QR de invitación es el token `demo`.*
- [ ] Un `make demo` que levante la web y la conecte con el teléfono (`adb reverse tcp:3000
      tcp:3000`), para probar los avisos sin desplegar.
      *Sin hacer: hasta ahora se probó con `next dev` y el teléfono contra Supabase directo, sin
      necesidad de ese puente.*

## Probar con voces mayores · *Abrahan*

**Sin empezar, y no por falta de tiempo:** hacen falta personas mayores grabando y un teléfono
viejo para medir. Ninguna de las dos cosas está disponible hoy.

- [ ] Clips de Common Voice de 60 años o más contra clips de 20: ¿YAMNet ve la voz igual?
- [ ] Notas de voz donadas: la meta es 10 personas, y el mensaje para pedirlas está en
      [investigacion-audio.md](investigacion-audio.md).
- [ ] Medir en el teléfono viejo cuánto tarda YAMNet por ventana, y cuánta batería y calor gasta.
- [ ] Si sobra tiempo: probar sherpa-onnx CED con ventanas de 5 s, que en la comparación acertó
      más ([experimentos/modelos-audio](../experimentos/modelos-audio/README.md)).

## Casi al final: probar todo en el teléfono real · *quien tenga el Android*

Abrahan lo pasó casi al final el sábado 24 a las 13:30: primero se planifica y se construye
([por-planificar.md](por-planificar.md)), y después se prueba todo junto.

Se instala con `make run` desde la raíz. Antes hay que copiar
`app/config/local.example.json` a `app/config/local.json` y poner el número de emergencia: ese
archivo no se sube, porque el repo es público.

**Por qué está sin empezar:** nadie ha hecho la prueba en un teléfono real. El número de
emergencia vive en `app/config/local.json`, que solo está en la máquina de Abrahan, y la app no se
ha instalado todavía en el teléfono que va a la tarima. Mientras esto siga abierto, todo lo demás
está probado solo con pruebas automáticas.

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
- [x] **Que la toma descuente** · *Abrahan*, sábado 24: «Ya me la tomé» llama `casa_tomar` por la cola de
      [`nube.dart`](../app/lib/datos/nube.dart), con la hora de la toma. Probado contra la base real
      con `make test-integracion` (de 8 a 7, y repetida no descuenta). Antes decía: «Ya me la tomé» llama `casa_tomar` (ver «Inventario
      de pastillas» en el P1) y en `/f/demo/pastillas` el losartán baja de 8 a 7. Es el momento 1
      del demo. La casa de demo arranca con 8 losartán (4 días, sale «Hay que comprar») y 40
      metformina; para volver a eso, «Las conté y son otras» en esa misma página.
- [ ] Anotar aquí lo que falló, con el modelo del teléfono y su versión de Android.

## Para el pitch y el jurado

- [x] **Aguanta al público:** [`web/scripts/carga.ts`](../web/scripts/carga.ts) simula los
      teléfonos que escanean el QR en 5 s, abren `/f/demo` y leen la casa cada 5 s. Sábado 24-oct,
      ~16:00, desde la laptop en Caracas contra producción:

      | Teléfonos | Duración | Lecturas | Fallas | Abrir `/f/demo` (p50 · p95) | Leer la casa (p50 · p95 · máx) |
      |---|---|---|---|---|---|
      | 50 | 2 min | 1124 (8,6/s) | 0 | 433 · 1437 ms | 262 · 1474 · 4005 ms |
      | 150 | 1 min | 1653 (22,9/s) | 0 | 729 · 1406 ms | 344 · 2913 · 10145 ms |

      Con 50 sobra. Con 150 no falla nada, pero alguna lectura tarda hasta 10 s: la alerta se ve un
      ciclo más tarde. No se midió si el cuello es Supabase Free o la red de la laptop.
- [x] **Cifras con fuente** ([investigacion.md](investigacion.md#anttony--antecedentes-y-usuarios)).
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
      *Sin hacer: es una decisión de equipo, no una tarea de código.*
- [ ] Actualizar [preguntas-tecnicas.md](preguntas-tecnicas.md) con lo que ya pasó a código: el
      oído en el teléfono, la llamada por WhatsApp y su respaldo, y la respuesta por voz.
      *Sin hacer: el canal cambió tres veces (Telegram → WhatsApp → WhatsApp con sandbox más
      Telegram). Se actualiza cuando el 4b esté decidido, o se actualiza dos veces.*
- [ ] Que la tabla de estado del README y la de [AGENTS.md](../AGENTS.md) digan lo mismo que el
      código.
      *Sin hacer: cambian cada hora con los commits de todo el equipo. Es lo último que se toca
      antes de congelar, el domingo a las 24:00.*
- [ ] Contar las limitaciones en voz alta ([riesgos.md](riesgos.md#cómo-contar-la-verdad)): la
      llamada de WhatsApp va por una vía no oficial, y Android no dice si la contestaron.
      *Se prepara antes del pitch; el texto ya está escrito en riesgos.md. Falta ensayarlo.*
- [ ] En el lienzo, la fila «Teléfono de la casa de pie» es la versión anterior: se puede borrar.
      *Sin hacer: es cosmético en un artifact externo y no bloquea nada.*
- [ ] Llave propia para firmar el App Bundle, si se quiere subir a Google Play.
      *Sin hacer y sin urgencia: la app se distribuye por sideload, y la investigación de alertas
      ya documenta que la tienda no aplica a este proyecto.*
