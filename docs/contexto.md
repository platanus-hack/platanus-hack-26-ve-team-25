# Contexto y decisiones

Por qué el proyecto es lo que es. Sale de la apertura del evento, del primer debate del equipo y de
la mentoría con Víctor Orozco (Head of Engineering, Yummy) el viernes 23 de octubre de 2026.
Track: **Emergencias**.

## La decisión: un solo producto

El equipo llegó con dos ideas:

1. **Semáforos que abren paso a la ambulancia.**
2. **Una red de emergencias**: conectar a quien tiene una emergencia con el médico o socorrista
   registrado más cercano, con su ficha médica a mano.

La recomendación del mentor fue elegir **una**. Los semáforos tienen más ingeniería: audio, tiempo
real, control y hardware. La red de emergencias es sobre todo formularios y datos, más producto
que ingeniería. En este evento el criterio técnico pesa 25%, así que la red queda en el pitch como
visión de futuro: una plataforma general de gestión de emergencias.

## Cómo funciona

| Pieza | Qué hace | Por qué así |
|---|---|---|
| Nodo de cruce | Escucha la sirena con el micrófono | La ambulancia no necesita app, datos ni GPS. La sirena suena casi igual en todas partes y hay miles de audios para validar |
| Motor central | Abre 2 o 3 semáforos adelante según la velocidad estimada | Abrir solo uno no alcanza. Abrir toda la avenida congela el tráfico |
| Resincronización | Devuelve cada semáforo a su plan y descuenta los segundos perdidos | Sin eso se rompe la onda verde de los demás autos |
| Simulación | Ambulancia y autos en una avenida real de Caracas | Mide el tiempo de llegada con el sistema y sin él |

Se respetan el amarillo y el todo-rojo de seguridad antes de cada cambio.

## El demo

Un teléfono reproduce la sirena, el nodo la oye y los semáforos se abren en ola. Los teléfonos del
público hacen de semáforos: así lo prueba cualquiera sin hardware.

## Las objeciones que esperamos

- **En Venezuela las ambulancias se coordinan por radio y a veces no hay señal.** Por eso se detecta
  en el cruce: no depende de la ambulancia. El GPS de despacho queda como segunda vía.
- **Los semáforos no están en red.** Proponemos el hardware y la lógica. Al ser open source, sirve en
  cualquier ciudad que sí los tenga conectados o que los conecte.

## Pendiente

- El número del problema, con fuente: cuántas personas mueren por ambulancias atascadas en el
  tráfico. El pitch empieza por ahí.
