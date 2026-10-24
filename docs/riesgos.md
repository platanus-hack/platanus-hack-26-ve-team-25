# Riesgos, muros y experiencia

> Dónde puede fallar el proyecto y cómo evitamos que reste en vez de sumar. Lo lleva Rogelio.
> Cada riesgo tiene su salida. Si alguien encuentra uno nuevo, lo agrega aquí. Lo que se deja
> para después no se descarta: va a [futuro.md](futuro.md).

## Los principales, en orden (sábado 24-oct, 02:00)

| # | Riesgo | Dueño | Límite | Está resuelto cuando | Estado |
|---|---|---|---|---|---|
| 1 | Nadie tiene asignado construir, y el stack se parte a última hora | Rogelio | Sáb 02:30 | Cada pieza tiene un nombre al lado | App Flutter para la casa y web para la familia: decidido. Faltan los nombres |
| 2 | El oído no está probado con las clases nuevas | Abrahan | Sáb 09:00 | La alarma de humo dispara con música alta, el golpe con vibración dispara y la TV no | Funcionó con música alta antes del cambio. Falta repetir |
| 3 | El demo con el público: QR, 50 teléfonos, wifi del evento | Rogelio | Sáb 12:00 | Cuatro teléfonos entran por el QR en producción y reciben la alerta | Abierto |
| 4 | La app de la casa muere en segundo plano o al reiniciarse | Josuep | Sáb 18:00 | El teléfono pasa 1 h con la pantalla apagada, se reinicia y sigue oyendo | Abierto: [modo kiosco](#3-el-modo-kiosco-que-la-app-no-se-muera) |
| 5 | Falsas alarmas que cansan a la familia, y lo que el teléfono no alcanza a oír | Josuep | Sáb 12:00 | Los tres niveles funcionan y el demo muestra un 🟡 que no suena | Abierto: [cobertura](#la-casa-entera-un-teléfono-no-alcanza-a-oír-todo) |
| 6 | Sin luz, sin internet o sin señal | Josuep | Sáb 18:00 | Se corta el wifi, se dispara un evento, vuelve el wifi y la alerta llega | Abierto: [salidas](#4-sin-luz-sin-internet-sin-señal) |
| 7 | El canal real de aviso no está construido | Josuep | Sáb 12:00 | Llega un mensaje de Telegram a un iPhone y a un Android | Telegram: decidido |
| 8 | Que el familiar no confíe | Rogelio | Sáb 20:00 | Hay una respuesta de una línea para cada duda, en la web y en el pitch | Abierto |
| 9 | ¿Quién paga y cómo, desde afuera? | Anttony | Sáb 20:00 | Hay un precio, un comprador y un testimonio | Abierto |
| 10 | Alcance que crece con cada idea buena | Rogelio | Sáb 24:00 | El alcance queda congelado | Prioridades P0, P1 y P2 en el [plan](plan.md#prioridades) |

## La regla de oro: despreocupar, no angustiar

El producto no vende alertas. Vende **tranquilidad**: que el hijo que está lejos deje de pensar en
su mamá cada hora porque sabe que, si pasa algo, se entera. Una app que suena por todo hace lo
contrario: la familia la silencia en una semana y el día que importa no la ve.

Por eso cada aviso tiene un nivel, y solo uno despierta a alguien:

| Nivel | Cuándo | Cómo llega |
|---|---|---|
| 🔴 **Urgente** | Botón de pánico. Alarma que nadie apagó en 60 s. «Necesito ayuda». Apagón en una casa con equipo eléctrico de soporte vital | Notificación que suena + Telegram, y se escala al siguiente contacto |
| 🟡 **Para saber** | Falsa alarma que la persona apagó. Apagón en una casa sin riesgo eléctrico. Rutina distinta a la de siempre. Batería baja o caliente | Se ve al abrir la web, sin sonido |
| 🟢 **Todo bien** | «Se levantó a las 7:12», «Hizo su check-in» | Un resumen al día. Es lo que reemplaza las cinco llamadas |

**Tope de avisos:** fuera del rojo, la familia no recibe más de uno o dos avisos al día. Si
un día hay más, se agrupan.

## Muros técnicos

### 1. El stack, decidido

Para el hackatón: app **Flutter en Android** para la casa y **web** para la familia, porque el
público prueba con un QR y no va a instalar nada en tres minutos. La versión final es una sola app
con dos roles. Dos del equipo ya trabajaron con Flutter.

**Plan B si YAMNet en Flutter va lento en un Android viejo:** la app de la casa abre `/escucha`
dentro de un WebView, que ya funciona. Sirve con la pantalla encendida (modo kiosco), no con la
pantalla apagada.

### 2. iOS, para después

Sin la cuenta de Apple paga ($99/año) no hay push nativo, la instalación desde Xcode vence a los
7 días, iOS no deja mandar SMS sola y suspende las apps en segundo plano. Para el hackatón la casa
es Android y la familia entra por web y Telegram. En el producto se paga la cuenta: ver
[futuro.md](futuro.md).

### 3. El modo kiosco: que la app no se muera

**Por qué es grave.** Android no deja arrancar un servicio de micrófono si la app no está a la
vista, **ni siquiera al encender el teléfono**: desde Android 14 un aviso de arranque no puede
lanzar un servicio de tipo micrófono, y desde Android 15 lo hace cumplir a toda app que apunte a
esa versión. Entonces, si un apagón largo agota la batería y el teléfono se reinicia, la app no
vuelve a oír sola. Además, Xiaomi, Samsung y Huawei matan las apps en segundo plano para ahorrar
batería.

**La salida: que la app esté siempre a la vista.** Hay tres niveles:

| Nivel | Qué es | Sobrevive al reinicio | Qué pide | Para |
|---|---|---|---|---|
| **1. La app es la pantalla de inicio** | Se declara como *launcher*. Al encender, Android abre la app porque es el inicio, y como está a la vista puede arrancar el micrófono | Sí, si el teléfono no tiene bloqueo de pantalla | Nada especial. El familiar la elige como inicio al configurar | **El hackatón (P1)** |
| 2. Fijar pantalla | La persona no puede salir de la app sin una combinación de botones | No | Que el familiar la fije | Complemento del nivel 1 |
| 3. Kiosco completo (*Device Owner*) | La app controla el teléfono: no se puede salir, arranca sola, la pantalla no se apaga | Sí, y es el más confiable | Teléfono reiniciado de fábrica y configurado con `adb` o con un QR en la pantalla de bienvenida | El producto: [futuro.md](futuro.md) |

Lo que se hace en el nivel 1:

- Servicio en primer plano de tipo `microphone` con notificación fija, arrancado desde la pantalla.
- Pedir que la app quede fuera de la optimización de batería, con instrucciones por marca.
- Pantalla encendida mientras está enchufado, con un fondo negro y un reloj tenue para no gastar ni
  calentar.
- Teléfono sin bloqueo de pantalla.

**El hueco que queda:** si el teléfono se apaga por completo en un apagón, muchos modelos al volver
la luz se quedan en la pantalla de carga y no encienden solos. Lo que hacemos:

1. Con la batería al 15 %, aviso 🟡: «El teléfono de Carmen se apagará en unos 30 minutos».
2. El latido hace que la familia vea «sin señal desde las 18:40» y sepa que hay que pedirle a
   alguien que lo encienda.
3. Algunos teléfonos tienen «encendido programado» en Ajustes. Hay que revisar si el del demo lo
   tiene.

**Prueba antes de las 18:00:** apagar la pantalla 1 hora, reiniciar el teléfono y comprobar que
sigue oyendo sin que nadie lo toque.

### 4. Sin luz, sin internet, sin señal

En Venezuela es lo normal, no la excepción. El teléfono tiene batería propia, así que sigue
trabajando durante el apagón.

| Qué falla | Qué pasa |
|---|---|
| Se va la luz | El teléfono deja de cargar y lo detecta. Es un evento: 🔴 o 🟡 según el perfil de salud. Pasa a modo ahorro: solo corre la compuerta de dB y el modelo se despierta cuando hay ruido |
| Se cae el wifi | Pasa a datos móviles |
| No hay internet pero hay señal | La alarma local suena igual. Los eventos quedan en cola con su hora y se mandan al volver. Para el 🔴: SMS o llamada al vecino desde el chip (ver abajo) |
| No hay señal de ningún tipo | La alarma local pasa a **sirena** al máximo volumen para que la oigan los vecinos. La red de respaldo son las personas cercanas |
| El teléfono se apaga | **El silencio avisa:** la familia ve «sin señal desde las 14:05» con un botón para escribirle al vecino. La familia sí tiene internet afuera |

**El SMS automático.** Android sí deja que una app mande SMS sola, con el permiso `SEND_SMS`. Lo
que lo restringe es **Google Play**: solo publica apps con ese permiso si la app es la de SMS
predeterminada del teléfono, salvo excepciones contadas que Google aprueba a mano. Las salidas:

1. **Hackatón y piloto:** el APK se instala a mano, fuera de Play, y la restricción no aplica.
   Android le pide el permiso a la persona una vez.
2. **Producto en Play:** el teléfono de la casa es un teléfono dedicado, así que la app puede ser
   su app de SMS predeterminada. Eso cumple la política.
3. **Llamada en altavoz al vecino.** Llamar no tiene la misma restricción que el SMS. La app llama
   al vecino y pone el altavoz: el vecino oye la sala y puede hablar con Carmen.

**Ojo:** el SMS y la llamada van a un contacto **local** (vecino, familiar en la ciudad). Un SMS
desde un chip venezolano al exterior cuesta y no siempre llega. Y en un apagón largo las antenas
también se quedan sin batería. Anttony lo verifica.

### 5. La batería del teléfono viejo

Un teléfono viejo enchufado todo el día se calienta y la batería se puede hinchar. Es un riesgo
físico real. La app no puede cortar la carga sin permisos de administrador, pero sí puede hacer
mucho:

| Qué | Cómo | Cuándo |
|---|---|---|
| **Vigilar la temperatura y la salud de la batería** | Android las reporta (`BatteryManager`: temperatura y estado, que incluye «sobrecalentada»). Si pasa de unos 45 °C, aviso 🟡 | P1 |
| **Gastar y calentar menos** | Pantalla negra con brillo mínimo, el modelo solo cuando la compuerta de dB lo pide, sin funda | P1 |
| **Decir cuánto aguanta en un apagón** | Medir cuánto baja la batería por hora cuando no hay luz: «Si se va la luz, este teléfono aguanta unas 6 horas». Una batería que ya no aguanta también es un aviso 🟡 | P2 |
| **Limitar la carga al 80 %** | Muchos teléfonos lo traen en Ajustes (Samsung lo llama «Proteger batería»). Va en la guía de configuración | Guía |
| **Enchufe con temporizador** | Un temporizador mecánico barato carga unas horas y descansa otras. La batería se mantiene a media carga | Guía, opcional |
| **Dónde ponerlo** | Superficie dura que no arda, lejos de cortinas y del sol | Guía |

En el pitch se dice antes de que lo pregunte el jurado: **la batería del teléfono viejo es la que
lo mantiene vivo en el apagón**, así que la cuidamos y avisamos cuando se está gastando.

## La casa entera: un teléfono no alcanza a oír todo

No está descartado. Cada tipo de evento llega a una distancia distinta:

| Evento | Hasta dónde llega | Por qué |
|---|---|---|
| Alarma de humo | **Toda la casa** | Las alarmas suenan a unos 85 dB a 3 m. Se oye de un cuarto a otro |
| Grito o «¡auxilio!» | **El cuarto y los de al lado** | La voz alta atraviesa una o dos puertas abiertas |
| Golpe de una caída | **El mismo cuarto**, quizá el de al lado | El golpe es grave y apagado. La vibración en piso de concreto o cerámica viaja mucho menos que en madera: hay que probarlo |
| Que falte lo de siempre (rutina) | **Toda la casa** | No hace falta oír la caída: no se oyó el baño, la cocina ni la TV a la hora de siempre |

**Dónde poner el teléfono.** Los estudios coinciden en que las caídas en casa ocurren sobre todo en
el **baño** y el **dormitorio**, y los viajes al baño de noche son el momento clásico. Por eso:

- **En el pasillo entre el dormitorio y el baño**, o en el dormitorio cerca de la puerta. Desde
  ahí oye los dos y la alarma de humo de toda la casa.
- **En el piso o en un estante bajo pegado a la pared**, sobre superficie dura. Así siente la
  vibración del piso. Nunca sobre un cojín ni dentro de un mueble.
- Cerca de un enchufe, con la pantalla hacia el pasillo para que el botón de pánico se vea.
- **No en la cocina** (mucho ruido) ni junto a la TV.
- La puerta del dormitorio abierta de noche.

La app lo guía al instalar: «Ponga el teléfono en el pasillo, entre el cuarto y el baño».

**Lo que cubre lo demás:**

1. **La rutina** (P1): el silencio a la hora de siempre cubre la caída que no se oyó.
2. **El botón de pánico** y el «¡auxilio!» por voz (P2).
3. **Más teléfonos viejos** en la misma casa, uno por cuarto clave. Muchas familias tienen más de
   uno en una gaveta ([futuro.md](futuro.md)).
4. **El teléfono que la persona lleva encima**, con detección de caídas por acelerómetro
   ([futuro.md](futuro.md)).

**En el pitch:** «Oye la alarma de humo en toda la casa, oye el grito en los cuartos de al lado y,
para lo que no se oye, el silencio avisa».

## Huecos del producto

| Hueco | Qué hacemos |
|---|---|
| La persona **apaga la alarma por reflejo** aunque esté mal, o tiene deterioro cognitivo | No basta un toque: «Estoy bien» y «Necesito ayuda» con dos botones grandes. En perfiles con deterioro cognitivo, apagar también avisa 🟡 |
| La persona no oye bien | La alarma destella y vibra, además de sonar |
| Datos de salud | Son sensibles. Se guarda lo mínimo: la condición que cambia la regla, no el historial. En el hackatón, todo inventado |
| Responsabilidad | No es un dispositivo médico ni reemplaza a los servicios de emergencia. Lo dice la app |

## Confianza: el cliente es el que cuida

El cliente es **el hijo o el familiar que está lejos**: es el que paga, configura y recibe los
avisos. El adulto mayor confía porque su familia confía. Por eso:

- El pitch le habla al hijo, no al abuelo.
- La configuración la hace el familiar: el adulto mayor no aprende nada.
- Las dudas que tiene que poder responder el familiar cuando su mamá le pregunte:

| Duda | Respuesta de una línea |
|---|---|
| «¿Me están grabando?» | No hay cámara, y el audio nunca sale del teléfono. Solo sale «alarma de humo a las 14:05» |
| «¿Y si se equivoca?» | Antes de avisar, te pregunta a ti. Si dices que estás bien, no molesta a nadie |
| «¿Y mis datos de salud?» | Solo se guarda lo que cambia el aviso, como «usa oxígeno». No el historial |
| «¿Esto reemplaza al 911?» | No. Avisa a tu familia y a tu vecino |

## Riesgos del demo

- **La sala es ruidosa.** Ya probamos con música alta de la oficina y funcionó. Igual va un botón
  oculto de «modo demo» que dispara el evento, y el video de respaldo.
- **El wifi del evento se satura** con 50 teléfonos. Salida: el teléfono de la tarima usa datos
  propios.
- **La TV que grita** tiene que no disparar en vivo. Ensayarlo antes de las 20:00.
- **Probar el micrófono al lado de una corneta del evento no sirve.** Para comparar modelos no
  hace falta micrófono: se usan archivos de audio (`experimentos/modelos-audio`). La prueba con
  micrófono real se hace en un cuarto tranquilo, una escalera o un carro, a 1 m y a 4 m. Y se
  hace una vez con ruido fuerte a propósito: si funciona con la corneta, funciona en una casa.

## Cómo contar la verdad

Los jueces son técnicos y tienen un agente leyendo el repo. Una exageración que encuentren cuesta
más que una limitación que contemos nosotros.

1. **Decir con qué se probó y cuánto.** Por ejemplo: «Probamos con 640 sonidos de casa del set
   ESC-50 y con N voces de más de 60 años de Common Voice», no «detecta todo».
2. **Mostrar los números, también los malos.** Por ejemplo: «Reconoce la tos y el vidrio. Le
   cuesta el quejido débil: 6 de 10». Un número malo explicado da confianza.
3. **Separar el demo de la realidad, en voz alta:**
    - «En el demo la cuenta regresiva es de 15 s; en una casa es de 60 s».
    - «El morral que cae representa una caída. Una caída silenciosa la detectamos por la
      rutina, no por el golpe».
    - Si se usa el botón oculto de «modo demo» porque la sala no deja oír, se dice: «La sala está
      muy ruidosa, así que disparamos el evento a mano».
4. **El README dice lo mismo que el pitch.** Una sección «Qué funciona y qué no» con la tabla de
   resultados y las limitaciones. El agente del jurado la va a comparar con lo que digamos.
5. **Lo que no existe se dice en futuro.** «La prueba en casas reales es el siguiente paso», no
   «está probado con abuelos».
6. **Cifras con fuente o no van.** Las de emigrados y caídas, con el enlace en el repo.

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

## Fuentes

- Android 14 y 15, servicios en primer plano: [tipos obligatorios](https://developer.android.com/about/versions/14/changes/fgs-types-required),
  [cambios de Android 15](https://developer.android.com/about/versions/15/behavior-changes-15),
  [restricciones de arranque](https://developer.android.com/about/versions/12/foreground-services)
- Google Play, permisos de SMS: [política](https://support.google.com/googleplay/android-developer/answer/16585319)
- Apple, cuenta gratis sin push: [foro de desarrolladores](https://developer.apple.com/forums/thread/768748)
- Dónde ocurren las caídas en casa: [NEISS 2015](https://pmc.ncbi.nlm.nih.gov/articles/PMC8669898/),
  [Brasil](https://www.scielo.br/j/fm/a/LtJrBJwpRhjbWPyNPpsTvHR/?lang=en)
- Supabase, límites de tiempo real: [documentación](https://supabase.com/docs/guides/realtime/limits)
