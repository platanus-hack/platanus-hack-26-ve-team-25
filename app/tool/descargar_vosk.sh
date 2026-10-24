#!/usr/bin/env bash
# Baja el modelo chico de español de Vosk (Apache 2.0, alphacephei.com) a los assets de Android.
# No va en git: pesa ~40 MB. `make deps` lo corre si falta.
set -euo pipefail

MODELO=vosk-model-small-es-0.42
DESTINO="$(dirname "$0")/../android/app/src/main/assets/vosk-es"
[ -f "$DESTINO/uuid" ] && exit 0

TEMP=$(mktemp -d)
trap 'rm -rf "$TEMP"' EXIT
curl -fL --retry 3 -o "$TEMP/m.zip" "https://alphacephei.com/vosk/models/$MODELO.zip"
unzip -q "$TEMP/m.zip" -d "$TEMP"
rm -rf "$DESTINO" && mkdir -p "$(dirname "$DESTINO")"
mv "$TEMP/$MODELO" "$DESTINO"
# StorageService.unpack de Vosk copia el modelo a la memoria del teléfono solo si cambia este uuid.
echo "$MODELO" > "$DESTINO/uuid"
echo "Modelo de Vosk en $DESTINO"
