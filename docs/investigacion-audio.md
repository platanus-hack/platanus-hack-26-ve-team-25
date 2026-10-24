# Investigación: audio

Qué separa la voz humana del resto de los sonidos de la casa, y el plan para elegir el modelo de
audio y personalizarlo para cada casa. Al 24-oct-2026.

## 1. ¿Hay frecuencias de la voz fáciles de separar?

**No hay una banda de frecuencia que sea solo de la voz.** La voz se separa por su estructura en
el tiempo, no por un filtro de frecuencias. Un filtro pasabanda no sirve: deja pasar la TV, la radio
y la música, y la voz de la TV es voz humana de verdad.

| Rasgo | Valor | Para qué nos sirve |
|---|---|---|
| Frecuencia fundamental (F0) | Hombres ~85–180 Hz, mujeres ~165–255 Hz (valores típicos de adultos) | Comparte la banda con la TV, motores y electrodomésticos. No separa por sí sola |
| Energía útil del habla | ~300–3.400 Hz (la banda telefónica) | Igual que arriba: es la banda más llena de la casa |
| Armonicidad | La voz es periódica: F0 más sus armónicos | Separa la voz del ruido, de los golpes y del agua. No la separa de la TV |
| Modulación silábica | El habla sube y baja de volumen ~4–5 veces por segundo; la mayoría de los sonidos que no son voz modulan por encima de 10 Hz ([Arnal 2015](https://neurosciencenews.com/acoustic-properties-fear-scream-2257/); [patente USPTO 8473282](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/8473282)) | Detector barato de "alguien está hablando" |
| Aspereza del grito | Los gritos se concentran en modulaciones de ~30–150 Hz, lejos del habla normal ([Arnal et al., Current Biology 2015](https://archive-ouverte.unige.ch/unige:75898)) | Separa un grito del habla normal, sin modelo |
| Alarma de humo | Tono fijo de 3.100 Hz o de 520 Hz en onda cuadrada, con el patrón temporal-3: tres pulsos de 0,5 s y una pausa de 1,5 s ([Wikipedia](https://en.wikipedia.org/wiki/Fire_alarm_notification_appliance); [manual System Sensor](https://s3.amazonaws.com/sdepot.com/lit/FIR001/B200SLFWH_IM.pdf)) | Se detecta con un filtro estrecho más el ritmo, sin ML y con casi ningún falso positivo |

**Lo que esto cambia en el diseño**

1. **El grito y la alarma se confunden por aspereza**: las alarmas también caen en el rango de
   30–150 Hz ([Arnal 2015](https://www.aesthetics.mpg.de/en/newsroom/news/news-article/article/scream-if-you-have-to.html)).
   Se separan porque la alarma es un tono fijo con ritmo exacto, y el grito cambia de tono.
2. **Detectores clásicos antes del modelo**: un detector de la alarma (filtro de 3.100 Hz y
   520 Hz más el patrón temporal-3) y uno de aspereza para gritos. Son baratos y explicables, y el
   modelo de ML confirma. Eso extiende la compuerta de decibeles que ya está en `/escucha`.
3. **La TV no se separa por frecuencia**. Se separa por contexto: la TV suena largo y parejo, y no
   mueve el piso. Se mantiene la fusión con la vibración del plan.
4. **La alarma de humo es el detector de techo que pita**, no algo que tengamos que fabricar. Si la
   casa tiene uno, el teléfono lo oye y avisa aunque el abuelo no reaccione. Falta confirmar
   cuántas casas en Venezuela tienen detector. Si son pocas, vale más para los abuelos que viven
   fuera, o como accesorio barato que la familia manda a instalar. El gas de las bombonas no se
   oye: para eso la persona puede decir «huele a gas» en voz alta.

Pendiente de medir: en qué frecuencias cae el golpe de una caída de una persona sobre cerámica, a
3–5 m del teléfono.

## 1.1 La voz del adulto mayor (prioridad)

Todo el sistema se diseña para la voz y el oído de un adulto mayor, no de un adulto joven. Los
modelos de audio y de habla se entrenaron casi siempre con voces jóvenes.

| Qué cambia | Fuente | Qué hacemos |
|---|---|---|
| **Voz más débil**: menos volumen y proyección, le cuesta hacerse oír con ruido | [Revisión de la voz senil, 2022](https://doaj.org/article/bfbbbb4f9fa14377baedb0a1a9dc124d); [hoja clínica del NHS](https://www.wsh.nhs.uk/CMS-Documents/Patient-leaflets/SpeechandLanguageTherapyServices/6428-1-Presbyphonia.pdf) | **Un pedido de ayuda puede sonar más bajo que la TV.** La compuerta de dB no puede descartar lo que suena bajo: se mide contra el fondo de esa casa, y la voz baja también pasa al modelo |
| **Voz aireada, ronca y temblorosa**, con menos armónicos | [Revisión 2022](https://doaj.org/article/bfbbbb4f9fa14377baedb0a1a9dc124d); [Beton et al., revisión 2023](https://pmc.ncbi.nlm.nih.gov/articles/PMC10339270) | La armonicidad sirve menos para reconocer su voz. Un umbral que funciona con voces jóvenes puede no verla |
| **F0 distinta**: baja en las mujeres y sube un poco en los hombres | [Estudio de adultos jóvenes y mayores, 1991](https://www.ncbi.nlm.nih.gov/pubmed/1749230); [estudio de la vida entera, 2020](https://pmc.ncbi.nlm.nih.gov/articles/PMC7229708/) | Nada de umbrales fijos de tono. Se calibra con la voz de esa casa |
| **Frases más cortas**, con menos aire al empezar a hablar | [Estudio preliminar registrado en ISRCTN](https://www.isrctn.com/editorial/retrieveFile/3284e1a9-a77a-46f2-b991-4dca5ad4e9c8/45985) | Un «¡ayuda!» puede ser corto y débil. Hay que buscar también las clases de quejido y llanto de YAMNet («Wail, moan», «Crying, sobbing»), no solo el grito |
| **El reconocimiento de voz se equivoca más** con personas mayores, sobre todo con hombres | [Vipperla, tesis de Edimburgo, 2011](https://era.ed.ac.uk/handle/1842/5725); [JAMIA 2023, entrevistas en residencias](https://cris.maastrichtuniversity.nl/en/publications/the-development-of-an-automatic-speech-recognition-model-using-in/) | La palabra clave «¡auxilio!» no se promete como infalible. Nunca es la única vía: la pantalla y los botones siguen |
| **Oye peor los agudos** (pérdida de audición con la edad) | En pruebas de la NFPA, el tono de 520 Hz en onda cuadrada despertó al 92% de las personas con pérdida auditiva, contra el 56% del tono de 3.100 Hz ([Wikipedia, con las pruebas de 1970](https://en.wikipedia.org/wiki/Fire_alarm_notification_appliance)) | **La alarma de confirmación de 60 s usa 520 Hz en onda cuadrada**, no un pitido agudo. La voz de «¿Está bien?» es grave, lenta y fuerte, y además la pantalla destella y el teléfono vibra |

**Lo que no se midió.** El equipo no tiene personas mayores cerca para grabar, así que el oído y
las frases de voz no se probaron con voces mayores reales. Las decisiones de arriba se tomaron por
la literatura, y se dice así en el pitch: «no está medido con voces mayores».

## 1.2 El audio llega crudo a YAMNet

**Decidido: no se limpia el audio.** YAMNet se entrenó con audio crudo y ruidoso (videos de
YouTube de AudioSet) y tiene su propio frente: lo pasa a 16 kHz mono y a 64 bandas mel entre 125 y
7.500 Hz. Si lo limpiamos, le llega un sonido que nunca vio. Y los supresores de ruido de voz,
como RNNoise, tratan como ruido justo lo que buscamos: la alarma, el vidrio y el golpe.

La única regla es **que Android tampoco lo limpie**. El modo de llamadas del micrófono trae su
propio supresor de ruido y control de volumen. Hay que pedir la fuente de audio `UNPROCESSED` o
`VOICE_RECOGNITION`. Falta confirmar cómo se elige con el paquete `record` (sección 4).

## 2. Plan: modelos tipo YAMNet y personalización por casa

**Punto de partida.** YAMNet sí es open source: el código y los pesos están en
[tensorflow/models](https://github.com/tensorflow/models/tree/master/research/audioset/yamnet)
con licencia Apache 2.0. Es una MobileNet v1 entrenada con AudioSet (521 clases) que entrega,
además de las clases, un embedding de 1.024 números por cada ventana de ~1 s.

**La idea clave: no se reentrena YAMNet.** Se congela y se usa como "oído". Lo que aprende cada
casa es una capa chica encima, que corre en el teléfono:

```text
micrófono ─► detectores clásicos (dB, alarma, aspereza)
          └► YAMNet congelado ─► embedding de 1.024 ─┬─► capa de la casa (falsas alarmas)
                                                      └─► modelo de rutina (qué suena y a qué hora)
```

- **Capa de la casa**: cada vez que el abuelo apaga una alarma, ese embedding queda como "falsa
  alarma de esta casa". Un kNN o una regresión logística sobre los embeddings aprende con pocos
  ejemplos, y se puede escribir en Dart sin entrenar redes en el teléfono.
- **Modelo de rutina**: un conteo por franja de 15 minutos de qué tipos de evento suenan (agua,
  cocina, puerta, TV, voz). Con unos días de historia se sabe lo esperado. Si a las 9:00 no hubo
  nada de lo que siempre hay, se avisa. Es estadística simple, explicable y no necesita GPU.
- Solo se guardan embeddings y conteos, nunca el audio.

### Preguntas que hay que responder

| # | Pregunta | Cómo se responde | Tiempo |
|---|---|---|---|
| 1 | ¿YAMNet corre en Flutter en un Android viejo? | Probar `tflite_flutter` con el `.tflite` oficial en el teléfono más viejo del equipo. Medir latencia, CPU y temperatura en 10 min | 1 h |
| 2 | ¿Hay un modelo más preciso que quepa igual? | Comparar con la tabla de abajo: tamaño, mAP en AudioSet, si existe en TFLite y su licencia | 1 h |
| 3 | ¿Los embeddings separan las falsas alarmas de una casa? | Grabar 20 sonidos reales por clase (ollas, puerta, TV, golpe, grito) y medir el kNN con validación cruzada | 1,5 h |
| 4 | ¿El modelo de rutina detecta un día anómalo? | Simular 7 días de eventos con un generador y verificar que marca el día sin actividad matutina | 1 h |
| 5 | ¿Los detectores clásicos aciertan? | Probar la alarma de 3.100 Hz y 520 Hz y gritos contra TV con gritos | 1 h |
| 7 | ¿Qué sienten los sensores de un teléfono de 2019? | Ver la sección 3: registrar cada sensor 10 min con la casa quieta, y luego con una caída simulada, una puerta y la luz | 1,5 h |

### Candidatos a comparar

Hay que confirmar la licencia y el formato de cada uno en su repositorio antes de elegir.

Todos hacen lo mismo que YAMNet: escuchan una ventana corta y dicen qué sonidos hay, con las
clases de AudioSet. La diferencia está en cuánto aciertan y cuánto pesan.

**Qué es el mAP.** Para cada clase, por ejemplo «alarma de humo», se le dan al modelo miles de clips
de prueba de AudioSet y se ordenan por su puntaje. La precisión promedio (AP) mide qué tan arriba
de esa lista quedan los clips que de verdad tienen alarma: 1 es perfecto, todos primero. El mAP es
el promedio de las 527 clases. No es un «porcentaje de aciertos»: un mAP de 0,47 contra 0,31
quiere decir que el modelo ordena mucho mejor. Además promedia clases que no nos importan, como los
géneros de música, así que lo que vale para nosotros se mide con nuestras propias grabaciones.

| Modelo | Qué es | Tamaño | mAP | Licencia | Para nosotros |
|---|---|---|---|---|---|
| YAMNet | MobileNet v1 de Google | ~3,7 M parámetros | ~0,31 | Apache 2.0 | Base actual. Ya funciona en `/escucha` y existe en TFLite |
| EfficientAT `mn04_as` ([repo](https://github.com/fschmid56/EfficientAT)) | MobileNet v3 que aprendió imitando a modelos transformer grandes (destilación) | 0,98 M | 0,432 | MIT | Más chico que YAMNet y bastante más preciso. Es el mejor candidato si hay que cambiar |
| EfficientAT `mn10_as` | Lo mismo, más grande | 4,88 M | 0,471 | MIT | Tamaño parecido a YAMNet, mucho más preciso |
| PANNs `Cnn14` ([repo](https://github.com/qiuqiangkong/audioset_tagging_cnn)) | CNN grande de referencia, de 2019 | Grande | 0,431 | MIT | Pesada para un teléfono viejo. Sus versiones de detección por cuadro dicen *cuándo* ocurre cada sonido, no solo *qué* suena |
| BEATs, AST, CLAP | Transformers de audio | Muy grandes | Más altos | Varias | Solo en la computadora, para etiquetar grabaciones de prueba |

Los datos de YAMNet son aproximados y salen de su documentación. Los de EfficientAT y PANNs, de sus
repositorios. EfficientAT y PANNs están en PyTorch: pasarlos a TFLite para Flutter es un paso más
que hay que probar (pregunta 2).

### Resultado de la comparación (24-oct, madrugada)

Corrimos los modelos sobre 640 sonidos de casa de ESC-50, en la computadora, con un solo hilo.
El código y las tablas completas están en
[experimentos/modelos-audio](../experimentos/modelos-audio/README.md).

| Modelo | MB | ms por 1 s de audio | Acierto top-5, ventanas de 1 s | Acierto top-5, ventanas de 5 s |
|---|---|---|---|---|
| YAMNet (TFLite) | 4,1 | 2,5–4,8 | **82%** | 81% |
| EfficientAT mn04 (ONNX) | 4,3 | 3,8–4,4 | 64% | 83% |
| EfficientAT mn10 (ONNX) | 19,8 | 5,4–6,4 | 0% (se rompe) | 79% |
| PANNs MobileNetV1 (ONNX) | 23,6 | 5,2–5,5 | 76% | 80% |
| PANNs Cnn14 (ONNX) | 327 | 58–67 | 81% | 83% |
| sherpa CED tiny int8 | 6,1 | 5,7–5,8 | 54% | **86%** |
| sherpa CED mini int8 | 10,5 | 7,4–7,9 | 55% | **87%** |
| sherpa Zipformer small int8 | 27 | 22–26 | 81% | 87% |

**Lo que dice:**

1. **Las dos conversiones funcionan.** EfficientAT y PANNs pasan de PyTorch a ONNX con el
   espectrograma adentro y dan lo mismo que en PyTorch (diferencia menor a 0,000001).
2. **El largo de la ventana decide.** Con ventanas de 1 s, como hoy en `/escucha`, gana YAMNet:
   está hecho para eso. Con ventanas de 5 s ganan los CED de sherpa, que se entrenaron con clips
   largos.
3. **La diferencia es chica**: 81% contra 86–87%, en 640 clips. Es real, pero no cambia el demo.
4. **Todos menos Cnn14 y Zipformer analizan 1 s de audio en menos de 10 ms** en la computadora.
   En un teléfono viejo será varias veces más lento y seguirá sobrando tiempo, pero hay que
   medirlo.
5. **Las clases difíciles son las mismas para todos**: la puerta que cruje (15–30%) y la lavadora
   (2–10%). No son emergencias.

**Decisión propuesta:** se queda **YAMNet** para el núcleo, porque ya funciona y cumple el
criterio. **sherpa CED tiny int8 con ventanas de 5 s** es el candidato si sobra tiempo: suma 5
puntos y el mismo paquete de Flutter trae la palabra clave y la detección de voz. Una ventana de
5 s tarda hasta 5 s más en avisar, y eso no importa si la alarma de la casa espera 60 s.

**Límites:** ESC-50 son grabaciones limpias y cercanas, sin TV, sin distancia y sin voces de
personas mayores. Falta medir en el teléfono.

### Criterio de decisión

Se elige el modelo que cumpla las tres condiciones:

1. Corre en tiempo real en el teléfono más viejo del equipo, dos ventanas por segundo, sin
   recalentarse.
2. Su embedding separa las falsas alarmas grabadas (pregunta 3).
3. Su licencia permite un proyecto abierto.

Si YAMNet cumple, se queda YAMNet: cambiar de modelo el sábado cuesta más de lo que suma en el
demo.

## 3. Los demás sensores del teléfono

Un teléfono Android de 2019 en adelante trae más que micrófono. Cada sensor suma una señal
independiente. Para que suene el aviso basta una sola señal fuerte o dos que coincidan, y la
persona sigue siendo el sensor que confirma.

| Sensor | ¿Lo trae un teléfono de 2019? | Qué nos dice | Uso |
|---|---|---|---|
| Acelerómetro | Todos | Vibraciones: golpes y pasos fuertes en el piso | Fusión con el sonido: un golpe que suena *y* hace vibrar. Funciona mejor con el teléfono pegado a la pared o al piso que sobre una mesa |
| Giroscopio | Casi todos | Que alguien movió o levantó el teléfono | Señal de vida para la rutina. También detecta si el teléfono se cayó |
| Sensor de luz | Todos | Si las luces del cuarto se prenden o se apagan | **Rutina sin micrófono y sin problema de privacidad**: «prendió la luz a las 6:50». Una luz prendida a las 3 a. m. por mucho rato es una alerta amarilla |
| Proximidad | Casi todos. Algunos modelos recientes lo simulan por software y responden mal | Algo a pocos centímetros de la parte de arriba de la pantalla | **Decidido: la alarma se apaga pasando la mano por encima**, sin atinarle a un botón. Pensado para quien ve mal o tiene temblor. El botón grande sigue, por si el sensor falla |
| Carga de batería | Todos | Si el teléfono dejó de cargar | Detecta el apagón, que el plan ya usa para no confundirlo con una emergencia |
| Barómetro | Solo algunos | Cambios de presión, por ejemplo al abrir una puerta en un espacio cerrado | Extra solo si el teléfono lo trae. No se promete |
| Magnetómetro | Casi todos | Cerca de metal que se mueve | Poco útil en casa. Fuera del alcance |
| Cámara | Todos | Imagen | **No se usa**: vigilar con video a la persona es justo lo que la hace sentir invadida |

**Lo que limita a todos: Android en segundo plano.** Desde Android 9, una app en segundo plano no
puede usar el micrófono y deja de recibir los sensores continuos, como el acelerómetro y el
giroscopio. La app de la casa tiene que correr como servicio en primer plano, con una notificación
fija y el teléfono enchufado. Los paquetes están en la sección 4.

**Cómo encaja con la rutina de la sección 2.** El modelo de rutina cuenta por franja del día
todas las señales, no solo los sonidos: luz, movimiento del teléfono, agua, cocina, TV. Mientras
más fuentes tenga la rutina, menos depende de que el micrófono oiga bien la voz del abuelo.

## 4. Paquetes de Flutter

Confirmados en pub.dev el 24-oct-2026.

| Para qué | Paquete | Versión | Licencia | Nota |
|---|---|---|---|---|
| **Servicio en primer plano y notificación fija** | [`flutter_foreground_task`](https://pub.dev/packages/flutter_foreground_task) | 11.0.3 (hace ~1,5 meses) | MIT | **El elegido.** Notificación con título, texto y botones. Acepta el tipo `microphone`. Sigue corriendo con la app cerrada y puede arrancar al encender el teléfono. 583 likes |
| Alternativa al anterior | [`flutter_background_service`](https://pub.dev/packages/flutter_background_service) | 5.1.0 (hace 22 meses) | MIT | Funciona, pero lleva casi dos años sin versión nueva |
| Micrófono en vivo | [`record`](https://pub.dev/packages/record) | 7.1.2 | BSD-3 | Entrega PCM de 16 bits en vivo con `startStream`. Falta confirmar cómo pedir la fuente `UNPROCESSED` |
| YAMNet en el teléfono | [`tflite_flutter`](https://pub.dev/packages/tflite_flutter) | 0.12.1 (hace 12 meses) | Apache 2.0 | Publicado por tensorflow.org. Acelera con NNAPI o GPU en Android |
| Acelerómetro, giroscopio, barómetro | [`sensors_plus`](https://pub.dev/packages/sensors_plus) | 7.1.1 | BSD-3 | No trae luz ni proximidad |
| Proximidad | [`proximity_sensor`](https://pub.dev/packages/proximity_sensor) | 2.0.0 | MIT | Avisa cerca o lejos. Su autor advierte que los sensores simulados de algunos modelos recientes no son confiables |
| Luz ambiente | [`light`](https://pub.dev/packages/light) o [`ambient_light`](https://pub.dev/packages/ambient_light) | 5.0.0 / 0.2.1 | Por confirmar | Hay que probar cuál responde en el teléfono viejo |
| Carga y batería | `battery_plus` | Por confirmar | Por confirmar | Para detectar el apagón |

**Las reglas de Android que cambian el diseño**

1. **Android 14 o más**: el servicio tiene que declarar el tipo `microphone`, con los permisos
   `FOREGROUND_SERVICE_MICROPHONE` y `RECORD_AUDIO`
   ([Android Developers](https://developer.android.com/guide/components/fg-service-types)). Y un
   servicio de micrófono no puede arrancar mientras la app está en segundo plano: **se arranca
   con la app abierta**, en la configuración inicial de la casa.
2. **Android 15 o más: el servicio de micrófono no puede arrancar solo al encender el teléfono**
   ([flutter_foreground_task](https://pub.dev/packages/flutter_foreground_task)). En Venezuela,
   si se va la luz y el teléfono se apaga, al volver deja de escuchar. Lo que hacemos:
    - El latido se corta y la familia ve «la casa se reinició, sin escuchar», en amarillo.
    - Al encender, la app muestra en pantalla «Toque para volver a cuidar».
    - Se recomienda dejar el teléfono enchufado con su batería sana, para que aguante el apagón
      sin apagarse.
3. **iOS no sirve como teléfono de la casa**: no permite escuchar todo el día en segundo plano. La
   casa es un Android. La familia puede usar Android o iPhone, porque solo recibe avisos.
