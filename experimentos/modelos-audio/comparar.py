"""Compara YAMNet, EfficientAT, PANNs y sherpa-onnx con los mismos sonidos de casa.

Mide tres cosas por modelo:
- Tamaño del archivo.
- Velocidad: milisegundos para analizar 1 s de audio con un solo hilo de CPU, como en un teléfono.
- Aciertos: con clips de ESC-50 de sonidos de casa, si la etiqueta correcta de AudioSet queda
  entre las 5 primeras. Cada clip de 5 s se analiza en ventanas de 1 s cada 0,5 s y se queda el
  puntaje más alto de cada clase, igual que en la app.

Uso: uv run comparar.py [--clips-por-clase N] [--ventana SEGUNDOS] [--salida ARCHIVO]
"""

import argparse
import csv
import statistics
import time
from pathlib import Path

import librosa
import numpy as np
import onnxruntime as ort
import pandas as pd
import sherpa_onnx
from ai_edge_litert.interpreter import Interpreter

AQUI = Path(__file__).parent
MODELOS = AQUI / "modelos"
ESC50 = AQUI / "datos" / "ESC-50-master"

# Clases de ESC-50 que pueden sonar en la casa de un adulto mayor, y las etiquetas de AudioSet
# que cuentan como acierto para cada una.
CLASES = {
    "glass_breaking": ["Glass", "Shatter", "Breaking"],
    "door_wood_knock": ["Knock", "Door", "Tap", "Wood"],
    "clock_alarm": ["Alarm clock", "Alarm", "Beep, bleep", "Buzzer", "Ringtone", "Telephone bell ringing", "Bell"],
    "siren": ["Siren", "Civil defense siren", "Emergency vehicle", "Police car (siren)", "Ambulance (siren)",
              "Fire engine, fire truck (siren)"],
    "crying_baby": ["Baby cry, infant cry", "Crying, sobbing"],
    "coughing": ["Cough", "Throat clearing"],
    "sneezing": ["Sneeze"],
    "breathing": ["Breathing", "Gasp", "Pant", "Wheeze", "Snort"],
    "snoring": ["Snoring", "Breathing"],
    "laughing": ["Laughter", "Giggle", "Chuckle, chortle", "Belly laugh", "Snicker"],
    "footsteps": ["Walk, footsteps", "Run"],
    "toilet_flush": ["Toilet flush"],
    "pouring_water": ["Pour", "Water", "Liquid", "Water tap, faucet", "Fill (with liquid)"],
    "door_wood_creaks": ["Creak", "Door", "Squeak"],
    "vacuum_cleaner": ["Vacuum cleaner"],
    "washing_machine": ["Washing machine", "Mechanical fan", "Mechanisms"],
}


def etiquetas_audioset(ruta: Path) -> list[str]:
    with open(ruta) as f:
        return [fila["display_name"] for fila in csv.DictReader(f)]


class Modelo:
    """Recibe 1 s de audio y devuelve una probabilidad por etiqueta."""

    nombre: str
    sr: int
    etiquetas: list[str]
    archivo: Path

    def __call__(self, ventana: np.ndarray) -> np.ndarray:
        raise NotImplementedError


VENTANA_S = 1.0  # largo de cada ventana en segundos; se cambia con --ventana


