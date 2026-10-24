# Plan: de los mockups al código

Cómo pasar a código las 7 pantallas del
[lienzo de mockups](https://claude.ai/artifact/BgbTMPcFXsC9qxitsmk1f2): 4 de la app de la casa
(Flutter) y 3 de la web de la familia (Next.js). El lienzo es privado: pídele acceso a Abrahan.
Escrito el sábado 24-oct a las 04:15, con la meta de P0 a las 12:00
([plan.md](plan.md#reloj-hora-de-caracas)).

## La regla: pantallas con datos simulados primero

Las pantallas se construyen **ya**, con datos inventados, sin esperar a la detección ni a
Supabase. Para eso las dos partes usan **la misma forma de datos** (abajo). Cuando Supabase esté
listo, solo se cambia de dónde vienen los datos; las pantallas no se tocan.

## El contrato: la misma forma en Dart y en TypeScript

Va en `app/lib/dominio/` (Dart) y en `web/src/lib/familia/tipos.ts` (TypeScript). Si cambia en
un lado, cambia en el otro en el mismo commit.

```text
Casa
  id, nombre ("Carmen"), condiciones (["oxigeno", "hipertension"])
  contactos: [{ nombre, relacion, canal: "telegram" | "llamada", orden }]
  ultimoLatido (fecha y hora), enchufado (sí/no), bateria (0–100)

Evento                        lo que oyó o sintió el teléfono, o lo que tocó la persona
  id, casaId, hora
  tipo: alarma | vidrio | golpe | grito | rutina | apagon | panico | huele_gas | me_siento_mal | estoy_bien
  descripcion ("Agua en la cocina")

Alerta                        un evento que pidió confirmación
  id, casaId, eventoId, nivel: rojo | amarillo | verde
  estado: pendiente → cancelada        (la persona tocó «Estoy bien»)
          pendiente → escalada → atendida  (nadie respondió, o «Necesito ayuda» o pánico)
  creada, venceEn (creada + 60 s; 15 s en modo demo), escaladaEn, atendidaPor
```

El estado de la pantalla de la familia **se deriva** de esos datos: si hay una alerta roja
escalada sin atender, es «Alerta urgente»; si no, «Todo bien», con los amarillos del día debajo.

## App de la casa (Flutter)

```text
app/
  lib/
    main.dart
    tema.dart                 colores, tipografía Atkinson Hyperlegible, tamaños de botón
    dominio/                  Dart puro, con pruebas (dart test)
      tipos.dart              Casa, Evento, Alerta
      alerta.dart             la máquina de estados y la cuenta regresiva
    ui/
      raiz.dart               muestra la pantalla según el estado: reposo, alarma o ayuda
      reposo.dart
      alarma.dart
      ayuda.dart
      configurar.dart
      componentes/boton_grande.dart
    datos/simulado.dart       una casa y eventos inventados; después, Supabase
  assets/
    fuentes/AtkinsonHyperlegible-*.ttf
    sonidos/alarma_520hz.wav
```

- **Sin rutas ni menús.** La casa no navega: `raiz.dart` muestra una pantalla u otra según el
  estado de la alerta. Así nadie puede «perderse» en la app.
- **La fuente va dentro de la app**, no se baja de internet: tiene que verse bien sin conexión.
- **La máquina de estados de la alerta es Dart puro** y lleva pruebas. Es lo que el agente del
  jurado va a revisar primero.

| # | Pantalla | Qué tiene que hacer | Detalle | Terminada cuando |
|---|---|---|---|---|
| 1 | **¿Está bien?** (`alarma.dart`) | Cuenta regresiva de 60 s (15 s en modo demo), «Estoy bien» cancela, «Necesito ayuda» escala ya | Tono de 520 Hz en onda cuadrada en bucle, vibración, el fondo destella. Pasar la mano por encima (sensor de proximidad) cuenta como «Estoy bien» | Se dispara con un botón de prueba, cuenta, y cada salida lleva al estado correcto |
| 2 | **Avisando a la familia** (`ayuda.dart`) | Muestra a quién se avisó y su estado. «Fue sin querer» cancela | Los estados de los contactos vienen de los datos, simulados por ahora | Llega desde 1 o desde el pánico y vuelve a reposo al cancelar |
| 3 | **En reposo** (`reposo.dart`) | Reloj, estado «Cuidando la casa», pánico y los tres botones de la persona | Fondo negro y brillo bajo. «Pedir ayuda» va directo a 2. «Huele a gas» y «Me siento mal» son 🔴. «Estoy bien hoy» es el 🟢 del día | Cada botón crea el evento correcto |
| 4 | **Configuración** (`configurar.dart`) | Nombre, contactos, salud y QR | Para el demo puede quedar con datos fijos. El QR lleva el enlace de invitación | P1: el demo funciona sin ella |

Paquetes ([investigacion-audio.md §4](investigacion-audio.md)): `flutter_foreground_task`,
`proximity_sensor`, `wakelock_plus` o equivalente para la pantalla encendida, `vibration` y un
reproductor de audio para el tono (por confirmar cuál).

## Web de la familia (Next.js, en `web/`)

```text
web/src/
  app/
    f/[token]/page.tsx        la casa vista por la familia
    demo/page.tsx             el QR gigante para el pitch
    page.tsx                  la raíz: lleva a la última casa abierta en este teléfono
  components/familia/
    estado-todo-bien.tsx
    alerta-urgente.tsx
    para-saber.tsx
    su-dia.tsx
  lib/familia/
    tipos.ts                  el contrato
    estado.ts                 deriva qué mostrar a partir de los datos, con pruebas (bun test)
    simulado.ts               tres escenarios inventados: todo-bien, alerta y para-saber
```

- **Escenarios simulados por URL**: `/f/demo?escenario=alerta` muestra la alerta sin backend.
  Sirve para construir, para probar y como respaldo en el pitch.
- **La raíz recuerda la casa:** al abrir `/f/[token]` se guarda el token en el teléfono. La web
  instalada abre `/`, que lleva a esa casa. Sin esto, el ícono abriría la plantilla de Next.js.
- La fuente Atkinson Hyperlegible entra con `next/font/google`, igual que Geist hoy.

| # | Pantalla | Qué tiene que hacer | Terminada cuando |
|---|---|---|---|
| 5 | **Alerta urgente** | Pantalla roja: qué pasó, qué ya hicimos, llamar a Carmen, llamar al vecino, «Ya hablé con ella» | Se ve con `?escenario=alerta`, los botones `tel:` marcan y «Ya hablé» la marca como atendida |
| 6 | **Todo bien** | Estado verde, conexión de la casa y su día en línea de tiempo | Se ve con `?escenario=todo-bien` y la hora del último latido es relativa («hace 1 min») |
| 7 | **Para saber** | Los avisos amarillos del día, sin sonido | Se ve con `?escenario=para-saber` |
| 8 | **`/demo`** | El QR gigante que lleva a `/f/demo` | El público lo escanea desde las sillas |

## El orden de trabajo

Se ordena por el demo: primero lo que se ve en el pitch.

| Bloque | Casa (Flutter) | Familia (web) |
|---|---|---|
| **04:30–07:00** | Proyecto en `app/`, tema, `tipos.dart` y la máquina de estados con pruebas | `tipos.ts`, `simulado.ts`, `estado.ts` con pruebas y la pantalla 5, alerta urgente |
| **07:00–09:30** | Pantallas 1 y 2, ¿Está bien? y avisando a la familia, con sonido y vibración | Pantalla 6, todo bien, la 7, para saber, y `/demo` con el QR |
| **09:30–12:00** | Pantalla 3, reposo, y conectar la alerta a Supabase | Cambiar `simulado.ts` por Supabase en tiempo real y hacer deploy |
| Después de las 12:00 | Pantalla 4, configuración, y la proximidad | La raíz que recuerda la casa y el pulido |

Quién: la casa, los dos del equipo con experiencia en Flutter; la familia y el diseño, Rogelio
([plan.md](plan.md#roles)). La detección (Abrahan) se conecta a la pantalla 1 cuando esté: hasta
entonces la dispara un botón de prueba.

## Lo que no entra en P0

- Notificaciones web: la alerta 🔴 llega por Telegram.
- La voz que pregunta «Carmen, ¿está bien?» y la palabra clave.
- El modo kiosco completo. En P0 basta la pantalla encendida mientras carga.
