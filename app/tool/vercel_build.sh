#!/usr/bin/env bash
# Arma la web de la casa en Vercel, que no trae Flutter: lo baja en la versión del equipo
# (la de .metadata) y compila. Se corre desde app/, como dice vercel.json.
# Sin config/local.json, a propósito: el número de emergencia no va en un sitio público.
set -euo pipefail

VERSION=3.47.5
SDK="$PWD/.flutter-sdk"

if [ ! -x "$SDK/bin/flutter" ]; then
  git clone --depth 1 --branch "$VERSION" https://github.com/flutter/flutter.git "$SDK"
fi
command -v unzip >/dev/null || dnf install -y unzip

export PATH="$SDK/bin:$PATH"
flutter config --no-analytics >/dev/null
flutter --version
flutter build web --release
