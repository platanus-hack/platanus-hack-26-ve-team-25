# Mejoras a futuro

> Lo que no construimos en el hackatón pero sí va en el producto. Que no lo hagamos ahora no
> quiere decir que lo descartemos. Si una idea no cabe en el [plan](plan.md#alcance-congelado-lo-que-se-presenta),
> viene aquí con su porqué.

## Hacia dónde va

Para el pitch, en tres pasos. El precio y el modelo están en [la venta](plan.md#la-venta-para-el-pitch).

1. **Hoy, lo que se ve en el demo:** un teléfono viejo que acompaña el día a día con la pastilla,
   oye lo que pasa, pregunta antes de avisar y no angustia a la familia.
2. **Lo siguiente: conectar con quien atiende.** La alerta lleva la ficha de emergencia y pide la
   ambulancia. Cuando se acaban las pastillas, el pedido sale solo. Víctor Orozco, el mentor, lo
   planteó así el sábado 24.
3. **Después: la app de cuidado completa.** El teléfono que la persona lleva encima, la cámara que
   confirma, varios teléfonos por casa y otros países: la migración interna deja al abuelo solo
   igual.

## Conectar con quien atiende

| Mejora | Por qué | Qué hace falta |
|---|---|---|
| **La ficha de emergencia** | Tipo de sangre, condiciones, alergias, pastillas, seguro y a qué clínica llevarla. La llena la familia y viaja con la alerta, para el paramédico o el vecino que llega | Una pantalla en la web de la familia y un QR en la casa. Reutiliza el perfil de salud y el récipe |
| **Pedir la ambulancia** | Hoy el aviso llega a la familia, que está lejos. El paso natural es que la alerta confirmada llame a quien puede ir | Integración con Venemergencia o el 911. No hay API pública: es un acuerdo |
| **Las pastillas a domicilio** | El inventario ya sabe cuándo se acaban y qué comprar para un mes | Una farmacia con entrega (Yummy, Farmatodo). El punto de enganche es `pedido()` en [`inventario.ts`](../web/src/lib/familia/inventario.ts) |
| **Las aseguradoras como canal** | Venden médico a domicilio y ambulancia a la diáspora, pero después del problema. Nosotros somos el aviso que dispara su respuesta | Un plan por afiliado con asistensi, Venemergencia o un seguro |

## La app

| Mejora | Por qué | Qué hace falta |
|---|---|---|
| **Una sola app para todos**, con dos roles: la casa y la familia | Un instalable para el teléfono del abuelo y para el del hijo. Hoy la familia entra por web para que el público pruebe con un QR | Pasar la web de la familia a Flutter |
| **iOS completo** | Push nativo, TestFlight y App Store. Muchos emigrados usan iPhone | Cuenta de Apple Developer ($99/año) |
| **Publicar en Google Play** | Instalar sin APK a mano | Cuenta de Play ($25 una vez) y la declaración de permisos |

## Avisos

| Mejora | Por qué | Qué hace falta |
|---|---|---|
| **Push nativo** | No depender de WhatsApp ni de Telegram | Cuenta de Apple y Firebase Cloud Messaging |
| **SMS automático cumpliendo la política de Play** | Avisar sin internet | Que la app sea la de SMS predeterminada del teléfono de la casa, que es un teléfono dedicado |
| **Llamada en altavoz al vecino** | El vecino oye la sala y puede hablar con la persona | Permiso de llamadas y pruebas por marca |
| **Llamada de WhatsApp por la vía oficial** | Hoy la casa ya llama primero por WhatsApp, pero por una vía no oficial: abre la fila de «llamada de voz» que WhatsApp crea en la agenda de Android. Depende de que el contacto esté guardado y de que WhatsApp no cambie esa fila | Una integración oficial, si WhatsApp la ofrece, o la API de WhatsApp Business |
| **WhatsApp para los mensajes** | Es lo que más se usa en Venezuela | WhatsApp Business API, que se paga por conversación |
| **Pasarela de SMS o llamadas** | Avisar al exterior aunque el chip de la casa no pueda | Twilio o similar, cuando haya ingresos |

## Cobertura de la casa

| Mejora | Por qué | Qué hace falta |
|---|---|---|
| **Varios teléfonos por casa** | Uno por cuarto clave: dormitorio, baño, sala. Muchas familias tienen más de uno en una gaveta | Que la casa sea un grupo de teléfonos y los eventos se unan |
| **El teléfono que la persona lleva encima** | Detecta la caída por acelerómetro donde sea, como las apps de caídas que ya existen. Ahí también le preguntaría cómo amaneció y si se tomó la pastilla: con su propio teléfono se maneja mejor | Rol «llevar encima» en la misma app |
| **Vibración del piso junto con el sonido** | Separa el golpe real de la TV: la TV grita, pero el piso no tiembla | El acelerómetro, la fusión con YAMNet y pruebas en piso de cerámica y concreto |
| **Reloj o colgante** como accesorio opcional | Para quien acepte llevarlo | Integración por Bluetooth |

## Modo kiosco

| Mejora | Por qué | Qué hace falta |
|---|---|---|
| **Servicio en primer plano** | Hoy la app escucha solo con la pantalla encendida y la app abierta | `flutter_foreground_task` con tipo `microphone` y la app como pantalla de inicio ([riesgos.md](riesgos.md#3-el-modo-kiosco-que-la-app-no-se-muera)) |
| **Kiosco completo (*Device Owner*)** | La app no se puede cerrar, arranca sola tras reiniciar y controla la pantalla | Configurar el teléfono reiniciado de fábrica con un QR en la pantalla de bienvenida |
| **Encendido automático al volver la luz** | Hoy, si la batería se agota en un apagón, el teléfono queda apagado | Encendido programado donde el teléfono lo traiga, o una guía por modelo |

## IA

| Mejora | Por qué | Qué hace falta |
|---|---|---|
| **Ajustar el modelo a cada casa** | Reentrenar la última capa con los sonidos de esa casa, más allá de los umbrales | Grabaciones etiquetadas de la casa, con permiso |
| **Reconocer la voz de la persona** | Distinguir su grito del de la TV | Muestras de su voz y un modelo de hablante |
| **Resumen del día redactado** | «Hoy Carmen se levantó a las 7, cocinó y vio la novela» | Un LLM; no va en el camino de la alerta |
| **Preguntar por WhatsApp** | «¿Cómo amaneció mi mamá?», y Claude responde leyendo los eventos de hoy | El webhook de Kapso ya recibe los mensajes |
| **La rutina de la casa** | Avisar si falta lo de siempre: no sonó la cocina a mediodía | Contar los eventos del oído por franja del día |
| **La cámara que confirma** | Ver que la persona está en el suelo antes de pedir la ambulancia. Víctor lo propuso, no para el demo | Un modelo de pose en el teléfono, sin que la imagen salga de él |

## Conexión

| Mejora | Por qué | Qué hace falta |
|---|---|---|
| **Relevo entre teléfonos vecinos** | Sin internet ni señal, el aviso salta al teléfono del vecino | Bluetooth o wifi directo entre dos apps |

## Salud

| Mejora | Por qué | Qué hace falta |
|---|---|---|
| **Más condiciones en el perfil** | Más reglas por condición, validadas con médicos | Asesoría médica |
| **El apagón según el perfil de salud** | Un apagón no es igual para quien usa oxígeno: para ella es 🔴, para otra casa 🟡 | El perfil en la web. El latido ya manda si el teléfono está enchufado |
| **El récipe desde la foto** | Hoy se lee la factura; el récipe se carga con un script | El mismo flujo de la factura, guardando con `familia_recetar` |
