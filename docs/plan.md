# Plan: un teléfono viejo que cuida a los que se quedaron solos

> Decidido el sábado 24-oct a las 00:30 y validado con el mentor. Si cambia, se reescribe aquí.
> El porqué, lo que ya existe y las decisiones de diseño están en [contexto.md](contexto.md).
> Lo que puede fallar: [riesgos.md](riesgos.md). Las preguntas de cada uno: [investigacion.md](investigacion.md).
> Lo que no hacemos ahora pero sí en el producto: [futuro.md](futuro.md).

## Decisiones del equipo (sábado 24-oct)

- **Para el hackatón, una app y una web.** El teléfono de la casa usa una app **Flutter en
  Android**. La familia entra por **web**, con un enlace o un QR, para que el público la pruebe en
  el pitch sin instalar nada.
- **La versión final es una sola app para todos**, con dos roles: la casa y la familia
  ([futuro.md](futuro.md)).
- **Supabase** para la base de datos, por ahora.
- **Lo que se pueda, en el teléfono** y en caché. A la base solo va lo relevante: eventos,
  alertas, latidos y el perfil de la casa.
- **Un filtro muy bueno antes de avisar.** La meta es despreocupar al que cuida desde lejos, no
  llenarlo de alertas. Tres niveles: 🔴 urgente, 🟡 para saber, 🟢 todo bien
  ([riesgos.md](riesgos.md#la-regla-de-oro-despreocupar-no-angustiar)).
- **El perfil de salud cambia las reglas.** Un apagón no es igual para una persona hipertensa que
  para una que usa oxígeno. Reglas generales por condición más calibración por casa
  ([investigacion.md](investigacion.md#el-perfil-de-salud)).
- **El cliente es el que cuida**, el hijo o el familiar que está lejos. El adulto mayor confía
  porque su familia confía.
- **Aviso real por Telegram:** es gratis y suena en iOS y en Android.
- **Se vende como un acompañante del día a día, y el oído sigue siendo el centro.** El pitch abre
  con lo de todos los días (la pastilla, la llamada con un toque) y llega a la alarma. No es un
  asistente médico: ya hubo proyectos así en Platanus (Tata y Memo, PH25), el track es Emergencias
  y lo original es el oído. No se construye nada nuevo hasta que P0 esté desplegado.

## Reloj (hora de Caracas)

| Cuándo | Qué |
|---|---|
| Sáb 12:00 | P0 desplegado y funcionando |
| Sáb 20:00 | Taller «Cómo hacer un buen demo» (va todo el equipo) |
| Sáb 24:00 | Alcance congelado y video de respaldo grabado |
| **Dom 08:30** | **Fin del hacking. Lo que no esté pusheado no existe.** |
| Dom 10:00 | Presentaciones |

## El flujo del MVP

1. El teléfono de la casa oye (y siente el piso) un posible evento: alarma de humo, vidrio roto,
   golpe con vibración, grito.
2. Suena una alarma fuerte en la casa: «¿Está bien?», con dos botones grandes: **Estoy bien** y
   **Necesito ayuda**. La pantalla destella y vibra.
3. Si nadie responde en 60 s, se avisa al contacto de emergencia: en la web de la familia y por
   Telegram.
4. Cada alarma que la persona apaga queda anotada como falsa alarma de esa casa y ajusta sus
   umbrales.

## Prioridades

Se trabaja de arriba hacia abajo. Nada de P1 hasta que P0 esté desplegado.

### P0 · El núcleo (meta: sábado 12:00, desplegado)

1. **El oído.** Micrófono → compuerta de dB → YAMNet en la app de la casa. Se suma el
   acelerómetro para la vibración del piso y se combinan las dos señales en un evento con su
   confianza. La prueba en web ya existe en `/escucha`.
2. **La confirmación en la casa.** Alarma, cuenta regresiva de 60 s, «Estoy bien» y «Necesito
   ayuda». Siempre en pantalla: el **botón de pánico** (🔴 directo, sin los 60 s).
3. **El escalamiento que no depende de un solo teléfono.** La casa registra la alerta con su hora
   de vencimiento. Si nadie la cancela, el primero que vea el vencimiento (la casa o cualquier
   teléfono de la familia) la escala, y solo una vez: el cambio de estado es atómico.
4. **El latido.** La casa reporta cada pocos minutos. Si deja de hacerlo, la familia ve «sin
   señal desde las 14:05».
5. **El aviso real por Telegram.**
6. **La web de la familia.** Estado de la casa en vivo, alertas e historial del día. Sin login: se
   entra con un enlace de invitación, que en el demo es un QR.

### P1 · Si P0 está listo (sábado en la tarde)

- **Perfil de salud y apagón.** Se detecta el apagón porque el teléfono deja de cargar, y el
  perfil decide si es 🔴 o 🟡. Es el paso 5 del demo.
- **Los tres niveles de aviso** con su tope diario.
- **La persona como sensor:** «Huele a gas», «Huele a quemado», «Me siento mal».
- **El recordatorio de pastillas:** la misma pregunta y los mismos botones de la alarma («¿Ya se
  tomó la de las 8?»). Sin respuesta, aviso 🟡. Cada respuesta cuenta como señal de que está bien.
- **Modo kiosco nivel 1:** la app como pantalla de inicio, con servicio en primer plano
  ([riesgos.md](riesgos.md#3-el-modo-kiosco-que-la-app-no-se-muera)).
- **Sin conexión:** cola local que se reenvía al volver la señal, y aviso de batería baja y de
  temperatura.
- **La rutina:** conteos por franja del día, y aviso si falta lo de siempre.

### P2 · Solo si sobra tiempo antes de las 24:00

- Palabra clave por voz («¡auxilio!») con el reconocimiento del sistema, sin conexión.
- Llamada en altavoz o SMS al vecino desde el chip cuando no hay internet (APK fuera de Play).
- El resumen 🟢 de cada mañana.
- Voz: «Carmen, ¿está bien?», y que pueda responder hablando.

Todo lo demás está en [futuro.md](futuro.md).

## Demo

1. Un teléfono en la tarima es la casa de «la señora Carmen» (inventada). El público escanea el QR
   y su teléfono pasa a ser la familia.
2. Suena una alarma de humo. En la tarima suena la alarma de confirmación, nadie la apaga y a los
   60 s les llega el aviso a todos los teléfonos. Los tiempos del demo son los del producto: nada
   se acelera.
3. Cae un morral junto al teléfono: golpe más vibración. Esta vez «Carmen» toca «Estoy bien» y se
   ve que no escala.
4. Se prende la TV con una escena de gritos: no dispara, porque el piso no tembló.
5. *(P1)* Se desenchufa el teléfono: «se fue la luz». En la casa de Carmen, que usa oxígeno, es
   🔴. En otra casa del demo es solo 🟡. El mismo evento, dos avisos.

## Roles

| Rol | Qué | Quién |
|---|---|---|
| Detección e IA | Modelo local o nube, YAMNet en Flutter, vibración, fusión, umbrales por casa, la persona como sensor | Abrahan |
| Alertas y conexión | Pánico, «¿Está bien?», filtro de falsos positivos, niveles, escalamiento, aviso sin señal o sin luz | Josuep |
| Datos y usuarios | Cifras con fuente, diáspora, usuarios potenciales, testimonios, competencia | Anttony |
| Orquestación, UX/UI y riesgos | Organización, huecos y muros, viabilidad, deploy, pitch. Programa la UI con el equipo | Rogelio |

**Quién construye qué:**

| Pieza | Quién |
|---|---|
| App Flutter de la casa | Los dos con experiencia en Flutter *(nombres por confirmar)* |
| Web de la familia y UI/UX de las dos pantallas | Rogelio |
| Supabase y Telegram | *(por confirmar)* |

## Infra (presupuesto cero)

- **Web de la familia:** Next.js en Vercel, plan gratis. Producción:
  https://platanus-hack-26-ve-team-25.vercel.app. Por ahora el deploy es manual desde la cuenta
  de Rogelio (`vercel --prod` en `web/`).
- **App de la casa:** Flutter, APK para Android instalado a mano.
- **Estado y tiempo real:** Supabase, plan gratis.
- **Detección:** corre en el teléfono, sin costo por uso. El audio nunca sale del teléfono.
- **Aviso real:** bot de Telegram, gratis.

## Cómo trabajamos

- Commits chicos y push seguido: el repo es lo que se juzga.
- Deploy después de cada avance grande.
- Datos de prueba inventados. Nada real de nadie.
- Nada de llaves ni `.env` en el repo: es público.

## Pendiente

- [ ] Nombres de quién construye cada pieza
- [ ] Contarle a Víctor el enfoque del día a día
- [ ] **Volver a probar `/escucha` con la música alta de la oficina, ya con las clases nuevas.**
  Ojo: el clasificador devuelve solo las 10 clases más probables (`maxResults: 10`). Con música
  fuerte, las 10 pueden ser todas de música y la alarma de humo quedar fuera aunque suene. Si
  pasa, se filtra por nuestras clases (`categoryAllowlist`) en vez de pedir el top 10
- [ ] Probar la vibración en piso de cerámica o concreto, que es el de las casas venezolanas
- [ ] Cifras con fuente: ver [investigacion.md](investigacion.md#anttony--antecedentes-y-usuarios)
