# Mejoras a futuro

> Lo que no construimos en el hackatón pero sí va en el producto. Que no lo hagamos ahora no
> quiere decir que lo descartemos. Si una idea no cabe en el [plan](plan.md#prioridades), viene
> aquí con su porqué.

## La app

| Mejora | Por qué | Qué hace falta |
|---|---|---|
| **Una sola app para todos**, con dos roles: la casa y la familia | Un instalable para el teléfono del abuelo y para el del hijo. Hoy la familia entra por web para que el público pruebe con un QR | Pasar la web de la familia a Flutter |
| **iOS completo** | Push nativo, TestFlight y App Store. Muchos emigrados usan iPhone | Cuenta de Apple Developer ($99/año) |
| **Publicar en Google Play** | Instalar sin APK a mano | Cuenta de Play ($25 una vez) y la declaración de permisos |

## Avisos

| Mejora | Por qué | Qué hace falta |
|---|---|---|
| **Push nativo** además de Telegram | No depender de que la familia tenga Telegram | Cuenta de Apple y Firebase Cloud Messaging |
| **SMS automático cumpliendo la política de Play** | Avisar sin internet | Que la app sea la de SMS predeterminada del teléfono de la casa, que es un teléfono dedicado |
| **Llamada en altavoz al vecino** | El vecino oye la sala y puede hablar con la persona | Permiso de llamadas y pruebas por marca |
| **Llamada de WhatsApp por la vía oficial** | Hoy la casa ya llama primero por WhatsApp, pero por una vía no oficial: abre la fila de «llamada de voz» que WhatsApp crea en la agenda de Android. Depende de que el contacto esté guardado y de que WhatsApp no cambie esa fila | Una integración oficial, si WhatsApp la ofrece, o la API de WhatsApp Business |
| **WhatsApp para los mensajes** | Es lo que más se usa en Venezuela | WhatsApp Business API, que se paga por conversación |
| **Pasarela de SMS o llamadas** | Avisar al exterior aunque el chip de la casa no pueda | Twilio o similar, cuando haya ingresos |

## Cobertura de la casa

| Mejora | Por qué | Qué hace falta |
|---|---|---|
| **Varios teléfonos por casa** | Uno por cuarto clave: dormitorio, baño, sala. Muchas familias tienen más de uno en una gaveta | Que la casa sea un grupo de teléfonos y los eventos se unan |
| **El teléfono que la persona lleva encima** | Detecta la caída por acelerómetro donde sea, como las apps de caídas que ya existen | Rol «llevar encima» en la misma app |
| **Reloj o colgante** como accesorio opcional | Para quien acepte llevarlo | Integración por Bluetooth |

## Modo kiosco

| Mejora | Por qué | Qué hace falta |
|---|---|---|
| **Kiosco completo (*Device Owner*)** | La app no se puede cerrar, arranca sola tras reiniciar y controla la pantalla | Configurar el teléfono reiniciado de fábrica con un QR en la pantalla de bienvenida |
| **Encendido automático al volver la luz** | Hoy, si la batería se agota en un apagón, el teléfono queda apagado | Encendido programado donde el teléfono lo traiga, o una guía por modelo |

## IA

| Mejora | Por qué | Qué hace falta |
|---|---|---|
| **Ajustar el modelo a cada casa** | Reentrenar la última capa con los sonidos de esa casa, más allá de los umbrales | Grabaciones etiquetadas de la casa, con permiso |
| **Reconocer la voz de la persona** | Distinguir su grito del de la TV | Muestras de su voz y un modelo de hablante |
| **Resumen del día redactado** | «Hoy Carmen se levantó a las 7, cocinó y vio la novela» | Un LLM; no va en el camino de la alerta |

## Conexión

| Mejora | Por qué | Qué hace falta |
|---|---|---|
| **Relevo entre teléfonos vecinos** | Sin internet ni señal, el aviso salta al teléfono del vecino | Bluetooth o wifi directo entre dos apps |

## Salud

| Mejora | Por qué | Qué hace falta |
|---|---|---|
| **Más condiciones en el perfil** | Más reglas por condición, validadas con médicos | Asesoría médica |
| **Recordatorio de medicinas** | Es lo que más preocupa al que cuida después de las caídas | Horarios y confirmación con un toque |
