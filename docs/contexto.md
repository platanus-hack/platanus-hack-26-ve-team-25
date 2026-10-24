# Contexto y decisiones

Por qué el proyecto es lo que es. Track: **Emergencias**. Mentor: Víctor Orozco (Head of
Engineering, Yummy).

## El problema

Cerca de 8 millones de venezolanos emigraron (R4V, cifra por confirmar) y muchos padres mayores
quedaron viviendo solos. Si se caen o hay un incendio, nadie se entera a tiempo. Hoy la familia lo
resuelve llamando varias veces al día.

## La propuesta

> Para el venezolano que emigró y dejó a sus padres solos, ofrecemos saber cada día que están bien
> y enterarse en segundos si se caen o suena una alarma, con el teléfono viejo que ya tienen en
> casa, a diferencia de llamarlos cinco veces al día o de cámaras y relojes caros que ellos no
> saben usar.

## Cómo llegamos aquí

Arrancamos el viernes en la noche con semáforos que abren paso a la ambulancia. Tenía ingeniería,
pero no una propuesta de valor para la gente: las ambulancias son pocas, pasan por pocas calles y
el único comprador es el gobierno. Buscamos un problema que toque a muchas familias todos los días
y en el que pague el usuario. El mentor validó la idea nueva el sábado a las 00:23 y propuso el
flujo del MVP: una alarma en la casa que hay que apagar, y si nadie la apaga en 60 s, el aviso al
contacto de emergencia.

## Lo que ya existe y en qué nos distinguimos

| Qué existe | Por qué no es esto |
|---|---|
| Apps de caídas (uFallAlert, FallSafety, Senior Safety App) | Usan el acelerómetro del teléfono que la persona lleva encima. En casa, el teléfono queda en la mesa |
| CareBridge | Solo mira si se desbloqueó la pantalla: no oye ni detecta caídas. Muestra que las familias pagan por saber que está bien |
| Google Nest | Oye la alarma de humo y el vidrio roto, pero pide un parlante, suscripción y dirección en EE. UU. No detecta caídas ni gritos |
| Sound Notifications de Android | Reconoce la alarma de humo y los gritos, pero el aviso no sale del mismo teléfono |
| AlfredCamera | Convierte el teléfono viejo en cámara: es video de la persona y solo detecta movimiento |
| Colgantes y sensores dedicados | Hardware que hay que comprar e instalar |
| Investigación y patentes | Detectan caídas con sonido ambiente, y con vibración del piso más sonido. Nadie lo llevó al teléfono viejo |

Ninguno de los proyectos anteriores de Platanus Hack lo hace.

## Decisiones de diseño

| Decisión | Por qué |
|---|---|
| El audio se procesa en el teléfono, con YAMNet en el navegador | Privacidad: solo salen etiquetas de eventos. Y no cuesta nada por uso |
| Una compuerta de decibeles antes del modelo | Lo barato corre siempre; el modelo solo confirma |
| Sonido más vibración del piso | La TV puede gritar, pero no hace temblar el piso. Una caída sí |
| Una alarma en la casa que hay que apagar en 60 s | Una falsa alarma cuesta un toque de la persona, no un susto a la familia. Cada alarma apagada calibra esa casa |
| Escalamiento por vencimiento, una sola vez | Si el teléfono de la casa se apaga en plena alarma, la alerta escala igual: cualquier teléfono de la familia ve que venció |
| El silencio también avisa | Si la casa deja de reportar, la familia lo ve |
| Tres niveles de aviso y un presupuesto al día | La meta es que la familia esté tranquila. Si la app suena por todo, la silencian y el día que importa no la ven |
| El perfil de salud cambia las reglas | Un apagón es una molestia para unos y una emergencia para quien usa oxígeno. Reglas generales por condición, calibradas por casa. No entrenamos un modelo por persona: no hay datos ni tiempo |
| La persona también es sensor | «Huele a gas» o «me siento mal» lo dice un humano, y cubre lo que el teléfono no puede oler. Se dice en voz alta, sin botón (sábado 24): la pantalla deja todo el espacio a «Pedir ayuda». Como la voz puede venir de la TV, pasa por «¿Está bien?» antes de avisar |
| Todo lo posible en el teléfono | Sin luz ni internet, que en Venezuela es lo normal, la alarma local sigue funcionando y los eventos esperan en cola |
| Flutter, Supabase y Telegram | Flutter da micrófono en segundo plano, batería y SMS en el teléfono de la casa. Telegram suena en cualquier teléfono sin pagar cuentas de desarrollador |
| El cliente es el que cuida | Paga, configura y recibe los avisos el hijo o el familiar lejos. El adulto mayor confía porque su familia confía |
| En el hackatón, app para la casa y web para la familia | El público prueba con un QR sin instalar nada. La versión final es una sola app con los dos roles |
| Lo que no cabe ahora va a [futuro.md](futuro.md) | Dejarlo para después no es descartarlo |
| Una sola app con dos roles: la casa y la familia | El mismo instalable sirve para el teléfono viejo del abuelo y para el del familiar que recibe el aviso |
| La rutina de cada casa se cuenta, no se entrena | Conteos de qué suena en cada franja del día. Lo que más dice que algo pasó es que falte lo de siempre, y eso cubre las caídas silenciosas |
| El demo muestra dos momentos | A la casa le pasa algo en la tarima, y a alguien del público le llega el aviso en su teléfono |
| El audio llega crudo al modelo | YAMNet se entrenó con audio ruidoso. Limpiarlo le muestra un sonido que nunca vio, y los supresores de voz borran la alarma y el golpe |
| La alarma se apaga pasando la mano por encima | El sensor de proximidad evita tener que atinarle a un botón a quien ve mal o tiene temblor. El botón grande queda por si el sensor falla |
| El teléfono de la casa es Android | iOS no deja escuchar todo el día en segundo plano. La familia puede usar cualquier teléfono |
| La web de la familia es instalable (PWA) | Se abre con un QR sin instalar nada, y quien quiera la agrega a la pantalla de inicio y se ve como una app, sin tienda. En iPhone, las notificaciones web solo funcionan así. La alerta 🔴 va igual por Telegram, que suena aunque el teléfono esté bloqueado |

## Pendiente

- Las cifras con fuente: venezolanos emigrados, adultos mayores que viven solos y caídas en casa.
