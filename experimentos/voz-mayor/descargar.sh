#!/usr/bin/env bash
# Baja el mismo modelo de Vosk que lleva la app (app/tool/descargar_vosk.sh). No va al repo.
set -euo pipefail
cd "$(dirname "$0")"
MODELO=vosk-model-small-es-0.42
mkdir -p modelos
if [ ! -d "modelos/$MODELO" ]; then
  curl -fL --retry 3 -o modelos/m.zip "https://alphacephei.com/vosk/models/$MODELO.zip"
  (cd modelos && unzip -q m.zip && rm m.zip)
fi
echo listo
