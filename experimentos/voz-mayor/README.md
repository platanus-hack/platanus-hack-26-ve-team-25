# ¿La casa entiende a una persona mayor?

La casa entiende pedidos de ayuda («me caí», «ayuda») y órdenes («Lucero, llama a mi hijo») con
Vosk, sin internet. No teníamos a quién grabar, así que medimos con **voces sintéticas** de
personas mayores generadas con ElevenLabs. Una voz real de 80 años tiembla, respira y articula
distinto, y se entiende peor: estos números son un techo, no la prueba final.

## Lo que salió

Todo el detalle está en [resultados.md](resultados.md) y fila por fila en [resultados.csv](resultados.csv).

| Condición | Pedidos del banco (71) | Órdenes (28) | Dichas a su manera (17) | Todas |
|---|---|---|---|---|
| Sin ruido | 99 % | 89 % | 85 % | 94 % |
| TV de fondo a 10 dB | 86 % | 59 % | 69 % | 77 % |
| TV de fondo a 5 dB | 51 % | 33 % | 36 % | 45 % |
| Calle y ventilador a 5 dB | 73 % | 67 % | 60 % | 70 % |

Con la ventana de audio de la app, entre 6 voces.

- **Los pedidos de ayuda se entienden; con la TV prendida, la mitad se pierde.** Una novela de
  fondo es lo peor, porque es voz sobre voz.
- **Las órdenes son lo más frágil con ruido.** «Lucero, llama a mi hijo» se entiende con 5 de 6
  voces sin ruido y con 1 de 6 con la TV o la calle: Vosk se queda en «lucero llama».
- **«Lucero, estoy bien» aguanta:** 6 de 6 sin ruido, con TV a 10 dB y con la calle. Es la que
  calla la alarma, así que es la que más importa.
- **«Ya me la tomé» falla con 5 de 6 voces aun sin ruido.** Vosk oye «llame la tomé»: «ya me»
  choca con «llame», que está en la gramática por las órdenes de llamar.
- **La ventana de la app corta las órdenes largas.** «Lucero, llama a una ambulancia» dura 3,7 s y
  llega a Vosk como «lucero llama a una». Cuesta poco: 89 % contra 92 % con la frase entera.
- **Falsos disparos:** sin ruido, 9 de 90 frases de casa y 2 de 42 de TV hacen actuar a la casa.
  La gramática cerrada empuja lo que oye hacia el banco: «Esa novela está buenísima» sale como
  «no veo». Un pedido pasa por «¿Está bien?», así que un falso disparo cuesta una pregunta, no una
  llamada.
- **La confianza mínima de 0,5 está bien puesta.** Bajarla no recupera casi nada; subirla a 0,6
  baja los falsos disparos de 23 a 16 (de 132) y cuesta de 2 a 4 puntos.

## Qué cambiaríamos (no se aplicó en el hackatón)

1. Aceptar «la tomé» mientras suena el recordatorio de la pastilla: ahí no hay otra frase con la
   que se confunda.
2. Esperar a que termine la frase en vez de 1,5 s fijos, para no cortar las órdenes largas.
3. Exigir que la frase del banco sea la mayor parte de lo que se entendió, para que una oración
   larga no se convierta en «no veo».
4. Repetir la medición con voces reales de personas mayores, y con la compuerta de YAMNet.

## Qué se mide

138 frases dichas por 6 voces de la biblioteca de ElevenLabs filtradas por español y edad «old»
(3 mujeres y 3 hombres, casi todos de acento rioplatense: no hay voces venezolanas mayores):

| Grupo | Frases | Qué debería pasar |
|---|---|---|
| Banco | 71 | Cada pedido de [`pedidos.dart`](../../app/lib/dominio/pedidos.dart): abre «¿Está bien?» con su tipo |
| Órdenes | 28 | «Lucero, llama…», «Lucero, estoy bien», «Ya me la tomé», «No» ([`comandos.dart`](../../app/lib/dominio/comandos.dart)) |
| Variantes | 17 | Como lo diría alguien sin calcar el banco: «¡Ay, ayuda, ayuda!», «Lucero, llámame a mi hijo» |
| Casa | 15 | Conversación de todos los días: no debe pasar nada |
| TV | 7 | Frases de novela, noticiero y comerciales: no debe pasar nada |

Si existe `guion.txt` (fuera del repo), también se prueban las frases del pitch, para saber cuáles
pueden hacer saltar a la casa en la tarima; ese informe queda en `resultados-guion.md`, también
fuera del repo.

Cada frase se prueba sin ruido y con ruido de casa generado con ElevenLabs (una TV con una novela
y una ventana a la calle con tráfico y un ventilador), a 10 y 5 dB de relación señal/ruido.

## Cómo se replica la casa

- **Las frases salen del código de la app**: [`casa.py`](casa.py) lee los `.dart` de
  `app/lib/dominio/`, así que si el banco cambia, el experimento usa el nuevo.
- **El mismo reconocedor:** `vosk-model-small-es-0.42` (el de `app/tool/descargar_vosk.sh`), con
  la gramática cerrada de `datos/frases.dart` (pedidos + órdenes + `[unk]`) y la confianza mínima
  de 0,5 por palabra. La app usa `vosk-android` 0.3.47; aquí, `vosk` 0.3.44 para Python (la 0.3.45
  no trae paquete para Mac ARM), con el mismo decodificador de Kaldi.
- **La misma lógica:** `normalizar`, `ordenPorVoz`, `pedidoPorVoz` y el orden de `_actuar`
  (primero órdenes, después pedidos), copiados de la app y probados con los casos de sus
  comentarios (`python3 casa.py`).
- **La misma ventana de audio:** cuando YAMNet marca que alguien habla, la casa espera 1,5 s y le
  pasa a Vosk los últimos 5 s; si la voz sigue, repite cada 4 s (`ui/controlador.dart`). Se supone
  que YAMNet tarda 1 s en marcar la voz. Para separar lo que falla Vosk de lo que corta la
  ventana, cada frase se prueba también entera.

## Lo que no mide

- **Voces reales de personas mayores**, con temblor, prótesis dentales o voz débil.
- **La compuerta de YAMNet:** la casa solo llama a Vosk si YAMNet oye voz y no TV (`_hablanEnLaCasa`).
  Aquí Vosk recibe todas las frases; con la TV prendida, en la casa real puede que ni se intente.
- **La sala:** distancia, eco y el micrófono de un teléfono viejo.
- **«¿Pudo hablar con Josuep?»:** esa respuesta la escucha el reconocedor de voz de Android
  (`datos/voz.dart`), no Vosk.

## Cómo correrlo

```bash
./descargar.sh                 # el modelo de Vosk de la app (40 MB, no va al repo)
uv run generar.py              # ~830 audios con ElevenLabs (~23 mil caracteres); lo que existe no se repite
uv run evaluar.py              # escribe resultados.md y resultados.csv
```

`generar.py` toma `ELEVENLABS_API_KEY` del entorno o de `web/.env.local`. Los audios quedan en
`audio/` y no van al repo. Con varios procesos, Vosk no da exactamente lo mismo en cada corrida:
puede cambiar una frase, un punto en alguna celda.
