## El problema

Muchos venezolanos emigraron y sus padres mayores se quedaron viviendo solos. Si se caen o suena
una alarma de humo, nadie se entera a tiempo. Hoy la familia lo resuelve llamando varias veces al
día.

## Qué hace

Un teléfono Android viejo, enchufado en la casa, oye lo que pasa: una alarma de humo, un vidrio
roto, un golpe, un grito o un quejido.

1. Cuando oye algo, suena una alarma en la casa: «¿Está bien?». **Estoy bien** se desliza en un
   riel ancho, para que no se active con un roce; **Necesito ayuda** es un solo toque.
2. Si nadie responde en 60 segundos, la casa llama por teléfono al primer contacto de la familia,
   una sola vez.
3. La persona también puede avisar sin esperar: **Pedir ayuda**, **Huele a gas** o
   **Me siento mal** llaman de inmediato.

Una falsa alarma le cuesta un gesto a la persona, no un susto a la familia.

## Todos los días, no solo el día malo

Un aparato que solo sirve para emergencias termina desenchufado en un cajón. Por eso el siguiente
paso es que el teléfono de la casa acompañe el día a día: que recuerde la pastilla («¿Ya se tomó la
de las 8?») con la misma pregunta y los mismos dos botones, y que llame a la familia con un toque.
Cada respuesta es, además, una señal de que la persona está bien.

## Cómo funciona

- **El audio nunca sale del teléfono.** Vive solo en un buffer de 5 segundos en memoria y entra
  crudo al modelo, sin supresión de ruido, porque esos filtros borran los golpes y las alarmas.
- **YAMNet corre en el mismo teléfono.** Una compuerta de decibeles mide cada bloque de sonido
  contra el ruido de fondo de la casa, y el modelo clasifica dos veces por segundo qué fue. Sus
  521 clases se reducen a los pocos tipos de evento que importan en una casa.
- **Elegimos el modelo con datos.** Comparamos 9 modelos de audio sobre 640 sonidos de casa. La
  comparación está en el repo y se puede repetir.

## Para quién

El cliente es el que cuida: el hijo o el familiar que está lejos. Es quien lo configura y quien
recibe los avisos. El adulto mayor no tiene que aprender nada: solo dejar el teléfono enchufado.

## Lo que viene

- El aviso a la familia por Telegram y en una web que se abre con un QR, sin instalar nada.
- Alertas con hora de vencimiento: si el teléfono de la casa se apaga en plena alarma, la alerta
  escala igual.
- El latido: si la casa deja de reportar, la familia ve «sin señal desde las 14:05».

## Con qué está hecho

Flutter en Android para el teléfono de la casa · YAMNet con TensorFlow Lite en el teléfono ·
Next.js y MediaPipe para la prueba del oído en el navegador · Supabase y Telegram para los avisos a
la familia.
