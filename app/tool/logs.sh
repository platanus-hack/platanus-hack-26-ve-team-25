#!/usr/bin/env bash
# El log de la app de la casa en vivo, desde el teléfono conectado por adb. Muestra solo lo de la
# app (Dart, Kotlin, Vosk, la sirena) y los avisos de Android que la afectan: cierres, «no
# responde» (ANR) y muertes por memoria. Si la app se reinicia, se vuelve a enganchar sola.
# Una copia queda en app/build/logs/, para revisarla después. Uso: make logs
set -uo pipefail

PAQUETE=ve.equipo25.casa
DISPOSITIVO=${1:?falta el teléfono}
ADB=(adb -s "$DISPOSITIVO")
mkdir -p "$(dirname "$0")/../build/logs"
ARCHIVO="$(dirname "$0")/../build/logs/casa-$(date +%Y%m%d-%H%M%S).log"
echo "Log de $PAQUETE en $DISPOSITIVO · copia en ${ARCHIVO#*/app/} · Ctrl-C para salir"

# Lo que Android dice de la app aunque no venga de su proceso.
AVISOS="$PAQUETE|ANR in|FATAL EXCEPTION|lowmemorykiller|Process .*$PAQUETE.* has died|Force finishing"

while true; do
  PID=$("${ADB[@]}" shell pidof -s "$PAQUETE" 2>/dev/null | tr -d '\r')
  if [ -z "$PID" ]; then
    echo "$(date +%T) · la app no está corriendo; esperando…"
    until PID=$("${ADB[@]}" shell pidof -s "$PAQUETE" 2>/dev/null | tr -d '\r') && [ -n "$PID" ]; do
      "${ADB[@]}" get-state >/dev/null 2>&1 || { echo "$(date +%T) · se perdió el teléfono (adb)"; exit 1; }
      sleep 1
    done
  fi
  echo "$(date +%T) · app corriendo, pid $PID"
  # Lo del proceso de la app, más los avisos del sistema sobre ella. Termina si la app muere.
  "${ADB[@]}" logcat -v time -T 1 2>/dev/null \
    | grep --line-buffered -E "\( *$PID\)|$AVISOS" \
    | grep --line-buffered -v -E "ImeTracker|enqueueInputEvent|Choreographer.*pending vsync" \
    | tee -a "$ARCHIVO" &
  LECTOR=$!
  while "${ADB[@]}" shell kill -0 "$PID" 2>/dev/null && \
        [ "$("${ADB[@]}" shell pidof -s "$PAQUETE" 2>/dev/null | tr -d '\r')" = "$PID" ]; do
    sleep 2
  done
  kill "$LECTOR" 2>/dev/null
  echo "$(date +%T) · la app se cerró o se reinició (pid $PID)"
done
