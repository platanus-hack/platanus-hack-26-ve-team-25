# Plan: semáforos que abren paso a la ambulancia

> Propuesta del 23-oct a las 22:00. **Falta que el equipo la confirme.** Si cambia, se reescribe
> aquí. El porqué está en [contexto.md](contexto.md).

## Reloj (hora de Caracas)

| Cuándo | Qué |
|---|---|
| Sáb 12:00 | Núcleo desplegado y funcionando |
| Sáb 20:00 | Taller «Cómo hacer un buen demo» (va todo el equipo) |
| Sáb 24:00 | Alcance congelado y video de respaldo grabado |
| **Dom 08:30** | **Fin del hacking. Lo que no esté pusheado no existe.** |
| Dom 10:00 | Presentaciones |

## Núcleo (meta: sábado 12:00, desplegado)

1. **Nodo de cruce en el navegador.** Micrófono → detector de sirena. MediaPipe Audio Classifier
   con YAMNet corre en el navegador y trae clases de sirena de ambulancia y de vehículo de
   emergencia. Lo primero es comprobar que detecta una sirena reproducida desde un teléfono, con
   el ruido de la sala. Encima va la lógica propia: suavizado en el tiempo y acercamiento
   (volumen creciente, Doppler).
2. **Motor central.** El corredor son los semáforos de OpenStreetMap de la avenida del CCCT. El
   motor:
   - abre 2 o 3 semáforos adelante según la velocidad estimada
   - respeta el amarillo y el todo-rojo de seguridad
   - resincroniza el plan al pasar la ambulancia
   - publica el estado en tiempo real
   - tiene pruebas: el jurado técnico las busca en el repo
3. **Simulación.** Autos con un modelo de seguimiento (IDM) que frenan en rojo, y la ambulancia.
   La métrica: tiempo de llegada con y sin el sistema, y demora de los demás autos.
4. **Los teléfonos del público son los semáforos.** Se escanea el QR y la pantalla pasa a ser el
   semáforo N de la avenida. Así el público prueba la app sin hardware.

## Extras (solo si el núcleo está listo)

- Visión: el destello rojo y azul de la ambulancia con la cámara.
- Despacho por GPS: la ambulancia disponible más cercana y su ruta.
- LEDs físicos con un ESP32. Se arman aquí: código y hardware nuevos, nada hecho antes del evento.

## Demo (3 pasos)

1. Alguien del equipo reproduce la sirena desde un teléfono.
2. La laptop la oye y los teléfonos del público se ponen en verde en ola, de adelante hacia atrás.
3. La simulación muestra cuánto antes llegó la ambulancia y cómo se recupera el tráfico.

Respaldo: un video grabado del mismo flujo.

## Roles

| Rol | Qué | Quién |
|---|---|---|
| Detección | Audio, y visión si da el tiempo | |
| Motor + tiempo real | Corredor, tiempos, resincronización, publicación del estado | |
| Simulación + panel | Mapa, autos, métricas, vista de semáforo para teléfonos | |
| Datos + pitch | El número del problema con fuente, las objeciones, el README de arquitectura y el video | |

## Infra (presupuesto cero)

- **Web:** Next.js en Vercel, plan gratis. Producción:
  https://platanus-hack-26-ve-team-25.vercel.app. Por ahora el deploy es manual desde la cuenta
  de Rogelio (`vercel --prod` en `web/`).
- **Tiempo real:** Supabase Realtime, plan gratis, suficiente para ~100 teléfonos a la vez.
  Render gratis se duerme a los 15 minutos sin uso: no sirve para el demo.
- **Motor:** TypeScript, en el navegador del panel o como proceso Node. Se decide al construirlo.
- **Detector:** corre en el navegador, no cuesta nada por uso.

## Cómo trabajamos

- Commits chicos y push seguido: el repo es lo que se juzga.
- Deploy después de cada avance grande.
- Datos de prueba inventados. Nada real de nadie.
- Nada de llaves ni `.env` en el repo: es público.

## Pendiente

- [ ] El equipo confirma este plan
- [ ] Nombres en la tabla de roles
- [ ] El número del problema, con fuente
