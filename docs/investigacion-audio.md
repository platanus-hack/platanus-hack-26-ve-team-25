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
4. **La voz de los adultos mayores cambia**: la F0 baja en las mujeres y sube un poco en los
   hombres, con más temblor y voz aireada ([estudio de adultos jóvenes y mayores, 1991](https://www.ncbi.nlm.nih.gov/pubmed/1749230);
   [estudio de la vida entera, 2020](https://pmc.ncbi.nlm.nih.gov/articles/PMC7229708/)). Un modelo
   entrenado con voces jóvenes puede fallar con el abuelo. Esa es otra razón para personalizar.

Pendiente de medir: en qué frecuencias cae el golpe de una caída de una persona sobre cerámica, a
3–5 m del teléfono.

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

| Modelo | Qué es | Por qué mirarlo |
|---|---|---|
| YAMNet | MobileNet v1, AudioSet, 521 clases | Base actual. Ya funciona en `/escucha` y existe en TFLite |
| EfficientAT (`fschmid56/EfficientAT`) | MobileNet v3 entrenadas con destilación desde transformers | Más precisas que YAMNet a un tamaño parecido. Pensadas para dispositivos |
| PANNs (`qiuqiangkong/audioset_tagging_cnn`) | CNN14 y MobileNet, AudioSet | Referencia clásica. CNN14 es grande, pero tiene variantes móviles |
| VGGish | El antecesor de YAMNet | Solo como comparación: más pesado y menos preciso |
| BEATs, AST, CLAP | Transformers de audio | Demasiado pesados para un teléfono viejo. Sirven para etiquetar datos en la computadora |

### Criterio de decisión

Se elige el modelo que cumpla las tres condiciones:

1. Corre en tiempo real en el teléfono más viejo del equipo, dos ventanas por segundo, sin
   recalentarse.
2. Su embedding separa las falsas alarmas grabadas (pregunta 3).
3. Su licencia permite un proyecto abierto.

Si YAMNet cumple, se queda YAMNet: cambiar de modelo el sábado cuesta más de lo que suma en el
demo.
