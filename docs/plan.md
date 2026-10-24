# Plan: un teléfono viejo que cuida a los que se quedaron solos

> Decidido el sábado 24-oct a las 00:30 y validado con el mentor. Si cambia, se reescribe aquí.
> El porqué, lo que ya existe y las decisiones de diseño están en [contexto.md](contexto.md).

## Reloj (hora de Caracas)

| Cuándo | Qué |
|---|---|
| Sáb 12:00 | Núcleo desplegado y funcionando |
| Sáb 20:00 | Taller «Cómo hacer un buen demo» (va todo el equipo) |
| Sáb 24:00 | Alcance congelado y video de respaldo grabado |
| **Dom 08:30** | **Fin del hacking. Lo que no esté pusheado no existe.** |
| Dom 10:00 | Presentaciones |

## El flujo del MVP

1. El teléfono de la casa oye (y siente el piso) un posible evento: alarma de humo, vidrio roto,
   golpe con vibración, grito.
2. Suena una alarma fuerte en la casa: «¿Está bien? Toque la pantalla para apagar». La pantalla
   destella y vibra.
3. Si nadie la apaga en 60 s, se avisa al contacto de emergencia: en la app de la familia y por un
   canal real.
4. Cada alarma que la persona apaga queda anotada como falsa alarma de esa casa y ajusta sus
   umbrales.

## Núcleo (meta: sábado 12:00, desplegado)

1. **El oído.** Micrófono → compuerta de dB → YAMNet en el navegador (ya existe como prueba en
   `/escucha`). Se suma el acelerómetro para la vibración del piso y se combinan las dos señales
   en un evento con su confianza.
2. **La confirmación en la casa.** Alarma, cuenta regresiva de 60 s y un botón grande para apagar.
3. **El escalamiento que no depende de un solo teléfono.** La casa registra la alerta con su hora
   de vencimiento. Si nadie la cancela, el primero que vea el vencimiento (la casa o cualquier
   teléfono de la familia) la escala, y solo una vez: el cambio de estado es atómico. Si la casa
   deja de reportar, la familia ve «sin señal desde las 14:05».
4. **La app de la familia.** Estado de la casa en vivo (última actividad, TV, luz), alertas e
   historial del día. Sin login: se entra con un enlace de invitación, que en el demo es un QR.
5. **La rutina.** «Se levantó a las 7:12» y aviso si a la hora de siempre no hubo actividad. Si no
   llega al sábado 12:00, va después.

## Extras (solo si el núcleo está listo)

- Voz: «Carmen, ¿está bien?», y que pueda responder hablando.
- El vecino de confianza como segundo escalón.
- Detectar el apagón porque el teléfono dejó de cargar.

## Demo

1. Un teléfono en la tarima es la casa de «la señora Carmen» (inventada). El público escanea el QR
   y su teléfono pasa a ser la familia.
2. Suena una alarma de humo. En la tarima suena la alarma de confirmación, nadie la apaga y a los
   60 s (15 s en modo demo) les llega el aviso a todos los teléfonos.
3. Cae un morral junto al teléfono: golpe más vibración. Esta vez «Carmen» apaga la alarma y se ve
   que no escala.
4. Se prende la TV con una escena de gritos: no dispara, porque el piso no tembló.

## Roles

| Rol | Qué | Quién |
|---|---|---|
| Detección | Audio, vibración, fusión de señales, umbrales por casa | |
| Confirmación + escalamiento | Alarma local, vencimientos, estado atómico, canal real de aviso | |
| App de la familia + demo | Estado en vivo, alertas, historial, invitación por QR | |
| Datos + pitch | Las cifras con fuente, la competencia, el README de arquitectura y el video | |

## Infra (presupuesto cero)

- **Web:** Next.js en Vercel, plan gratis. Producción:
  https://platanus-hack-26-ve-team-25.vercel.app. Por ahora el deploy es manual desde la cuenta
  de Rogelio (`vercel --prod` en `web/`).
- **Estado y tiempo real:** Supabase, plan gratis.
- **Detección:** corre en el teléfono, sin costo por uso. El audio nunca sale del teléfono.
- **Aviso real:** correo o Telegram, que son gratis. El SMS cuesta: se decide si hay presupuesto.

## Cómo trabajamos

- Commits chicos y push seguido: el repo es lo que se juzga.
- Deploy después de cada avance grande.
- Datos de prueba inventados. Nada real de nadie.
- Nada de llaves ni `.env` en el repo: es público.

## Pendiente

- [ ] Probar `/escucha` con micrófono real: alarma de humo, golpe, grito, TV
- [ ] Nombres en la tabla de roles
- [ ] Cifras con fuente: venezolanos emigrados (R4V), adultos mayores que viven solos, caídas
- [ ] Elegir el canal real de aviso: correo o Telegram
