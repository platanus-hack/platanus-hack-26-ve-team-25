# Preguntas técnicas

Las preguntas que un juez técnico probablemente haga, con la respuesta corta y la evidencia. Cada
respuesta dice en qué estado está:

- ✅ **Hecho**: está en el código, con pruebas o con un experimento que se puede correr.
- 📐 **Diseñado**: decidido y escrito en los documentos, todavía no en código.
- ⏳ **Pendiente**: aún no se ha medido o está en construcción.
- ❌ **No se hizo**, y se dice.

Al sábado 24-oct-2026, 18:30. **Lo de la app de la casa está probado con pruebas automáticas
(110) y contra la base real; la prueba de punta a punta en el teléfono del demo todavía no se
repitió desde los últimos cambios.**

## El audio y la privacidad

### ¿El audio sale del teléfono?

✅ **No.** En la app de la casa el audio vive solo en un anillo de 5 s en memoria que se pisa a sí
mismo ([`anillo.dart`](../app/lib/oido/anillo.dart)). YAMNet y Vosk leen de ese anillo dentro del
teléfono. A Supabase solo van etiquetas: «Oímos un golpe», «Oímos la cocina», alertas, latidos y
tomas de pastillas ([`nube.dart`](../app/lib/datos/nube.dart)). La prueba en el navegador
`/escucha` hace lo mismo ([`anillo.ts`](../web/src/lib/escucha/anillo.ts)).

### ¿Por qué no limpian el audio antes del modelo?

✅ Porque YAMNet se entrenó con audio crudo y ruidoso, y los supresores de ruido borran justo lo
que buscamos: golpes y alarmas. La app pide la fuente `UNPROCESSED` de Android, sin control de
volumen, eco ni supresión ([`oido.dart`](../app/lib/oido/oido.dart)). El razonamiento está en
[investigacion-audio.md §1.2](investigacion-audio.md).

## El modelo

### ¿Por qué YAMNet y no otro modelo?

✅ Comparamos 9 modelos de 4 familias (YAMNet, EfficientAT, PANNs y sherpa-onnx) con 640 sonidos
de casa del set ESC-50 ([experimento](../experimentos/modelos-audio/README.md)):

- Con ventanas de 1 s, YAMNet acierta más (82% en el top-5), pesa 4,1 MB y analiza 1 s de audio
  en 2,5 ms en una CPU de escritorio.
- Con ventanas de 5 s, los modelos CED de sherpa-onnx llegan a 86–87%, contra 81% de YAMNet.

Nos quedamos con YAMNet porque ya funciona y la diferencia es chica. Corre en el teléfono con
TFLite, en otro isolate para no trabar la pantalla. Las tablas:
[resultados-1s.md](../experimentos/modelos-audio/resultados-1s.md),
[resultados-5s.md](../experimentos/modelos-audio/resultados-5s.md).

### ¿Cómo entiende la voz sin internet?

✅ Con **Vosk**, el modelo chico de español (Apache 2.0, ~40 MB), desde la librería oficial de
Android ([`Frases.kt`](../app/android/app/src/main/kotlin/ve/equipo25/casa/Frases.kt)). No abre el
micrófono: cuando YAMNet oye una voz (y no es la TV), Vosk lee los últimos 5 s del mismo anillo.
Así el oído nunca se pausa y la frase que despertó al reconocedor también cuenta.

Usa una **gramática cerrada**: solo puede contestar con las frases del banco, que es más robusto
con una voz débil. A cambio, puede forzar una frase del banco sobre algo parecido, así que se
descartan las palabras con confianza menor a 0,6 ([`frases.dart`](../app/lib/datos/frases.dart)).

- **Pedidos de ayuda** (~70 frases: «me siento malita», «huele a gas», «no me puedo parar»,
  [`pedidos.dart`](../app/lib/dominio/pedidos.dart)): abren «¿Está bien?», no llaman directo.
- **Órdenes con «Lucero»** ([`comandos.dart`](../app/lib/dominio/comandos.dart)): «Lucero, llama a
  mi hijo», «… al vecino», «… a emergencias», con 5 s para decir «no»; «Lucero, estoy bien» calla
  la alarma; «ya me la tomé» quita el recordatorio. Sin el nombre no llama ni calla nada: puede
  ser la TV.

### ¿Qué tan rápido corre en un teléfono viejo?

