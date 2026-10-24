# Pendientes

Lo que de verdad queda para el demo del domingo 25 a las 10:00, por persona. Reescrito por Abrahan
el sábado 24 a las 18:00: se sacó todo lo que no se va a hacer por falta de tiempo. Lo que va
después del hackatón está en [futuro.md](futuro.md); las ideas que se van pensando, en
[por-planificar.md](por-planificar.md); y cómo se arma el demo con los cuatro teléfonos, en
[armar-demo.md](armar-demo.md).

## Lo que queda

### Rogelio · activar la lectura de la factura

**El demo lee una factura** (Abrahan, sábado 24 a las 18:45: es más simple). La lectura ya está
hecha en la web y probada con la factura de ejemplo: la familia le toma una foto en
`/f/demo/pastillas/factura`, Claude la lee
([`route.ts`](../web/src/app/f/[token]/pastillas/factura/leer/route.ts), con su prompt), se cruza
con el récipe ([`factura.ts`](../web/src/lib/familia/factura.ts)), la familia confirma y solo se
guarda lo que está en el récipe. Falta encenderla:

- [ ] Poner **`ANTHROPIC_API_KEY`** en Vercel (Settings → Environment Variables, en Production) y
      en `web/.env.local`, y volver a desplegar. Nunca en el repo. Sin ella, la página dice que la
      lectura no está activada y solo deja probar con la factura de ejemplo.
- [ ] **Imprimir una factura inventada** de farmacia con las pastillas del récipe de Carmen:
      losartán 50 mg (por ejemplo «COZAAR 50MG X30 TAB») y metformina 500 mg, y algo que no esté
      en el récipe (un champú) para mostrar que eso no se guarda. Nada de facturas reales.
- [ ] Probarla con la foto: derecha, torcida y con poca luz. Ver que en `/f/demo/pastillas` sube
      el inventario y cambian los días que alcanzan.

### Abrahan · la app de la casa y el demo

- [x] **El reposo, más grande** (sábado 18:40, con el skill ui-ux-pro-max): reloj más alto y
      más grande, «Leer récipe» bajo «Pedir ayuda» con el alto de la cinta de la pastilla, la cinta
      más alta y con letra de 27, y el borde de los botones a 3,8:1 de contraste. Captura sin
      teléfono: `flutter test --run-skipped --update-goldens -t captura` →
      [`app/test/capturas/reposo.png`](../app/test/capturas/reposo.png).
- [ ] **Las demás vistas del teléfono de mesa,** con las indicaciones que va a dar Abrahan.
- [ ] **Armar el demo** con los cuatro teléfonos ([armar-demo.md](armar-demo.md)): Infinix de
      mesa, Samsung de la familia, iPhone como «el 911» y el Honor por definir.
