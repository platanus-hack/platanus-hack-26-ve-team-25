# Equipo 25 · Platanus Hack 26: Caracas ft. Yummy

<img src="./project-logo.png" alt="Logo del proyecto" width="200" />

**Un teléfono viejo que cuida a los que se quedaron solos.** Enchufado en la casa de un adulto
mayor, oye y siente lo que pasa: una alarma de humo, un vidrio roto, un golpe con grito. Antes de
alertar, suena una alarma en la casa que la persona puede apagar; si nadie la apaga en 60 s,
avisa a la familia, esté donde esté. El audio se procesa en el teléfono y nunca sale de ahí.

Track: 🚨 Emergencias · Producción: https://platanus-hack-26-ve-team-25.vercel.app

- El plan, los roles y el demo: [docs/plan.md](docs/plan.md)
- De los mockups al código, pantalla por pantalla: [docs/pantallas.md](docs/pantallas.md)
- Por qué, lo que ya existe y las decisiones de diseño: [docs/contexto.md](docs/contexto.md)
- Dónde puede fallar y cómo lo evitamos: [docs/riesgos.md](docs/riesgos.md)
- Las preguntas abiertas de cada uno: [docs/investigacion.md](docs/investigacion.md)
- Lo que va después del hackatón: [docs/futuro.md](docs/futuro.md)
- Preguntas técnicas, con la evidencia de cada respuesta: [docs/preguntas-tecnicas.md](docs/preguntas-tecnicas.md)
- Comparación de modelos de audio: [experimentos/modelos-audio](experimentos/modelos-audio/README.md)

## Estado

| Pieza | Estado |
|---|---|
| Micrófono → compuerta de dB → YAMNet en el navegador | Prueba funcionando en [`/escucha`](https://platanus-hack-26-ve-team-25.vercel.app/escucha). Falta probarla con micrófono real |
| Pruebas automáticas de la lógica de audio | 12 pruebas de nivel, compuerta, buffer circular y clases, con `bun test` |
| Comparación de 9 modelos de audio | Hecha y reproducible sobre 640 sonidos de casa: [experimentos/modelos-audio](experimentos/modelos-audio/README.md) |
| Vibración del piso con el acelerómetro | Por hacer |
| Alarma de confirmación de 60 s, botón de pánico y reportes de la persona | Por hacer |
| Perfil de salud y niveles de aviso (🔴 🟡 🟢) | Por hacer |
| App del teléfono de la casa en Flutter | Las 4 pantallas con datos simulados y la máquina de estados de la alerta, con 12 pruebas: [`app/`](app/README.md). Falta el oído, Supabase, sonido y sensores |
| Alertas con vencimiento y escalamiento (Supabase) | Por hacer |
| Web de la familia instalable (PWA) | Hecha la base: manifiesto, íconos y metadatos para Android e iPhone. Faltan las pantallas |
| Aviso real por Telegram | Decidido; falta implementarlo |

## Cómo está armado

```text
Teléfono de la casa                                                          Supabase     Familia
micrófono ──► compuerta dB ──► YAMNet ──┐
acelerómetro ──► vibración del piso ────┴─► evento ──► alarma local 60 s
                                                        (si nadie la apaga)
                                                        │
                                                        ▼
                                                        T1 · HTTP (10 s) ──► Supabase ──► web de la familia
                                                        │                                 └────► Telegram
                                                           falla o timeout
                                                        ▼
                                                        T2 · llamada local (25 s) ──► vecino
                                                        ▼
                                                        T3 · SMS local ──► vecino

latido periódico ───────────────────► sin latido = «sin señal» en la web
```

- Lo barato (el nivel en dB contra el fondo aprendido) corre con cada bloque de audio. YAMNet
  clasifica una ventana de 1 s dos veces por segundo, sobre un buffer circular de 5 s en memoria.
- Las 521 clases de YAMNet se reducen a seis tipos: alarma, vidrio, golpe, grito, TV y rutina.
- **El escalamiento empieza a los 60 s**, cuando la alarma ya venció y nadie la apagó, y los
  canales van en serie: primero el POST, después la llamada y al final el SMS. Los contactos de
  llamada y SMS son locales; al exterior solo llega el POST
  ([investigacion-alertas.md](docs/investigacion-alertas.md)).
- **El perfil de salud decide el nivel del aviso.** El mismo apagón es 🔴 en una casa con oxígeno y
  🟡 en una casa sin equipo eléctrico: el evento no fuerza urgencia por sí solo.

## Cómo correrlo

```bash
cd web
bun install
bun dev     # http://localhost:3000/escucha
bun test    # pruebas de la lógica de audio
```

El micrófono de un teléfono solo funciona con HTTPS. Para probar desde el teléfono, usa la URL de
producción o abre un túnel: `cloudflared tunnel --url http://localhost:3000`.

## Dónde está cada cosa

```text
docs/plan.md                     el plan, los roles y el demo
docs/pantallas.md                de los mockups al código: contrato de datos y orden de las pantallas
docs/contexto.md                 el porqué, la competencia y las decisiones
docs/riesgos.md                  los muros, los huecos y cómo hacer que sume y no reste
docs/preguntas-tecnicas.md       las preguntas frecuentes, con la evidencia de cada respuesta
docs/investigacion-alertas.md    entrega, escalamiento tras los 60 s y detección del apagón
docs/investigacion-audio.md      la voz del adulto mayor, modelos de audio y sensores
docs/investigacion-carga.md      cómo se sabe si el teléfono está cargando
docs/investigacion.md            las preguntas abiertas de cada uno
docs/futuro.md                   las mejoras a futuro
experimentos/modelos-audio/      la comparación de modelos de audio, reproducible
web/src/app/escucha/             la página de prueba del oído
web/src/lib/escucha/             lógica pura con pruebas: nivel y compuerta, buffer circular, clases de YAMNet
```

## Por dónde empieza cada rol

| Rol | Quién | Primera tarea |
|---|---|---|
| Detección e IA | Abrahan | Probar `/escucha` con alarma de humo, golpe, grito y TV; YAMNet en Flutter |
| Alertas y conexión | Josuep | Niveles de aviso, alarma de 60 s, pánico y la tabla de alertas con vencimiento en Supabase |
| Datos y usuarios | Anttony | Las cifras con fuente y dos o tres testimonios |
| Orquestación, UX/UI y riesgos | Rogelio | Cerrar el reparto Flutter / web, las pantallas y [docs/riesgos.md](docs/riesgos.md) |

## Cómo trabajamos

- Commits chicos y push seguido: el repo es lo que se juzga.
- El deploy lo hace Rogelio con `vercel --prod` desde `web/`.
- Nada de llaves ni `.env` en el repo: es público.
- Datos de prueba inventados. Nada real de nadie.

## Equipo

- Josuep Simon Turmero Brito ([@jkou02](https://github.com/jkou02))
- Anttonny Rodelo ([@rodeloa](https://github.com/rodeloa))
- Abrahan David Quintero Teran ([@abrahanq](https://github.com/abrahanq))
- Luis Rogelio Gomez Montes ([@rogelio-electronic](https://github.com/rogelio-electronic))
