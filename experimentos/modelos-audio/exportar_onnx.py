"""Exporta EfficientAT y PANNs de PyTorch a ONNX y verifica que den lo mismo.

Cada modelo se exporta con su espectrograma adentro: recibe audio crudo a 32 kHz, del largo que sea, y
devuelve las 527 probabilidades de AudioSet. Si el espectrograma no se puede exportar, se
exporta solo la red y se avisa.
"""

import contextlib
import importlib.util
import io
import os
import sys
from pathlib import Path

import numpy as np
import onnxruntime as ort
import torch

AQUI = Path(__file__).parent
MODELOS = AQUI / "modelos"
SR = 32000
torch.manual_seed(0)


class EfficientAT(torch.nn.Module):
    def __init__(self, nombre: str, ancho: float):
        super().__init__()
        # EfficientAT lee sus etiquetas y pesos con rutas relativas a su carpeta
        os.chdir(AQUI / "externos" / "EfficientAT")
        sys.path.insert(0, ".")
        from models.mn.model import get_model
        from models.preprocess import AugmentMelSTFT

        with contextlib.redirect_stdout(io.StringIO()):
            self.red = get_model(width_mult=ancho, pretrained_name=nombre, strides=[2, 2, 2, 2], head_type="mlp")
        self.mel = AugmentMelSTFT(n_mels=128, sr=SR, win_length=800, hopsize=320)

    def forward(self, audio):
        spec = self.mel(audio)
        logits, _ = self.red(spec.unsqueeze(1))
        return torch.sigmoid(logits)


class Panns(torch.nn.Module):
    def __init__(self, clase: str, pesos: str):
        super().__init__()
        carpeta = AQUI / "externos" / "panns" / "pytorch"
        sys.path.insert(0, str(carpeta))
        # Se carga con otro nombre porque EfficientAT también tiene un paquete «models»
        spec = importlib.util.spec_from_file_location("panns_models", carpeta / "models.py")
        models = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(models)

        self.red = getattr(models, clase)(
            sample_rate=SR, window_size=1024, hop_size=320, mel_bins=64, fmin=50, fmax=14000, classes_num=527
        )
        self.red.load_state_dict(torch.load(MODELOS / pesos, map_location="cpu", weights_only=False)["model"])

    def forward(self, audio):
        return self.red(audio)["clipwise_output"]


def exportar(nombre: str, modelo: torch.nn.Module):
    modelo.eval()
    destino = MODELOS / f"{nombre}.onnx"
    audio = torch.randn(1, SR) * 0.1
    with torch.no_grad():
        esperado = modelo(audio).numpy()
    try:
        torch.onnx.export(
            modelo, (audio,), destino, input_names=["audio"], output_names=["probs"], opset_version=17, dynamo=False,
            dynamic_axes={"audio": {1: "muestras"}},
        )
    except Exception as e:  # noqa: BLE001 — queremos el motivo, sea cual sea
        print(f"{nombre}: NO se pudo exportar: {type(e).__name__}: {str(e)[:300]}")
        return
    sesion = ort.InferenceSession(str(destino), providers=["CPUExecutionProvider"])
    obtenido = sesion.run(None, {"audio": audio.numpy()})[0]
    dif = float(np.abs(obtenido - esperado).max())
    top_pt, top_onnx = np.argsort(esperado[0])[::-1][:5], np.argsort(obtenido[0])[::-1][:5]
    print(
        f"{nombre}: exportado ({destino.stat().st_size / 1e6:.1f} MB), diferencia máxima {dif:.2e}, "
        f"top-5 igual: {list(top_pt) == list(top_onnx)}"
    )


if __name__ == "__main__":
    exportar("efficientat_mn04", EfficientAT("mn04_as", 0.4))
    exportar("efficientat_mn10", EfficientAT("mn10_as", 1.0))
    exportar("panns_mobilenetv1", Panns("MobileNetV1", "MobileNetV1.pth"))
    exportar("panns_cnn14", Panns("Cnn14", "Cnn14.pth"))