- [ ] **Probar todo en el teléfono real**, de punta a punta, con la tabla de
      [armar-demo.md](armar-demo.md#5-la-prueba-de-punta-a-punta-en-el-orden-del-demo). Nada de la
      app de la casa se ha probado en el teléfono desde que se agregaron la voz, la sirena, las
      órdenes con «Lucero», la toma que descuenta y el servicio en primer plano.
- [ ] **Llave propia para firmar el App Bundle**, de madrugada, cuando todo funcione.

### Josuep · Telegram

Lo único que queda del canal son dos pruebas que necesitan teléfonos de verdad; el código, el
webhook y el vigilante están hechos y verificados.

- [ ] Probar el aviso sin wifi, por datos móviles.
- [ ] Probar con un segundo teléfono suscrito, no solo con el de Josuep.

### Todo el equipo · el pitch

- [ ] **El nombre del producto.** Hoy la web dice «En casa» de relleno
      ([`web/src/lib/app.ts`](../web/src/lib/app.ts)) y la app, «Casa». La casa se llama
      «Lucero» en las órdenes de voz.
- [ ] **El guion del demo** en [plan.md](plan.md#demo), con lo que se decidió el sábado.
- [ ] **Ensayar las limitaciones en voz alta** ([riesgos.md](riesgos.md#cómo-contar-la-verdad)).
- [ ] **En el pitch se dice «golpe», no «caída».** El oído reconoce un golpe y por eso pregunta.
- [ ] Video de respaldo.

### Si sobra tiempo

- [ ] Guardar en disco la cola de la app de la casa: hoy, si la app se cierra sin internet, lo que
      esperaba por enviarse se pierde ([`nube.dart`](../app/lib/datos/nube.dart)).
- [ ] En el lienzo de mockups, borrar la fila «Teléfono de la casa de pie», que es la versión vieja.
- [ ] **Si sobra tiempo, y no para el demo:** mostrar en la pantalla de pastillas el **precio y el
      stock reales** de cada medicamento que falta comprar, leídos de Algolia, con un enlace por
      renglón a la búsqueda de Farmatodo (`https://www.farmatodo.com.ve/buscar?product=` con el
      término al final). Iría en [`web/src/lib/familia/`](../web/src/lib/familia/).

## Lo que está hecho

Todo con pruebas automáticas; lo de la app de la casa, todavía sin probar en el teléfono desde los
últimos cambios.

**App de la casa ([`app/`](../app/README.md)), 120 pruebas:**

- [x] Horizontal como reloj de mesa: reposo con «Pedir ayuda» en todo el panel derecho, la pastilla
      en chico y «Leer récipe».
- [x] El oído: micrófono crudo → compuerta de dB → YAMNet en el teléfono. Arreglado el sábado: el
      audio llegaba en bloques que empezaban en un byte impar y el oído estaba sordo.
- [x] «¿Está bien?» con 60 s, deslizar para «estoy bien» y tocar para «necesito ayuda». Suena a
      520 Hz con el ritmo de las alarmas de humo, vibra y pregunta con la voz del teléfono
      ([`Sirena.kt`](../app/android/app/src/main/kotlin/ve/equipo25/casa/Sirena.kt)).
- [x] La voz, con Vosk sin internet: un banco de ~70 frases de ayuda («me siento malita», «huele a
      gas»), y órdenes con «Lucero»: «llama a mi hijo», «… al vecino», «… a emergencias» (5 s
      para decir «no»), «Lucero, estoy bien» para callar la alarma, y «ya me la tomé».
- [x] Al escalar, llama al hijo por WhatsApp y, si no contestan, por teléfono. Sin internet
      (ni wifi ni datos que salgan de verdad) no intenta WhatsApp: llama directo por teléfono.
- [x] Si el hijo no contesta ni el WhatsApp ni el teléfono, la casa llama a emergencias en altavoz.
      Android no dice si contestaron, así que después de la llamada por teléfono pregunta otra vez
      «¿Pudo hablar con Josuep?»; con «no» o sin respuesta en 15 s, llama a `NUMERO_EMERGENCIAS`. A emergencias y
      al vecino, llamada normal en altavoz y con el volumen al máximo.
- [x] El recordatorio de la pastilla en toda la pantalla, que solo se quita con «Ya me la tomé»,
      y que descuenta del inventario con `casa_tomar` (probado contra la base: de 8 a 7).
- [x] Le manda a Supabase eventos, alertas, respuestas y un latido cada 90 s con la batería y si
      está enchufado, con cola si no hay internet. `make test-integracion` lo prueba contra la base
      real con una casa que se crea y se borra.
- [x] Servicio en primer plano para que siga oyendo con la pantalla apagada
      ([`Guardia.kt`](../app/android/app/src/main/kotlin/ve/equipo25/casa/Guardia.kt)).
- [x] «Lucero, estoy bien» encima de la alarma (sábado 19:00, tras la prueba en el Infinix:
      solo se entendía cuando la sirena paraba). Después de cada frase, la sirena se calla 4 s y
      la pantalla dice «Le escucho»; al cerrarse, Vosk lee justo esos segundos. Y mientras suena,
      un filtro le quita la sirena al audio que va a Vosk: muescas en 520 Hz y sus múltiplos, que
      la bajan más de 30 dB y a la voz menos de 1 ([`filtro.dart`](../app/lib/oido/filtro.dart)).
      La sirena ahora se arma con sus armónicos, sin frecuencias fantasma que el filtro no podría
      quitar. Falta probarlo en el teléfono.
- [x] La rutina: cuenta lo de siempre que suena por franja del día y lo manda como «Su día»; si
      de día no suena nada en 3 horas, avisa una vez como «día distinto»
      ([`rutina.dart`](../app/lib/dominio/rutina.dart)).
- [x] `make demo`: la web de la familia en la laptop y la app en el teléfono a la vez, con
      `adb reverse` para abrir `http://localhost:3000/f/demo` desde el teléfono.

**Supabase:** esquema, funciones con secretos en hash, escalamiento atómico, casa de demo, avisos
y pastillas, con 11 pruebas de integración. El vigilante corre en la base cada 5 s con pg_cron
desde las 16:21, y a las 18:30 se verificó de verdad: una alerta nueva se envió y se selló sola en
5 segundos. Quedan en la base dos casas de prueba de esas verificaciones («Prueba de avisos» y
«Prueba del vigilante»); no hay función de borrado y son inofensivas.

**«Sin señal»:** la casa late cada 90 s, y la web de la familia declara «sin señal» cuando pasan
180 s sin latido, es decir, dos latidos perdidos
([`estado.ts`](../web/src/lib/familia/estado.ts)). Lo calcula quien lee, sin servidor aparte.

**Web de la familia:** todo bien, alerta, para saber y sin señal; la invitación con Telegram;
`/demo` con el QR; «Ya hablé con Carmen»; el inventario de pastillas con cuántos días alcanzan; y
aguanta 50 teléfonos leyendo cada 5 s sin fallas.

**Telegram:** bot `@CasaAvisoBot`, suscripción desde la invitación con `/start`, y el aviso con el
enlace cuando la alerta escala. **El vigilante lo manda solo**: el sábado ~18:30 se creó una alerta
urgente en una casa de prueba y pasó de «1 en cola» a «0 en cola» **en 5 segundos**, sin que nadie
llamara a `/api/vigilar` a mano. Probado de punta a punta contra la base real.

**Cifras para el pitch, con fuente:**

| Cifra | Fuente |
|---|---|
| 7,9 millones de venezolanos fuera del país (nov-2024) | [R4V](https://www.r4v.info/es/situaciones/platform), vía [El Diario](https://eldiario.com/2024/12/06/r4v-mas-4-millones-venezolanos-regularizaron-su-situacion-migratoria-desde-2019-latam/) |
| Entre 300.000 y 380.000 mayores viven solos en Venezuela (may-2026) | [Convite, vía El Diario](https://eldiario.com/2026/05/29/adultos-mayores-solos-venezuela/) |
| Las caídas son la 2.ª causa de muerte por lesión no intencional: 684.000 al año | [OMS](https://www.who.int/news-room/fact-sheets/detail/falls) |
| De los mayores de 90 años, el 30 % quedó una hora o más en el piso tras caerse | [Fleming y Brayne, BMJ 2008](https://pmc.ncbi.nlm.nih.gov/articles/PMC2590903) |

Las demás cifras de [`dashboard/investigacion_sustento_problematica.md`](../dashboard/investigacion_sustento_problematica.md)
no se usan hasta encontrar la fuente original.

## Lo que se sacó el sábado 24 a las 18:00

Para que nadie lo retome sin saber por qué:

- **WhatsApp por Kapso, entero:** Meta restringió la cuenta y el sandbox exige activar cada
  teléfono a mano. Los avisos van **solo por Telegram**. El código de Kapso sigue en `web/` pero no
  se usa. La **llamada** de WhatsApp de la casa al hijo sí sigue: es otra cosa, sale del teléfono.
  **No queda ninguna tarea pendiente de este canal**: `/api/vigilar` solo lo despacharía si
  existiera una suscripción con `canal = 'whatsapp'`, y hoy no hay ninguna; la invitación muestra
  «Avisos por WhatsApp: pronto» y el botón nunca aparece.
- **Comprar en una farmacia:** no se hace. Farmatodo no es VTEX ni Magento ni Shopify: es una SPA
  propia en Angular 12 sobre Google Cloud. Verificado el 24-oct-2026 con fetch directo al sitio: el
  catálogo, el precio y el stock se leen sin llave ni login (la búsqueda corre sobre Algolia, app
  `VCOJEYD2PO`, con credenciales search-only públicas en el propio HTML), y el endpoint que agrega
  al carrito responde sin login: devolvió 400 pidiendo campos del carrito, no 401. **Lo que falta
  es el puente: ese carrito creado desde fuera no aparece en el navegador del usuario.** El pago
  exige login con Firebase Auth y reCAPTCHA Enterprise, no se encontró ningún parámetro de URL que
  precargue un carrito, y no se puede embeber (`X-Frame-Options: DENY`, `frame-ancestors 'none'`).
  Los términos (secciones 5 y 14) prohíben violar la seguridad del sitio y el framing; no mencionan
  scraping ni bots, así que queda como zona gris contractual. Queda como proyección.
- **El aviso de compra por WhatsApp:** se va con Kapso, que era su canal. Queda como proyección.
- **La pastilla olvidada** (aviso 🟡 a las 2 horas): va a [futuro.md](futuro.md).
- **Leer el récipe por foto:** el demo lee la factura, que ya está hecha. El récipe de Carmen se
  carga con el script de demo; leerlo por foto va a [futuro.md](futuro.md#salud).
- **La app como pantalla de inicio** y **la voz del hijo grabada**: van al speech como lo que viene.
