# Riesgos, muros y experiencia

> Dónde puede fallar el proyecto y cómo evitamos que reste en vez de sumar. Lo lleva Rogelio.
> Cada riesgo tiene su salida. Si alguien encuentra uno nuevo, lo agrega aquí.

## Los principales, en orden (sábado 24-oct, 01:45)

| # | Riesgo | Dueño | Límite | Está resuelto cuando |
|---|---|---|---|---|
| 1 | Nadie tiene asignado construir, y el stack se parte a última hora | Rogelio | **Sáb 02:30** | Cada pieza del núcleo tiene un nombre al lado y se sabe qué se hace en Flutter y qué en web |
| 2 | El oído no está probado con micrófono real | Abrahan | Sáb 09:00 | La alarma de humo dispara, el golpe con vibración dispara y la TV no dispara, en una sala con ruido |
| 3 | El demo con el público: QR, 50 teléfonos, wifi del evento | Rogelio | Sáb 12:00 | Cuatro teléfonos entran por el QR en producción y reciben la alerta |
| 4 | La app de la casa muere en segundo plano o tras reiniciarse | Josuep | Sáb 18:00 | El teléfono pasa 1 h con la pantalla apagada y sigue oyendo |
| 5 | Falsas alarmas que cansan a la familia, y caídas que no se oyen | Josuep | Sáb 12:00 | Los tres niveles funcionan y el demo muestra un 🟡 que no suena |
| 6 | Sin luz o sin internet, que es la historia venezolana | Josuep | Sáb 18:00 | Se corta el wifi, se dispara un evento, vuelve el wifi y la alerta llega |
| 7 | El canal real de aviso no está construido | Josuep | Sáb 12:00 | Llega un mensaje de Telegram a un iPhone y a un Android |
| 8 | Confianza: espionaje, datos de salud, responsabilidad | Rogelio | Sáb 20:00 | Hay una respuesta de una línea para cada uno, en la app y en el pitch |
| 9 | ¿Quién paga y cómo, desde afuera? | Anttony | Sáb 20:00 | Hay un precio, un comprador y un testimonio |
| 10 | Alcance que crece con cada idea buena | Rogelio | **Sáb 24:00** | El alcance queda congelado y lo que sobra pasa a «después» |

## La regla de oro: despreocupar, no angustiar

El producto no vende alertas. Vende **tranquilidad**: que el hijo que está lejos deje de pensar en
su mamá cada hora porque sabe que, si pasa algo, se entera. Una app que suena por todo hace lo
contrario: la familia la silencia en una semana y el día que importa no la ve.

Por eso cada aviso tiene un nivel, y solo uno despierta a alguien:

| Nivel | Cuándo | Cómo llega |
|---|---|---|
| 🔴 **Urgente** | Botón de pánico. Alarma que nadie apagó en 60 s. «Necesito ayuda». Apagón en una casa con equipo eléctrico de soporte vital | Notificación que suena + Telegram, y se escala al siguiente contacto |
| 🟡 **Para saber** | Falsa alarma que la persona apagó. Apagón en una casa sin riesgo eléctrico. Rutina distinta a la de siempre | Se ve al abrir la app, sin sonido |
| 🟢 **Todo bien** | «Se levantó a las 7:12», «Hizo su check-in» | Un resumen al día. Es lo que reemplaza las cinco llamadas |

**Presupuesto de avisos:** fuera del rojo, la familia no recibe más de uno o dos avisos al día. Si
un día hay más, se agrupan.

## Muros técnicos

### 1. Flutter a la 01:30 con el núcleo para las 12:00 🔴

El equipo decidió Flutter. Lo que ya existe (el oído con YAMNet y sus pruebas) está en Next.js y
desplegado. Cambiar de stack ahora cuesta horas de las 10 que quedan para el núcleo.

**Salida recomendada:** Flutter solo para el **teléfono de la casa**, que es donde lo nativo sirve
de verdad (micrófono en segundo plano, batería, SMS, pantalla siempre encendida). La **app de la
familia queda en web**, porque:

- **El público prueba la app con un QR durante el pitch.** Nadie va a instalar una app nativa en
  tres minutos. Los jueces piden deploy público y sin login.
- Ya hay deploy en Vercel funcionando.

Si el equipo quiere un solo código, Flutter compila a web: la app de la familia sería Flutter web
desplegada en Vercel. Hay que decidirlo ya, no a las 10:00.

### 2. iOS sin cuenta de desarrollador pagada

Con la Mac de Rogelio y una cuenta gratis de Apple se puede instalar desde Xcode en un iPhone. Pero:

- La instalación **vence a los 7 días** y no hay TestFlight: sirve para el demo, no para usuarios.
- **Sin la cuenta paga ($99/año) no hay notificaciones push nativas.** Presupuesto: cero.
- iOS **no deja que una app mande SMS sola** y suspende las apps en segundo plano.

**Salida:** el teléfono de la casa es **Android**. Encaja con la historia: el teléfono viejo que
queda en una casa venezolana casi siempre es Android (Anttony busca la cifra). El aviso a la
familia va por **Telegram**: es gratis, suena en iOS y en Android, y el emigrado ya lo tiene. iOS
queda para el lado de la familia, que es web.

