# Guía del repo para agentes

Proyecto del equipo 25 en Platanus Hack 26 (Caracas, 23–25 de octubre de 2026), track
Emergencias. Este archivo resume qué hay en el repo y dónde, para que un agente responda
preguntas o trabaje en él sin leerlo todo. Todo lo que dice aquí se puede verificar en los
archivos enlazados. Si algo no coincide con el código, manda el código.

## Qué es

Un teléfono Android viejo, enchufado en la casa de un adulto mayor que vive solo, oye y siente lo
que pasa: alarma de humo, vidrio roto, golpe, grito o quejido. Antes de avisar, suena una alarma
en la casa que la persona apaga si está bien. Si nadie la apaga en 60 s, avisa a la familia, que
suele estar en otro país. El audio se procesa en el teléfono y nunca sale de él.

## Estado real (24-oct-2026)

| Pieza | Estado | Dónde |
|---|---|---|
| Oído en el navegador: micrófono → compuerta de dB → YAMNet → 6 tipos de evento | Prueba de viabilidad funcionando y desplegada | [`web/src/app/escucha/`](web/src/app/escucha/), [`web/src/lib/escucha/`](web/src/lib/escucha/) |
| Pruebas automáticas de la lógica de audio | 12 pruebas: nivel en dB, fondo de la casa, compuerta, buffer circular, clases de YAMNet | [`web/src/lib/escucha/escucha.test.ts`](web/src/lib/escucha/escucha.test.ts) |
| Comparación de 9 modelos de audio (YAMNet, EfficientAT, PANNs, sherpa-onnx) en 640 sonidos de casa | Hecha y reproducible, con resultados | [`experimentos/modelos-audio/`](experimentos/modelos-audio/README.md) |
| Web de la familia instalable (PWA): manifiesto, íconos provisionales y metadatos para Android e iPhone | Hecho. La web de la familia en sí está por hacer | [`web/src/app/manifest.ts`](web/src/app/manifest.ts), [`web/src/lib/app.ts`](web/src/lib/app.ts) |
| App Flutter del teléfono de la casa | Horizontal como reloj de mesa: reposo con pastillas, «¿Está bien?» con deslizador, llamada directa al primer contacto y recordatorio de pastillas. Oye con YAMNet en el teléfono. 35 pruebas. Falta Supabase, Telegram, sonido y vibración | [`app/`](app/README.md) |
| La app de la casa compilada para web, instalable | Publicada en https://platanus-hack-26-ve-team-25-casa.vercel.app. Sin oído ni llamadas: en web, TFLite se cambia por una versión vacía con una importación condicional. Vercel baja Flutter 3.47.5 y compila | [`app/lib/oido/tflite_web.dart`](app/lib/oido/tflite_web.dart), [`app/tool/vercel_build.sh`](app/tool/vercel_build.sh) |
| Alarma de confirmación de 60 s, botón de pánico | Por hacer | — |
| Alertas con vencimiento y escalamiento en Supabase | Diseñado, por hacer | [`docs/plan.md`](docs/plan.md) |
| Web de la familia y aviso por Telegram | Por hacer | — |
| Vibración del piso, rutina de la casa, otros sensores | Diseñado, por hacer | [`docs/investigacion-audio.md`](docs/investigacion-audio.md) |

La raíz del sitio desplegado todavía es la plantilla de Next.js. La prueba está en `/escucha`.

## Mapa del repo

```text
README.md                         presentación, estado y cómo correrlo
docs/preguntas-tecnicas.md        preguntas técnicas frecuentes, con la evidencia de cada respuesta
docs/pendientes.md                lo que falta, en orden, con dónde está el código y cómo probarlo
docs/plan.md                      decisiones del equipo, prioridades P0–P2, demo y roles
docs/pantallas.md                 plan para pasar los mockups a código: contrato de datos, estructura y orden
docs/contexto.md                  el problema, la competencia y las decisiones de diseño
docs/riesgos.md                   muros técnicos (kiosco, apagones, batería), riesgos del demo
docs/investigacion-alertas.md     capa de alertas: transporte, escalamiento, apagones y perfil energético
docs/investigacion-audio.md       voz del adulto mayor, modelos, sensores y paquetes de Flutter
docs/investigacion-carga.md       cómo se sabe si el teléfono está cargando: señales de Android y battery_plus
docs/investigacion.md             preguntas abiertas por persona del equipo
docs/futuro.md                    lo que va después del hackatón
app/                              Flutter: la app del teléfono de la casa
web/                              Next.js: la prueba /escucha (YAMNet en el navegador con MediaPipe)
experimentos/modelos-audio/       Python con uv: exportación a ONNX y comparación de modelos
```

## Decisiones técnicas clave

- **Todo lo posible en el teléfono.** El audio vive solo en un buffer circular de 5 s en memoria
  ([`anillo.ts`](web/src/lib/escucha/anillo.ts)). Al servidor van etiquetas de eventos, alertas y
  latidos, nunca audio.
- **Lo barato corre siempre y el modelo confirma.** Una compuerta de dB contra el fondo aprendido
  de la casa ([`nivel.ts`](web/src/lib/escucha/nivel.ts)) corre con cada bloque de audio. En la
  prueba `/escucha`, YAMNet clasifica dos veces por segundo siempre y la compuerta solo se anota
  junto a cada evento. Que la compuerta decida cuándo despertar al modelo, para ahorrar batería,
  es el diseño de la app y está por hacer.
- **El audio llega crudo al modelo.** Sin supresión de ruido ni control de volumen, porque esos
  filtros borran golpes y alarmas
  ([`escucha.tsx`](web/src/app/escucha/escucha.tsx), [razón](docs/investigacion-audio.md)).
- **YAMNet como modelo base**, elegido con la comparación de `experimentos/modelos-audio`. El
  candidato alternativo es sherpa-onnx CED con ventanas de 5 s.
- **Stack del hackatón:** Flutter en Android para la casa, web para la familia, Supabase,
  Telegram. La casa no puede ser iOS: no deja escuchar todo el día en segundo plano.

## Cómo correr las pruebas

```bash
cd web && bun install && bun test
cd app && flutter test
cd experimentos/modelos-audio && uv sync && ./descargar.sh && uv run comparar.py
```

## Reglas para trabajar en el repo

- Español en el código, los comentarios, los documentos y los commits.
- Commits chicos con prefijo (`feat`, `fix`, `docs`, `chore`) y push seguido.
- El repo es público: nada de llaves, `.env`, grabaciones de personas ni datos reales. Los datos
  de prueba son inventados.
- Al terminar una pieza, actualizar la tabla de estado de este archivo y la del README.
- En `web/` aplica además [`web/AGENTS.md`](web/AGENTS.md): esta versión de Next.js tiene cambios
  que no están en los datos de entrenamiento.
