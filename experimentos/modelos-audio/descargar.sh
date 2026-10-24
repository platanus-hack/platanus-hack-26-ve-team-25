#!/usr/bin/env bash
# Baja los modelos, el código de EfficientAT y PANNs, y el set ESC-50. No van al repo.
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p externos modelos datos

[ -d externos/EfficientAT ] || git clone -q --depth 1 https://github.com/fschmid56/EfficientAT externos/EfficientAT
[ -d externos/panns ] || git clone -q --depth 1 https://github.com/qiuqiangkong/audioset_tagging_cnn externos/panns

baja() { [ -s "$2" ] || curl -sfL -o "$2" "$1"; }
baja https://storage.googleapis.com/download.tensorflow.org/models/tflite/task_library/audio_classification/android/lite-model_yamnet_classification_tflite_1.tflite modelos/yamnet.tflite
baja https://raw.githubusercontent.com/tensorflow/models/master/research/audioset/yamnet/yamnet_class_map.csv modelos/yamnet_class_map.csv
baja "https://zenodo.org/record/3987831/files/MobileNetV1_mAP%3D0.389.pth?download=1" modelos/MobileNetV1.pth
baja "https://zenodo.org/record/3987831/files/Cnn14_mAP%3D0.431.pth?download=1" modelos/Cnn14.pth

# EfficientAT busca sus pesos en su propia carpeta resources/
mkdir -p externos/EfficientAT/resources
baja https://github.com/fschmid56/EfficientAT/releases/download/v0.0.1/mn04_as_mAP_432.pt externos/EfficientAT/resources/mn04_as_mAP_432.pt
baja https://github.com/fschmid56/EfficientAT/releases/download/v0.0.1/mn10_as_mAP_471.pt externos/EfficientAT/resources/mn10_as_mAP_471.pt

for m in sherpa-onnx-ced-tiny-audio-tagging-2024-04-19 sherpa-onnx-ced-mini-audio-tagging-2024-04-19 sherpa-onnx-zipformer-small-audio-tagging-2024-04-15; do
  [ -d "modelos/$m" ] || curl -sfL "https://github.com/k2-fsa/sherpa-onnx/releases/download/audio-tagging-models/$m.tar.bz2" | tar xj -C modelos
done

if [ ! -d datos/ESC-50-master ]; then
  curl -sfL -o datos/esc50.zip https://github.com/karoldvl/ESC-50/archive/master.zip
  (cd datos && unzip -q esc50.zip && rm esc50.zip)
fi
echo listo