class Yamnet(Modelo):
    def __init__(self):
        self.nombre, self.sr = "YAMNet (TFLite)", 16000
        self.archivo = MODELOS / "yamnet.tflite"
        self.etiquetas = etiquetas_audioset(MODELOS / "yamnet_class_map.csv")
        self.inter = Interpreter(model_path=str(self.archivo), num_threads=1)
        self.inter.allocate_tensors()
        self.entrada = self.inter.get_input_details()[0]
        self.salida = self.inter.get_output_details()[0]
        self.largo = int(self.entrada["shape"][-1])  # 15.600 muestras: 0,975 s

    def __call__(self, ventana):
        # YAMNet ve 0,975 s por vez: una ventana más larga se parte y se queda el máximo
        trozos = [ventana[i : i + self.largo] for i in range(0, max(1, len(ventana) - self.largo + 1), self.largo // 2)]
        salidas = []
        for trozo in trozos:
            x = np.zeros(self.largo, np.float32)
            x[: len(trozo)] = trozo
            self.inter.set_tensor(self.entrada["index"], x.reshape(self.entrada["shape"]))
            self.inter.invoke()
            salidas.append(self.inter.get_tensor(self.salida["index"]).reshape(-1))
        return np.max(salidas, axis=0)


class Onnx(Modelo):
    """EfficientAT y PANNs exportados por exportar_onnx.py: audio a 32 kHz adentro, probabilidades afuera."""

    def __init__(self, nombre: str, archivo: str):
        self.nombre, self.sr = nombre, 32000
        self.archivo = MODELOS / archivo
        self.etiquetas = etiquetas_audioset(MODELOS / "sherpa-onnx-ced-mini-audio-tagging-2024-04-19/class_labels_indices.csv")
        opciones = ort.SessionOptions()
        opciones.intra_op_num_threads = opciones.inter_op_num_threads = 1
        self.sesion = ort.InferenceSession(str(self.archivo), opciones, providers=["CPUExecutionProvider"])

    def __call__(self, ventana):
        return self.sesion.run(None, {"audio": ventana.astype(np.float32)[None]})[0].reshape(-1)


class Sherpa(Modelo):
    def __init__(self, nombre: str, carpeta: str, tipo: str, archivo: str):
        self.nombre, self.sr = nombre, 16000
        base = MODELOS / carpeta
        self.archivo = base / archivo
        etiquetas_csv = base / "class_labels_indices.csv"
        self.etiquetas = etiquetas_audioset(etiquetas_csv)
        if tipo == "ced":
            modelo = sherpa_onnx.AudioTaggingModelConfig(ced=str(self.archivo), num_threads=1, provider="cpu")
        else:
            modelo = sherpa_onnx.AudioTaggingModelConfig(
                zipformer=sherpa_onnx.OfflineZipformerAudioTaggingModelConfig(model=str(self.archivo)),
                num_threads=1,
                provider="cpu",
            )
        self.tagger = sherpa_onnx.AudioTagging(
            sherpa_onnx.AudioTaggingConfig(model=modelo, labels=str(etiquetas_csv), top_k=len(self.etiquetas))
        )

    def __call__(self, ventana):
        stream = self.tagger.create_stream()
        stream.accept_waveform(sample_rate=self.sr, waveform=ventana.astype(np.float32))
        probs = np.zeros(len(self.etiquetas), np.float32)
        for evento in self.tagger.compute(stream, len(self.etiquetas)):
            probs[evento.index] = evento.prob
        return probs


def velocidad_ms(modelo: Modelo, repeticiones: int = 30) -> float:
    """Milisegundos por cada segundo de audio analizado."""
    ventana = (np.random.default_rng(0).standard_normal(int(modelo.sr * VENTANA_S)) * 0.1).astype(np.float32)
    for _ in range(3):
        modelo(ventana)
    tiempos = []
    for _ in range(repeticiones):
        t = time.perf_counter()
        modelo(ventana)
        tiempos.append((time.perf_counter() - t) * 1000 / VENTANA_S)
    return statistics.median(tiempos)


def db(ventana: np.ndarray) -> float:
    return 20 * np.log10(np.sqrt(np.mean(ventana**2)) + 1e-12)


def puntajes_del_clip(modelo: Modelo, audio: np.ndarray) -> np.ndarray:
    """Ventanas de VENTANA_S segundos que avanzan a la mitad; se queda el máximo de cada clase.

    Como en la app, una compuerta de nivel salta las ventanas en silencio. Los clips de ESC-50
    traen silencio digital absoluto al final, que un micrófono real nunca da, y con eso
    EfficientAT devuelve cualquier cosa.
    """
    largo = int(modelo.sr * VENTANA_S)
    ventanas = [audio[i : i + largo] for i in range(0, max(1, len(audio) - largo + 1), largo // 2)]
    con_sonido = [v for v in ventanas if db(v) > -50] or [max(ventanas, key=db)]
    return np.max([modelo(v) for v in con_sonido], axis=0)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--clips-por-clase", type=int, default=40)
    parser.add_argument("--ventana", type=float, default=1.0, help="segundos de audio por análisis")
    parser.add_argument("--salida", default="resultados.md")
    args = parser.parse_args()
    global VENTANA_S
    VENTANA_S = args.ventana

    meta = pd.read_csv(ESC50 / "meta" / "esc50.csv")
    meta = meta[meta.category.isin(CLASES)].groupby("category").head(args.clips_por_clase)

    modelos: list[Modelo] = [
        Yamnet(),
        Onnx("EfficientAT mn04", "efficientat_mn04.onnx"),
        Onnx("EfficientAT mn10", "efficientat_mn10.onnx"),
        Onnx("PANNs MobileNetV1", "panns_mobilenetv1.onnx"),
        Onnx("PANNs Cnn14", "panns_cnn14.onnx"),
        Sherpa("sherpa CED tiny int8", "sherpa-onnx-ced-tiny-audio-tagging-2024-04-19", "ced", "model.int8.onnx"),
        Sherpa("sherpa CED mini int8", "sherpa-onnx-ced-mini-audio-tagging-2024-04-19", "ced", "model.int8.onnx"),
        Sherpa("sherpa CED mini", "sherpa-onnx-ced-mini-audio-tagging-2024-04-19", "ced", "model.onnx"),
        Sherpa("sherpa Zipformer small int8", "sherpa-onnx-zipformer-small-audio-tagging-2024-04-15", "zipformer",
               "model.int8.onnx"),
    ]

    audios = {sr: {} for sr in {m.sr for m in modelos}}
    for archivo in meta.filename:
        for sr in audios:
            audios[sr][archivo], _ = librosa.load(ESC50 / "audio" / archivo, sr=sr, mono=True)

    filas, por_clase = [], []
    for modelo in modelos:
        faltan = {e for es in CLASES.values() for e in es} - set(modelo.etiquetas)
        objetivo = {c: [modelo.etiquetas.index(e) for e in es if e in modelo.etiquetas] for c, es in CLASES.items()}
        aciertos = {c: 0 for c in CLASES}
        t0 = time.perf_counter()
        for archivo, clase in zip(meta.filename, meta.category):
            puntajes = puntajes_del_clip(modelo, audios[modelo.sr][archivo])
            top5 = set(np.argsort(puntajes)[::-1][:5])
            aciertos[clase] += bool(top5 & set(objetivo[clase]))
        total = len(meta)
        filas.append({
            "modelo": modelo.nombre,
            "MB": round(modelo.archivo.stat().st_size / 1e6, 1),
            "ms por 1 s de audio": round(velocidad_ms(modelo), 1),
            "acierto top-5": f"{sum(aciertos.values()) / total:.0%}",
            "minutos de prueba": round((time.perf_counter() - t0) / 60, 1),
        })
        por_clase.append({"modelo": modelo.nombre, **{c: f"{a / (total / len(CLASES)):.0%}" for c, a in aciertos.items()}})
        if faltan:
            print(f"{modelo.nombre}: etiquetas que no tiene: {sorted(faltan)}")
        print(filas[-1], flush=True)

    resumen, detalle = pd.DataFrame(filas), pd.DataFrame(por_clase).set_index("modelo").T
    print("\n" + resumen.to_markdown(index=False) + "\n\n" + detalle.to_markdown())
    (AQUI / args.salida).write_text(
        f"# Resultados con ventanas de {VENTANA_S:g} s\n\nClips de ESC-50 por clase: {args.clips_por_clase}. "
        "CPU de escritorio, un hilo.\n\n"
        + resumen.to_markdown(index=False) + "\n\n## Acierto top-5 por clase\n\n" + detalle.to_markdown() + "\n"
    )


if __name__ == "__main__":
    main()
