# Comparación de modelos de audio

Compara cuatro familias de modelos que reconocen sonidos con las clases de AudioSet, para elegir
el «oído» de la app: YAMNet, EfficientAT, PANNs y los modelos de audio de sherpa-onnx. No hace
falta micrófono: todo corre sobre archivos de audio.

Resultados: con ventanas de 1 s, como analiza hoy `/escucha`, en
[resultados-1s.md](resultados-1s.md), y con ventanas de 5 s en
[resultados-5s.md](resultados-5s.md). Se prueban los dos largos porque YAMNet está hecho para
ventanas de ~1 s, mientras que EfficientAT y CED se entrenaron con clips de 10 s: comparar solo con
1 s los castigaría injustamente.

## Qué mide

- **Tamaño** del archivo del modelo.
- **Velocidad:** milisegundos para analizar 1 s de audio con un solo hilo de CPU. Es una CPU de
  escritorio: sirve para ordenar los modelos, no para saber cuánto tardan en un teléfono viejo.
- **Aciertos:** 640 clips de 5 s de [ESC-50](https://github.com/karolpiczak/ESC-50) (16 clases
  de sonidos de casa, 40 clips cada una). Acierta si una etiqueta correcta de AudioSet queda
  entre las 5 primeras. Cada clip se analiza como en la app: ventanas que avanzan a la mitad de
  su largo, una compuerta que salta el silencio y el puntaje más alto de cada clase. La
  compuerta importa: ESC-50 trae silencio digital absoluto, que un micrófono real nunca da, y con
  eso EfficientAT devuelve cualquier cosa.

EfficientAT y PANNs están en PyTorch: `exportar_onnx.py` los pasa a ONNX con el espectrograma
adentro y verifica que den lo mismo que en PyTorch. Así corren en Flutter con ONNX Runtime.

## Cómo correrlo

Necesita [uv](https://docs.astral.sh/uv/). Los modelos y los datos (~1,5 GB) no van en el repo.

```bash
cd experimentos/modelos-audio
uv sync
./descargar.sh                 # modelos, código de EfficientAT y PANNs, y ESC-50
uv run exportar_onnx.py        # EfficientAT y PANNs a ONNX
uv run comparar.py --ventana 1 --salida resultados-1s.md   # unos 10 minutos
uv run comparar.py --ventana 5 --salida resultados-5s.md
```

## Límites de esta prueba

- ESC-50 son grabaciones limpias y cercanas. Una casa real tiene TV, distancia y eco.
- No hay voces de personas mayores: eso va con Common Voice (60+) y notas de voz donadas, que no
  se suben al repo.
- La velocidad en el teléfono se mide aparte, con el teléfono conectado por USB.
