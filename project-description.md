## El problema

Muchos venezolanos emigraron y sus padres mayores se quedaron viviendo solos. Si se caen o suena
una alarma de humo, nadie se entera a tiempo. Hoy la familia lo resuelve llamando varias veces al
día.

## Qué hace

Un teléfono Android viejo, enchufado en la mesa como un reloj, acompaña el día y oye lo que pasa en
la casa: una alarma de humo, un vidrio roto, un golpe, un grito o un «¡ayuda!» dicho en voz alta.

1. Cuando oye algo, pregunta «¿Está bien?»: suena, vibra y lo dice con la voz del teléfono.
   **Estoy bien** se desliza en un riel ancho, para que no se active con un roce, o se dice:
   «Lucero, estoy bien». «Ayuda», «me caí» o «no» llaman de una vez.
2. Si nadie responde en 60 segundos, la alerta escala: la casa llama al hijo por WhatsApp (si no
   contesta, por teléfono), la web de la familia se pone roja y a cada familiar le llega un aviso
   por Telegram con el enlace.
3. La persona también puede pedir ayuda sin esperar: con el botón **Pedir ayuda** o con la voz
   («Lucero, llama a mi hijo»), con 5 segundos para decir «no».

Una falsa alarma le cuesta un gesto a la persona, no un susto a la familia.

## Todos los días, no solo el día malo

Un aparato que solo sirve para emergencias termina desenchufado en un cajón. Por eso el teléfono
recuerda la pastilla, y el aviso solo se quita con **Ya me la tomé**, que la descuenta del
inventario. La familia sube la foto de la factura de la farmacia, Claude la lee, se cruza con el
récipe y la familia confirma. Así sabe cuántos días de losartán le quedan a su mamá. Si la casa deja
de reportar, la familia ve «sin señal».

## Para la familia, sin instalar nada

Un enlace o un QR abre la web de la casa, sin crear cuenta: alerta, «para saber», todo bien o sin
señal. Con un toque se suscribe a los avisos por Telegram.

## Cómo funciona

- **El audio nunca sale del teléfono.** Vive solo en un buffer de 5 segundos en memoria. A la base
  van etiquetas de eventos, alertas y latidos.
- **YAMNet y Vosk corren en el teléfono, sin internet.** YAMNet clasifica los sonidos y Vosk
  entiende unas 70 frases de ayuda y órdenes.
- **Elegimos el modelo con datos.** Comparamos 9 modelos de audio sobre 640 sonidos de casa: YAMNet
  acierta el 82% en el top-5 y pesa 4,1 MB. La comparación está en el repo y se puede repetir.
- **La alerta vive en la base desde que nace**, con su hora de vencimiento. Si el teléfono de la
  casa se apaga a mitad de la cuenta, la base la escala igual: un vigilante con pg_cron revisa cada
  5 segundos y manda los avisos sin repetirlos.
- **El camino de la alarma no depende de un modelo de lenguaje.** Oír, preguntar, escalar y avisar
  son reglas. Claude solo lee la factura.
- **Probado con 150 teléfonos a la vez** contra producción, sin una falla.

## Para quién

El cliente es el que cuida: el hijo o el familiar que está lejos. Es quien lo configura y quien
recibe los avisos. El adulto mayor no tiene que aprender nada: solo dejar el teléfono enchufado.

## Lo que viene

Conectar con quien atiende: que la alerta lleve la ficha de emergencia y pida la ambulancia, y que
el pedido de pastillas salga solo cuando se acaban. Después, el teléfono que la persona lleva encima
y varios teléfonos por casa.

## Con qué está hecho

Flutter en Android para el teléfono de la casa · YAMNet con TensorFlow Lite y Vosk en el teléfono ·
Next.js 16 en Vercel para la familia · Supabase con pg_cron, pg_net y Vault · Telegram y WhatsApp
con Kapso para los avisos · Claude para leer la factura.
