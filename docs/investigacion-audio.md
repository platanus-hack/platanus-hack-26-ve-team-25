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
   oye: para eso está el botón «Huele a gas».

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
| **El reconocimiento de voz se equivoca más** con personas mayores, sobre todo con hombres | [Vipperla, tesis de Edimburgo, 2011](https://era.ed.ac.uk/handle/1842/5725); [JAMIA 2023, entrevistas en residencias](https://cris.maastrichtuniversity.nl/en/publications/the-development-of-an-automatic-speech-recognition-model-using-in/) | La palabra clave «¡auxilio!» se prueba con voces mayores reales antes de prometerla. Nunca es la única vía: la pantalla y los botones siguen |
| **Oye peor los agudos** (pérdida de audición con la edad) | En pruebas de la NFPA, el tono de 520 Hz en onda cuadrada despertó al 92% de las personas con pérdida auditiva, contra el 56% del tono de 3.100 Hz ([Wikipedia, con las pruebas de 1970](https://en.wikipedia.org/wiki/Fire_alarm_notification_appliance)) | **La alarma de confirmación de 60 s usa 520 Hz en onda cuadrada**, no un pitido agudo. La voz de «¿Está bien?» es grave, lenta y fuerte, y además la pantalla destella y el teléfono vibra |

**Cómo lo probamos.** Hay que grabar voces mayores reales: los abuelos del equipo, con su permiso.
Diez frases dichas normal, un «¡ayuda!» débil, un quejido y una tos. Las grabaciones se quedan en la
máquina de quien grabó y no se suben al repo, que es público. Con eso se mide si YAMNet y la
palabra clave las detectan a 1 m y a 4 m del teléfono.

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

### Candidatos a comparar

Hay que confirmar la licencia y el formato de cada uno en su repositorio antes de elegir.

Todos hacen lo mismo que YAMNet: escuchan una ventana corta y dicen qué sonidos hay, con las
clases de AudioSet. La diferencia está en cuánto aciertan y cuánto pesan. El mAP mide el acierto
en AudioSet: más alto es mejor.

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

### Criterio de decisión

Se elige el modelo que cumpla las tres condiciones:

1. Corre en tiempo real en el teléfono más viejo del equipo, dos ventanas por segundo, sin
   recalentarse.
2. Su embedding separa las falsas alarmas grabadas (pregunta 3).
3. Su licencia permite un proyecto abierto.

Si YAMNet cumple, se queda YAMNet: cambiar de modelo el sábado cuesta más de lo que suma en el
demo.
