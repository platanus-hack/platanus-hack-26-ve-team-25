# Guía del repo para agentes

Proyecto del equipo 25 en Platanus Hack 26 (Caracas, 23–25 de octubre de 2026), track
Emergencias. Este archivo resume qué hay en el repo y dónde, para que un agente responda
preguntas o trabaje en él sin leerlo todo. Todo lo que dice aquí se puede verificar en los
archivos enlazados. Si algo no coincide con el código, manda el código.

## Qué es

Un teléfono Android viejo, enchufado en la mesa de un adulto mayor que vive solo, lo acompaña en el
día a día (el recordatorio de la pastilla, llamar a su hijo con la voz) y oye lo que pasa: alarma de
humo, vidrio roto, golpe, grito o una frase de ayuda dicha en voz alta. Antes de avisar, pregunta
«¿Está bien?». Si nadie responde en 60 s, la alerta escala: la familia, que suele estar en otro
país, recibe un Telegram y la casa la llama por WhatsApp; si nadie contesta, llama a emergencias.
El audio se procesa en el teléfono y
nunca sale de él. La arquitectura y las decisiones, con su evidencia, están en el
[README](README.md).

## Estado real (sábado 24-oct-2026, 17:30)

| Pieza | Estado | Dónde |
|---|---|---|
| App Flutter del teléfono de la casa | Horizontal como reloj de mesa. «¿Está bien?» con cuenta de 60 s y deslizador; «Pedir ayuda» escala sin esperar. Oye con YAMNet en el teléfono; entiende frases de ayuda y órdenes («Lucero, llama a mi hijo») con Vosk sin internet. Al escalar llama al primer contacto por WhatsApp; si no contestan, por teléfono, y si tampoco, a emergencias (`NUMERO_EMERGENCIAS`, fijado al compilar). Sin internet llama igual por la línea. «¿Está bien?» suena a 520 Hz, vibra y pregunta con la voz del teléfono. También se responde con la voz: «Lucero, estoy bien» la calla, y «ayuda», «me caí» o «no» llaman sin esperar los 60 s. Recordatorio de pastillas, y «Ya me la tomé» descuenta del inventario con `casa_tomar`. Cuenta la rutina por franja del día y avisa si de día no suena nada en 3 h. Le manda a Supabase eventos, alertas, respuestas y el latido, con cola en memoria si no hay internet. Antes de una llamada de emergencia toma una foto de la sala para la familia. 127 pruebas. En la tarima va con `make release-demo`: espera 15 s en vez de 60. Un servicio en primer plano la mantiene viva con la pantalla apagada. Que sea la pantalla de inicio va en el speech como lo que viene. Se está probando en el teléfono de la tarima | [`app/`](app/README.md) |
| La app de la casa para instalar | En Play Store como [prueba interna](https://play.google.com/apps/internaltest/4701205547603054693) (`com.abrahan.presente`), y el APK en el Release [`casa-v0.1.0`](https://github.com/platanus-hack/platanus-hack-26-ve-team-25/releases/tag/casa-v0.1.0), con 60 s y sin `local.json`: oye y pregunta, pero no llama ni escribe en la base | [`Makefile`](Makefile) (`make apk-publico`) |
| La app de la casa compilada para web | Publicada en https://platanus-hack-26-ve-team-25-casa.vercel.app, sin oído ni llamadas: en web, TFLite se cambia por una versión vacía con una importación condicional | [`app/lib/oido/tflite_web.dart`](app/lib/oido/tflite_web.dart), [`app/tool/vercel_build.sh`](app/tool/vercel_build.sh) |
| Alertas con vencimiento y escalamiento | Hecho. La casa registra la alerta al nacer, con su vencimiento; `escalar_vencidas()` la pasa a «escalada» con una sola escritura que gana. RLS activado sin políticas, funciones con secreto en hash SHA-256 | [`supabase/migrations/20261024130000_casa_y_familia.sql`](supabase/migrations/20261024130000_casa_y_familia.sql), [`nube.dart`](app/lib/datos/nube.dart) |
| El vigilante | Hecho y corriendo desde el sábado 16:21: pg_cron llama a `GET /api/vigilar` cada 5 s con pg_net, con el secreto en Vault (`cron_secret`, el mismo `CRON_SECRET` de Vercel). Escala lo vencido, manda los avisos en tandas de 25 en paralelo y los sella por alerta y destinatario | [`20261024200000_vigilante.sql`](supabase/migrations/20261024200000_vigilante.sql), [`api/vigilar/route.ts`](web/src/app/api/vigilar/route.ts) |
| Aviso por Telegram | Hecho, desplegado y con el webhook registrado. Es el canal general: la familia se suscribe desde la invitación con `t.me/<bot>?start=<token>` | [`api/telegram/webhook/route.ts`](web/src/app/api/telegram/webhook/route.ts), [`lib/telegram.ts`](web/src/lib/telegram.ts), [`20261024180000_avisos.sql`](supabase/migrations/20261024180000_avisos.sql) |
| Aviso por WhatsApp (Kapso) | Sacado del demo el sábado 18:00: Meta restringió la cuenta. Los avisos van solo por Telegram. El código sigue en `web/` sin usarse | [`lib/kapso.ts`](web/src/lib/kapso.ts) |
| Web de la familia (PWA) | Alerta urgente, todo bien, para saber, sin señal, invitación con Telegram, `/demo` con el QR y la política de privacidad en `/privacidad`, enlazada desde la portada y la invitación. Lee `familia_casa` cada 5 s directo de Supabase; con `?escenario=alerta` usa datos simulados. El estado se deriva en una función pura con pruebas | [`web/src/lib/familia/`](web/src/lib/familia/), [`web/src/components/familia/`](web/src/components/familia/) |
| Inventario de pastillas | Hecho, con la migración aplicada. La foto de la factura va a Claude (`claude-opus-5-5`, salida estructurada), `cruzar` la compara con el récipe y la familia confirma. Es un libro de movimientos: la factura suma, `casa_tomar` resta y el conteo a mano ajusta; `inventario.ts` calcula los días (aviso con menos de 7). La casa de demo tiene 8 losartán y 40 metformina | [`20261024160000_pastillas_e_inventario.sql`](supabase/migrations/20261024160000_pastillas_e_inventario.sql), [`inventario.ts`](web/src/lib/familia/inventario.ts), [`factura.ts`](web/src/lib/familia/factura.ts), [`f/[token]/pastillas/`](web/src/app/f/[token]/pastillas/) |
| Pruebas de la web | 63 unitarias (`bun test`), incluidos la foto de la emergencia, el tope de lecturas de factura y cómo se lee cuánto lleva una casa sin señal, y 11 contra la base real: 6 de alertas y 5 de pastillas (`bun run test:integracion`) | [`web/src/lib/`](web/src/lib/) |
| Foto de la emergencia | Hecho el domingo 02:10; falta probarla en el Samsung con una alerta de verdad. Antes de llamar por una alerta o a emergencias, la cámara de adelante toma una foto (4 s como mucho, si falla se llama igual). Va a `/api/casa/foto`, al bucket privado `fotos` de Supabase Storage (sin tabla nueva); Claude dice lo que se ve y sale por Telegram y en la alerta roja con un enlace firmado. Se borra a las 24 h. 5 pruebas en la app y 6 en la web | [`camara.dart`](app/lib/datos/camara.dart), [`api/casa/foto`](web/src/app/api/casa/foto/route.ts), [`lib/fotos/`](web/src/lib/fotos/), [`foto-casa.tsx`](web/src/components/familia/foto-casa.tsx) |
| Prueba de carga del pitch | 50 teléfonos durante 2 min y 150 durante 1 min contra producción, sin una falla | [`web/scripts/carga.ts`](web/scripts/carga.ts), [resultados](docs/pendientes.md#para-el-pitch-y-el-jurado) |
| Oído en el navegador (`/escucha`) | La prueba de viabilidad: micrófono → compuerta de dB → YAMNet → 6 tipos de evento, con 12 pruebas | [`web/src/app/escucha/`](web/src/app/escucha/), [`web/src/lib/escucha/`](web/src/lib/escucha/) |
| Comparación de 9 modelos de audio en 640 sonidos de casa | Hecha y reproducible. YAMNet acierta el 82% en el top-5 con 4,1 MB | [`experimentos/modelos-audio/`](experimentos/modelos-audio/README.md) |
| Vibración del piso, apagón según el perfil de salud, ficha de emergencia, cámara, rutina | Fuera del alcance del hackatón: van como proyección | [`docs/futuro.md`](docs/futuro.md#hacia-dónde-va) |

La raíz lleva a la última casa abierta en el teléfono. Cada push a `main` despliega la web en
Vercel; si el build falla, producción no cambia.

## Mapa del repo

```text
README.md                         qué es, cómo probarlo, arquitectura, decisiones, pruebas y límites
docs/plan.md                      lo que se presenta (alcance congelado), el demo y la venta
docs/pendientes.md                lo que falta, en orden, con dónde está el código y cómo probarlo
docs/futuro.md                    hacia dónde va el producto
docs/contexto.md                  el problema, la competencia y las decisiones de diseño
docs/riesgos.md                   muros técnicos (kiosco, apagones, batería), riesgos del demo
docs/preguntas-tecnicas.md        preguntas técnicas frecuentes, con la evidencia de cada respuesta
docs/por-planificar.md            ideas de Abrahan que se van pensando antes de construirlas
docs/armar-demo.md                qué va en cada teléfono del demo, cómo se conectan y cómo se prueba
docs/pantallas.md                 plan para pasar los mockups a código: contrato de datos, estructura y orden
docs/investigacion-alertas.md     capa de alertas: transporte, escalamiento, apagones y perfil energético
docs/investigacion-audio.md       voz del adulto mayor, modelos, sensores y paquetes de Flutter
docs/investigacion-carga.md       cómo se sabe si el teléfono está cargando: señales de Android y battery_plus
docs/investigacion.md             preguntas abiertas por persona del equipo
app/                              Flutter: la app del teléfono de la casa
web/                              Next.js: la web de la familia, el vigilante, los webhooks y /escucha
web/scripts/                      la prueba de carga y la carga de la casa de demo
supabase/migrations/              el esquema, las funciones, quién puede llamar qué y el vigilante
experimentos/modelos-audio/       Python con uv: exportación a ONNX y comparación de modelos
```

## Decisiones técnicas clave

La lista completa, con la evidencia de cada una, está en el [README](README.md#las-decisiones-y-por-qué).

- **Todo lo posible en el teléfono.** El audio vive solo en un buffer circular de 5 s en memoria
  ([`anillo.dart`](app/lib/oido/anillo.dart)). Al servidor van etiquetas de eventos, alertas y
  latidos, nunca audio. Lo único que sale además es una foto, y solo justo antes de una llamada de
  emergencia.
- **El audio llega crudo al modelo.** Sin supresión de ruido ni control de volumen, porque esos
  filtros borran golpes y alarmas ([razón](docs/investigacion-audio.md)).
- **YAMNet como modelo base**, elegido con la comparación de `experimentos/modelos-audio`.
- **La alerta vive en la base desde que nace.** Si el teléfono de la casa muere, la base la escala
  igual; el vigilante corre dentro de Supabase, sin un servidor aparte.
- **El camino de la alarma no depende de un modelo de lenguaje.** Claude lee la factura (la familia
  confirma antes de guardar) y describe la foto de la emergencia después de llamar, sin frenarla.
- **Stack del hackatón:** Flutter en Android para la casa; Next.js 16 en Vercel para la familia;
  Supabase con pg_cron, pg_net y Vault; avisos por Telegram. La casa no puede
  ser iOS: no deja escuchar todo el día en segundo plano.

## Cómo correr las pruebas

```bash
cd web && bun install && bun test
cd web && bun run test:integracion                     # contra la base real, con web/.env.local
cd web && bun --env-file=.env.local scripts/carga.ts   # carga: 50 teléfonos durante 2 min
make test                                              # la app de la casa
cd experimentos/modelos-audio && uv sync && ./descargar.sh && uv run comparar.py
```

## Reglas para trabajar en el repo

- Español en el código, los comentarios, los documentos y los commits.
- Commits chicos con prefijo (`feat`, `fix`, `docs`, `chore`, `test`) y push seguido.
- Antes de subir algo de `web/`, `cd web && bun run build`: un build roto deja producción vieja.
- El repo es público: nada de llaves, `.env`, grabaciones de personas ni datos reales. Los datos
  de prueba son inventados.
- Al terminar una pieza, actualizar la tabla de estado de este archivo y la del README.
- En `web/` aplica además [`web/AGENTS.md`](web/AGENTS.md): esta versión de Next.js tiene cambios
  que no están en los datos de entrenamiento. Por ejemplo, con `cacheComponents` las rutas no
  aceptan `export const runtime` ni `dynamic`.