⏳ No medido. En la computadora, YAMNet analiza 1 s de audio en 2,5–4,8 ms con un hilo.

### ¿Funciona con la voz de una persona mayor?

❌ No medido, y no se va a medir en el hackatón: el equipo no tiene personas mayores cerca para
grabar. Las voces mayores son más débiles, aireadas y temblorosas, y el reconocimiento de voz se
equivoca más con ellas ([investigacion-audio.md §1.1](investigacion-audio.md)). Por eso el diseño
no depende solo de la voz: la compuerta de dB se mide contra el fondo de la casa (un «ayuda» bajo
pasa igual al modelo), YAMNet busca también quejidos («Wail, moan»), y siempre quedan la pantalla y
la alarma que escala sola. No afirmamos que funcione con voces mayores.

## Las falsas alarmas

### ¿Cómo evitan avisarle a la familia por cualquier ruido?

Por capas, de la más barata a la más cara:

| Capa | Qué hace | Estado |
|---|---|---|
| Compuerta de dB | Mide el nivel contra el fondo aprendido de esa casa. Un golpe aislado casi no mueve el fondo; una TV prendida lo sube poco a poco | ✅ [`nivel.dart`](../app/lib/oido/nivel.dart), con pruebas |
| Clases de YAMNet | Las 521 clases se reducen a 6 tipos (alarma, vidrio, golpe, grito, TV, rutina), con un umbral de 0,3. La TV y la rutina no son alertas | ✅ [`sonidos.dart`](../app/lib/oido/sonidos.dart), con pruebas |
| Sin repeticiones | El mismo sonido no vuelve a preguntar antes de 3 s, y después de callar la alarma el oído ignora 5 s para no oír su propio tono | ✅ [`controlador.dart`](../app/lib/ui/controlador.dart) |
| **Confirmación en la casa** | «¿Está bien?» suena a 520 Hz, vibra y pregunta con la voz del teléfono. Se apaga deslizando o diciendo «Lucero, estoy bien». Si nadie responde en 60 s, llama | ✅ [`alarma.dart`](../app/lib/ui/alarma.dart), [`Sirena.kt`](../app/android/app/src/main/kotlin/ve/equipo25/casa/Sirena.kt) |
| Niveles | 🔴 urgente, 🟡 para saber, 🟢 todo bien. Una falsa alarma le llega a la familia como «para saber», no como urgencia | ✅ [`estado.ts`](../web/src/lib/familia/estado.ts), 13 pruebas |
| Sonido más vibración | Un golpe que suena y también hace vibrar el teléfono | 📐 [futuro.md](futuro.md) |

### ¿Por qué el tono es de 520 Hz?

✅ Porque con la edad se oyen peor los agudos: en pruebas de la NFPA, el tono de 520 Hz en onda
cuadrada despertó al 92% de las personas con pérdida auditiva, contra el 56% del de 3.100 Hz
([investigacion-audio.md §1.1](investigacion-audio.md)). Suena con el patrón temporal-3 de las
alarmas de humo, por el canal de alarma (aunque el teléfono esté en silencio), y la voz que
pregunta es la del teléfono, grave y lenta, con frases fijas: predecible y sin internet.

### ¿Y una caída silenciosa?

✅ **Por la rutina.** La casa cuenta lo de siempre que suena por franja del día (cocina, agua,
puerta, baño, TV, voces) y lo manda como «Su día». Si de día no suena nada durante 3 horas, avisa
una vez como «día distinto» 🟡 ([`rutina.dart`](../app/lib/dominio/rutina.dart), 6 pruebas). En el
pitch se dice «golpe», no «caída»: el oído reconoce un golpe y por eso pregunta.

## La alerta

### ¿Cómo se garantiza que una alerta escale una sola vez?

✅ La casa registra la alerta en Supabase con su hora de vencimiento. `escalar_vencidas()` es un
solo `UPDATE` condicionado al estado: si dos procesos lo corren a la vez, Postgres revisa de nuevo
la condición y solo uno recibe la fila
([migración](../supabase/migrations/20261024130000_casa_y_familia.sql)). Lo corre la base cada 5 s
con pg_cron, y también cada lectura de la familia, así que escala aunque el teléfono de la casa se
apague en plena alarma.

### ¿Cómo le llega el aviso a la familia?

