# En casa · Equipo 25 · Platanus Hack 26: Caracas ft. Yummy

<img src="./project-logo.png" alt="Logo del proyecto" width="200" />

**Un teléfono viejo que cuida a los que se quedaron solos.** Enchufado en la mesa de un adulto
mayor que vive solo, lo acompaña en el día a día (la pastilla, llamar a su hijo con un toque) y oye
lo que pasa en la casa: una alarma de humo, un vidrio roto, un golpe, un grito o un «¡ayuda!» dicho
en voz alta. Antes de avisar, pregunta «¿Está bien?». Si nadie responde en 60 s, avisa a la
familia, que suele estar en otro país, por Telegram y con una llamada de WhatsApp. **El audio se
procesa en el teléfono y nunca sale de él.** Su asistente de voz se llama **Lucero**: «Lucero,
estoy bien» calla la alarma y «Lucero, llama a mi hijo» llama.

Track: 🚨 Emergencias

## Pruébalo, sin instalar nada ni crear cuenta

- **Eres la familia de Carmen** (inventada): https://platanus-hack-26-ve-team-25.vercel.app/f/demo.
  El QR del pitch está en [`/demo`](https://platanus-hack-26-ve-team-25.vercel.app/demo).
- **Para que te llegue el aviso:** en la [invitación](https://platanus-hack-26-ve-team-25.vercel.app/f/demo/bienvenida),
  «Recibir avisos por Telegram».
- **Una alerta simulada**, sin esperar a que pase algo: [`/f/demo?escenario=alerta`](https://platanus-hack-26-ve-team-25.vercel.app/f/demo?escenario=alerta).
- **El teléfono de la casa en el navegador**, sin oído ni llamadas: https://platanus-hack-26-ve-team-25-casa.vercel.app.
  El oído de verdad corre en la app Android ([`app/`](app/README.md)).
- **La app Android, para instalar:** [`en-casa.apk`](https://github.com/platanus-hack/platanus-hack-26-ve-team-25/releases/latest/download/en-casa.apk)
  (105 MB, Android 7 o posterior, [Release `casa-v0.1.0`](https://github.com/platanus-hack/platanus-hack-26-ve-team-25/releases/tag/casa-v0.1.0)).
  Oye, entiende «Lucero» y pregunta «¿Está bien?» con 60 s de espera, sin internet. Va sin los
  números ni la clave de la casa de demo, así que no llama ni escribe en la base: para eso se
  compila con su propio `app/config/local.json`.

## Cómo funciona

```text
TELÉFONO DE LA CASA · Flutter en Android
  micrófono ─► buffer de 5 s en memoria ─┬─► compuerta de dB ─► YAMNet (TFLite) ─► alarma, vidrio, golpe, grito
                                         └─► Vosk, sin internet ─► «¡ayuda!», «me siento mal», ~70 frases
                                                                    «Lucero, llama a mi hijo»: 5 s para decir «no»
                                                    │
                                                    ▼
  «¿Está bien?» ─► casa_alerta(vence en 60 s) ──────────────────────────────────┐
     ├─ «Estoy bien», deslizando o con la voz ─► casa_responder('cancelar')      │
     ├─ «ayuda», «me caí» o «no» ─► escala sin esperar los 60 s                  │
     └─ vence sin respuesta ─► llama al hijo por WhatsApp; si no, por teléfono   │
  latido cada 90 s, con enchufado y batería ─► casa_latido                       │
                                                                                 ▼
SUPABASE · Postgres
  alertas: pendiente ─► escalada ─► atendida · escalar_vencidas(): una sola escritura gana
  pg_cron cada 5 s ─► GET /api/vigilar: escala lo vencido, manda los avisos y los sella
                                                                                 │
                                                                                 ▼
FAMILIA · Next.js 16 en Vercel, sin login: el enlace de invitación es la llave
  /f/[token] lee familia_casa cada 5 s ─► 🔴 alerta · 🟡 para saber · 🟢 todo bien · sin señal
  Telegram (/start <token>) ◄─ el aviso del vigilante
  Pastillas: foto de la factura ─► Claude ─► se cruza con el récipe ─► la familia confirma
```

## Las decisiones, y por qué

- **El audio nunca sale del teléfono.** Vive en un buffer circular de 5 s en memoria
  ([`anillo.dart`](app/lib/oido/anillo.dart)); a la base van etiquetas de eventos, alertas y
  latidos. Es privacidad y es costo: no hay un servidor de audio que pagar por minuto.
- **YAMNet, elegido midiendo.** Comparamos 9 modelos sobre 640 sonidos de casa de ESC-50. YAMNet
  acierta el 82% en el top-5 con 4,1 MB y 2,5 ms por segundo de audio en una CPU de escritorio.
  Los dos que se le acercan (81%) pesan entre 7 y 80 veces más y tardan entre 10 y 27 veces más
  ([resultados](experimentos/modelos-audio/resultados-1s.md),
  [cómo se midió](experimentos/modelos-audio/README.md)).
- **El audio llega crudo al modelo:** sin supresión de ruido ni control de volumen, porque esos
  filtros borran justo los golpes y las alarmas ([investigacion-audio.md](docs/investigacion-audio.md)).
- **Preguntar antes de avisar.** La meta es despreocupar al que cuida desde lejos, no llenarlo de
  alertas: cada «Estoy bien» es una falsa alarma que no le llegó
  ([riesgos.md](docs/riesgos.md#la-regla-de-oro-despreocupar-no-angustiar)).
- **La alerta vive en la base desde que nace**, con su hora de vencimiento. Si el teléfono de la
  casa muere a mitad de la cuenta (batería, golpe, apagón), la base la escala igual. El paso a
  «escalada» es una sola escritura condicional: lo intentan el vigilante y cada lectura de la
  familia, y gana uno solo ([migración](supabase/migrations/20261024130000_casa_y_familia.sql)).
- **El vigilante corre dentro de la base:** pg_cron llama a `/api/vigilar` cada 5 s con pg_net, y
  el secreto está en Vault, no en el repo ([migración](supabase/migrations/20261024200000_vigilante.sql)).
  Manda en tandas en paralelo para terminar antes de la pasada siguiente, y sella por alerta y por
  destinatario para no repetir mensajes ([`route.ts`](web/src/app/api/vigilar/route.ts)).
- **Sin login, pero sin tablas abiertas.** RLS activado sin políticas: la llave pública solo puede
  ejecutar funciones, y cada función pide la clave de la casa o el token de la familia, de 128 bits
  y guardados como SHA-256. El token `demo` es público a propósito: es el del QR.
- **El camino de la alarma no depende de un modelo de lenguaje.** Oír, preguntar, escalar y avisar
  son reglas. Claude solo lee la foto de la factura de la farmacia, con salida estructurada, y la
  familia confirma antes de guardar ([`leer/route.ts`](web/src/app/f/[token]/pastillas/factura/leer/route.ts)).
- **El inventario de pastillas es un libro de movimientos:** la factura suma, cada «Ya me la tomé»
  resta y el conteo a mano ajusta. El conteo vive en la base, para que la casa y la web no tengan
  dos números; la web calcula cuántos días alcanzan ([`inventario.ts`](web/src/lib/familia/inventario.ts)).
- **Los avisos van por Telegram,** que llega a cualquiera sin verificación de negocio. Los
  mensajes por WhatsApp con Kapso se sacaron: Meta restringió la cuenta. La casa sí llama al hijo
  por WhatsApp, desde el teléfono.
- **La casa es Android:** iOS no deja escuchar todo el día en segundo plano.

## Las pruebas

| Qué | Cuántas | Cómo |
|---|---|---|
| Web: estado de la familia, audio, inventario, factura y el tope de lecturas | 56 | `cd web && bun test` |
| Contra la base real: alertas, escalamiento y pastillas | 11 | `cd web && bun run test:integracion` (llaves en `web/.env.local`) |
| App de la casa: alerta, pastillas, pedidos y órdenes por voz, nube con cola | 121 | `make test` |
| Carga del pitch: 50 teléfonos durante 2 min | 1124 lecturas, 0 fallas, p95 1,5 s | `cd web && bun --env-file=.env.local scripts/carga.ts 50 120` |
| Carga con 150 teléfonos durante 1 min | 1653 lecturas, 0 fallas, p95 2,9 s | `… scripts/carga.ts 150 60` |
| Modelos de audio: 9 modelos, 640 clips | [resultados](experimentos/modelos-audio/resultados-1s.md) | `cd experimentos/modelos-audio && uv run comparar.py` |

La carga se midió el sábado 24-oct contra producción, desde una laptop en Caracas
([detalle](docs/pendientes.md#para-el-pitch-y-el-jurado)).

## Lo que todavía no hace

- La app de la casa sigue oyendo con la pantalla apagada gracias a un servicio en primer plano,
  pero todavía no es la pantalla de inicio del teléfono: si el teléfono se reinicia, alguien tiene
  que abrirla.
- La llamada de WhatsApp va por una vía no oficial (la fila de «llamada de voz» que WhatsApp crea
  en la agenda), y Android no dice si contestaron: por eso, si la llamada termina rápido, la casa
  pregunta «¿Pudo hablar con…?» y llama por teléfono normal.
- Si se cierra la app sin internet, se pierde lo que esperaba en la cola: vive en memoria.
- No se ha probado con voces de personas mayores reales.

Hacia dónde va el producto, en tres pasos: [futuro.md](docs/futuro.md#hacia-dónde-va).

## Cómo correrlo

```bash
# La web de la familia
cd web && bun install
bun dev        # http://localhost:3000/f/demo
bun test

# La app de la casa, en un Android conectado por USB
cp app/config/local.example.json app/config/local.json   # el número de emergencia y la clave de la casa
make run       # make muestra todos los atajos; make run-demo usa una cuenta regresiva de 15 s
```

Las llaves van en `web/.env.local` y en Vercel, nunca en el repo: está
[`web/.env.example`](web/.env.example). Cada push a `main` despliega la web; si el build falla,
producción no cambia.

## Dónde está cada cosa

```text
app/                          Flutter: el teléfono de la casa (oído, voz, alerta, pastillas, llamadas)
web/                          Next.js: la web de la familia, el vigilante y los webhooks
supabase/migrations/          el esquema, las funciones, quién puede llamar qué y el vigilante
experimentos/modelos-audio/   la comparación de modelos de audio, reproducible
docs/plan.md                  lo que se presenta, el demo y la venta
docs/contexto.md              el problema, lo que ya existe y en qué nos distinguimos
docs/riesgos.md               los muros técnicos y cómo contarlos
docs/futuro.md                hacia dónde va
docs/pendientes.md            lo que falta, con dónde está el código y cómo probarlo
docs/investigacion-*.md       alertas y apagones, audio y sensores, cómo saber si el teléfono carga
```

## Equipo

| Quién | Qué hizo |
|---|---|
| Abrahan David Quintero Teran ([@abrahanq](https://github.com/abrahanq)) | La app de la casa: el oído, la voz, las llamadas y las pastillas |
| Josuep Simon Turmero Brito ([@jkou02](https://github.com/jkou02)) | Los avisos: Telegram y el vigilante |
| Anttonny Rodelo ([@rodeloa](https://github.com/rodeloa)) | Las cifras con fuente y la investigación del problema |
| Luis Rogelio Gomez Montes ([@rogelio-electronic](https://github.com/rogelio-electronic)) | La web de la familia, la base, la orquestación y el pitch |
