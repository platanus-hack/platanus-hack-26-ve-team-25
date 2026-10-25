"""Lo mínimo de la API de ElevenLabs que usa el experimento, sin dependencias.

La llave se toma de ELEVENLABS_API_KEY o, si no está, de web/.env.local (solo esa variable, y
nunca se imprime).
"""

import json
import os
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

API = "https://api.elevenlabs.io"
ENV = Path(__file__).resolve().parents[2] / "web" / ".env.local"


def llave() -> str:
    if k := os.environ.get("ELEVENLABS_API_KEY"):
        return k
    # Como lo lee el shell: gana la última línea, con o sin `export`, y sin el comentario del final.
    valor = None
    if ENV.exists():
        for linea in ENV.read_text().splitlines():
            nombre, _, resto = linea.strip().removeprefix("export ").partition("=")
            if nombre.strip() != "ELEVENLABS_API_KEY":
                continue
            resto = resto.strip()
            if resto[:1] in ("'", '"'):
                valor = resto[1:].split(resto[0], 1)[0]
            else:
                valor = resto.split(" #", 1)[0].strip()
    if valor:
        return valor
    raise SystemExit("Falta ELEVENLABS_API_KEY (en el entorno o en web/.env.local)")


def pedir(ruta: str, datos: dict | None = None, consulta: dict | None = None, intentos: int = 4) -> bytes:
    url = API + ruta + ("?" + urllib.parse.urlencode(consulta) if consulta else "")
    cuerpo = json.dumps(datos).encode() if datos is not None else None
    for intento in range(intentos):
        req = urllib.request.Request(url, data=cuerpo, method="POST" if cuerpo else "GET")
        req.add_header("xi-api-key", llave())
        if cuerpo:
            req.add_header("content-type", "application/json")
        try:
            with urllib.request.urlopen(req, timeout=120) as r:
                return r.read()
        except urllib.error.HTTPError as e:
            # 429: muchas a la vez para el plan. Se espera y se reintenta.
            if e.code == 429 and intento < intentos - 1:
                time.sleep(2 * (intento + 1))
                continue
            raise SystemExit(f"ElevenLabs {ruta}: {e.code} {e.read()[:300].decode(errors='replace')}")
    raise AssertionError("inalcanzable")


def json_de(ruta: str, **kw) -> dict:
    return json.loads(pedir(ruta, **kw))