### 3. El micrófono en segundo plano en Android

- Android exige un **servicio en primer plano** con notificación fija (tipo `microphone` desde
  Android 14).
- Xiaomi, Samsung y Huawei matan las apps en segundo plano para ahorrar batería. Hay que guiar al
  familiar a quitar la optimización de batería al configurar.
- **Un servicio de micrófono no puede arrancar desde segundo plano**, ni siquiera al encender el
  teléfono. Si un apagón largo agota la batería y el teléfono se reinicia, la app no vuelve a oír
  sola hasta que alguien la abra. Lo cubre el latido: la familia ve «sin señal».
- Salida para el demo, y quizá para el producto: **modo kiosco**. La app se instala como
  pantalla de inicio del teléfono, así que al reiniciar arranca visible y puede volver a oír.
  Queda enchufada y con la pantalla siempre encendida.

### 4. Sin luz, sin wifi, sin datos

En Venezuela es lo normal, no la excepción. El teléfono tiene batería propia, así que sigue
trabajando durante el apagón. Lo que hace en cada caso:

| Qué falla | Qué pasa |
|---|---|
| Se va la luz | El teléfono deja de cargar y lo detecta. Es un evento: 🔴 o 🟡 según el perfil de salud |
| Se cae el wifi | Pasa a datos móviles |
| No hay internet | La alarma local suena igual (todo se detecta en el teléfono). Los eventos quedan en cola y se mandan al volver la señal. En Android puede mandar **SMS desde el propio chip**: no cuesta nada a nosotros, y para el usuario cuesta un mensaje |
| El teléfono se apaga o se queda sin batería | **El silencio avisa:** la casa manda un latido cada pocos minutos y la familia ve «sin señal desde las 14:05». El escalamiento por vencimiento sigue funcionando desde los teléfonos de la familia |

### 5. La batería del teléfono viejo

Un teléfono viejo enchufado 24/7 se calienta y la batería se puede hinchar. Es un riesgo físico
real. La app vigila la temperatura de la batería y avisa 🟡 si sube. Se dice en el pitch antes de
que lo pregunte el jurado.

### 6. Supabase gratis

- Pausa el proyecto tras una semana sin uso: irrelevante para el hackatón, sí para un piloto.
- Límite de conexiones en tiempo real del plan gratis: hay que verificar que aguante a 50
  personas del público a la vez.

## Huecos del producto

| Hueco | Qué hacemos |
|---|---|
| **Caída silenciosa** en otra habitación: no hay golpe fuerte ni grito cerca del teléfono | Un teléfono no cubre toda la casa y lo decimos. Lo cubren la rutina («a las 10:00 no hubo actividad») y el botón de pánico |
| La persona **apaga la alarma por reflejo** aunque esté mal, o tiene deterioro cognitivo | Al apagar no basta un toque: pregunta «¿Está bien?» con dos botones grandes, **Estoy bien** y **Necesito ayuda**. En perfiles con deterioro cognitivo, apagar también avisa 🟡 |
| La persona no oye bien | La alarma destella y vibra, además de sonar |
| «Me están espiando» | No hay cámara. El audio nunca sale del teléfono: solo sale «alarma de humo a las 14:05». Lo explica la pantalla de la casa y el pitch |
| Datos de salud | Son sensibles. Se guarda lo mínimo: la condición que cambia la regla, no el historial. En el hackatón, todo inventado |
| Responsabilidad | No es un dispositivo médico ni reemplaza a los servicios de emergencia. Lo dice la app |

## Riesgos del demo

- **La sala es ruidosa.** El micrófono puede disparar con el ruido o no oír la alarma. Salida: un
  botón oculto de «modo demo» que dispara el evento, y el video de respaldo.
- **El wifi del evento se satura** con 50 teléfonos. Salida: el teléfono de la tarima usa datos
  propios.
- **La TV que grita** tiene que no disparar en vivo. Ensayarlo antes de las 20:00.

## Que sume y no reste

**Para la persona en la casa:**

- Cero configuración. No crea cuenta, no aprende nada: la familia lo configura todo.
- Una sola pantalla, letra grande, dos botones grandes como máximo.
- Nunca la regaña ni la asusta: «¿Está bien? Toque aquí» y no «ALERTA DETECTADA».
- Puede pedir ayuda sin buscar el teléfono: el botón de pánico siempre está en pantalla.

**Para la familia lejos:**

- El silencio significa «todo bien», pero el resumen verde del día lo confirma.
- Cada aviso dice qué pasó, cuándo y qué hacer: «Alarma de humo en la casa de Carmen, 14:05. No
  la apagó. Llamar al vecino: Pedro».
- Se entra con un enlace. Sin contraseñas.

**Lo que lo hace irresistible:** la frase de venta no es «detecta caídas». Es **«deja de llamar
cinco veces al día»**. El mensaje verde de cada mañana es el gancho. La alerta es el seguro.
