# Equipo 25 · Platanus Hack 26: Caracas ft. Yummy

<img src="./project-logo.png" alt="Logo del proyecto" width="200" />

**Un teléfono viejo que cuida a los que se quedaron solos.** Enchufado en la casa de un adulto
mayor, oye y siente lo que pasa: una alarma de humo, un vidrio roto, un golpe con grito. Antes de
alertar, suena una alarma en la casa que la persona puede apagar; si nadie la apaga en 60 s,
avisa a la familia, esté donde esté. El audio se procesa en el teléfono y nunca sale de ahí.

Track: 🚨 Emergencias · Producción: https://platanus-hack-26-ve-team-25.vercel.app

- El plan, los roles y el demo: [docs/plan.md](docs/plan.md)
- Por qué, lo que ya existe y las decisiones de diseño: [docs/contexto.md](docs/contexto.md)

## Estado

| Pieza | Estado |
|---|---|
| Micrófono → compuerta de dB → YAMNet en el navegador | Prueba funcionando en [`/escucha`](https://platanus-hack-26-ve-team-25.vercel.app/escucha). Falta probarla con micrófono real |
| Vibración del piso con el acelerómetro | Por hacer |
| Alarma de confirmación de 60 s | Por hacer |
| Alertas con vencimiento y escalamiento (Supabase) | Por hacer |
| App de la familia | Por hacer |
| Aviso real (Telegram o correo) | Por decidir |

## Cómo está armado

```text
Teléfono de la casa                                    Supabase              Familia
micrófono ──► compuerta dB ──► YAMNet ──┐
acelerómetro ──► vibración del piso ────┴─► evento ─► alarma local 60 s ─► alerta ─► app de la familia
                                                       (si nadie la apaga)    └────► Telegram o correo
```

- Lo barato (el nivel en dB contra el fondo aprendido) corre con cada bloque de audio. YAMNet
  clasifica una ventana de 1 s dos veces por segundo, sobre un buffer circular de 5 s en memoria.
- Las 521 clases de YAMNet se reducen a seis tipos: alarma, vidrio, golpe, grito, TV y rutina.

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
docs/plan.md               el plan, los roles y el demo
docs/contexto.md           el porqué, la competencia y las decisiones
web/src/app/escucha/       la página de prueba del oído
web/src/lib/escucha/       lógica pura con pruebas: nivel y compuerta, buffer circular, clases de YAMNet
```

## Por dónde empieza cada rol

| Rol | Primera tarea | Dónde |
|---|---|---|
| Detección | Probar `/escucha` con alarma de humo, golpe, grito y TV; sumar el acelerómetro | `web/src/lib/escucha/` |
| Confirmación + escalamiento | La alarma de 60 s y la tabla de alertas con vencimiento en Supabase | `web/src/lib/alertas/` (nuevo) |
| App de la familia | Estado de la casa y alertas en vivo, entrando por un enlace de invitación | `web/src/app/familia/` (nuevo) |
| Datos + pitch | Las cifras con fuente y la competencia | `docs/` |

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