✅ **Por Telegram y por una llamada.** Cuando la alerta escala, el vigilante manda un Telegram con
el enlace a la web a todos los que se suscribieron desde la invitación, y la casa llama al hijo:
primero por WhatsApp (suele estar fuera del país) y, si no contestan, por teléfono normal. Las
llamadas a emergencias y al vecino salen por teléfono normal, en altavoz y con el volumen al
máximo.

La llamada de WhatsApp va por una **vía no oficial**: abre la fila de «llamada de voz» que WhatsApp
crea en la agenda de Android. Funciona solo si el contacto está guardado, y Android no dice si
contestaron. ❌ Los **mensajes** por WhatsApp (Kapso) se sacaron del demo: Meta restringió la cuenta.

### ¿Qué pasa si se va la luz, el internet o la señal?

- ✅ **Sin internet:** la alarma local suena igual y lo que hay que mandar espera en una cola, con
  su hora real ([`nube.dart`](../app/lib/datos/nube.dart)). La cola vive en memoria: si la app se
  cierra sin internet, se pierde.
- ✅ **Sin luz:** el latido manda si está enchufado (`EXTRA_PLUGGED`, no `isCharging()`, ver
  [investigacion-carga.md](investigacion-carga.md)) y la pantalla se deja apagar para que la
  batería dure.
- ✅ **Teléfono apagado:** la casa late cada 90 s; sin latido por 180 s, la familia ve «sin señal».

### ¿Qué pasa si se apaga la pantalla o el teléfono se reinicia?

✅ Un servicio en primer plano de tipo micrófono mantiene vivo el oído con la pantalla apagada
([`Guardia.kt`](../app/android/app/src/main/kotlin/ve/equipo25/casa/Guardia.kt)). 📐 Tras un
reinicio, Android 14 y 15 no dejan arrancar el micrófono solo: la salida es que la app sea la
pantalla de inicio del teléfono de mesa ([riesgos.md §3](riesgos.md)). Va como lo que viene.

### ¿Por qué la casa es Android y no iPhone?

📐 iOS no deja escuchar todo el día en segundo plano ([riesgos.md §2](riesgos.md)). La familia sí
puede usar cualquier teléfono: entra por web y recibe el aviso por Telegram.

## Las pastillas

### ¿Cómo se sabe cuántas quedan?

✅ El inventario es un **libro de movimientos** en la base: cada compra suma, cada «Ya me la tomé»
de la casa resta con `casa_tomar` y un conteo a mano ajusta. Nadie guarda «quedan 12» en una
columna, así la casa y la web nunca se pisan el número, y una toma repetida el mismo día no
descuenta dos veces ([migración](../supabase/migrations/20261024160000_pastillas_e_inventario.sql);
probado contra la base real con `make test-integracion`). Los días que alcanzan los calcula
[`inventario.ts`](../web/src/lib/familia/inventario.ts).

### ¿Cómo se carga el récipe?

⏳ Se le toma una foto al récipe en la web de la familia, Claude lo lee con salida estructurada y
la familia confirma antes de guardar con `familia_recetar`. Está en construcción
([pendientes.md](pendientes.md)); la lectura de facturas ya existe con el mismo patrón. La foto no
se guarda: va a Claude y se olvida.

## Seguridad

### ¿Cómo se protege el enlace de invitación y la casa?

✅ Todas las tablas tienen RLS activado y **ninguna política**: la llave pública no lee ni escribe
nada. Todo pasa por funciones que piden la clave de la casa (`casa_*`) o el token de la familia
(`familia_*`), aleatorios de 128 bits y guardados como hash SHA-256: quien lea la base no puede
entrar a ninguna casa ([migración](../supabase/migrations/20261024130000_casa_y_familia.sql),
pruebas de que una clave no escribe en otra casa). El token `demo` es público a propósito: es el
del QR. Las llaves nunca van al repo, que es público.

### ¿Qué datos personales guardan?

✅ Etiquetas de eventos con su hora, alertas, latidos, el récipe y el perfil de la casa (nombre,
contactos, condición de salud), nunca audio. Para el demo, todos los datos son inventados.

## Cómo comprobarlo

```bash
make test                # 110 pruebas de la app de la casa
make test-integracion    # la app contra la base real, con una casa que se crea y se borra
cd web && bun test       # la web: estado de la familia, audio, inventario
cd experimentos/modelos-audio && uv sync && ./descargar.sh && uv run comparar.py
```
