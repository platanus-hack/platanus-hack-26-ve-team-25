"""Corre test/nube_integracion_test.dart contra la base de verdad con una casa de prueba.

Crea la casa con la llave secreta de web/.env.local, pasa su clave y su token a flutter test y la
borra al final, pase lo que pase. La casa de Carmen no se toca. Uso: make test-integracion
"""
import json
import pathlib
import subprocess
import sys
import urllib.request

APP = pathlib.Path(__file__).resolve().parent.parent
env = {}
for linea in (APP.parent / "web/.env.local").read_text().splitlines():
    if "=" in linea and not linea.lstrip().startswith("#"):
        k, v = linea.split("=", 1)
        env[k.strip()] = v.strip().strip("\"'")
url, publica, secreta = (env.get(k) for k in (
    "NEXT_PUBLIC_SUPABASE_URL", "NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY", "SUPABASE_SECRET_KEY"))
if not (url and publica and secreta):
    sys.exit("Faltan las llaves de Supabase en web/.env.local")


def pedir(ruta, metodo="POST", cuerpo=None):
    req = urllib.request.Request(
        f"{url}/rest/v1/{ruta}", method=metodo,
        data=json.dumps(cuerpo).encode() if cuerpo is not None else None,
        headers={"apikey": secreta, "Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=10) as r:
        cuerpo = r.read()
        return json.loads(cuerpo) if cuerpo else None


casa = pedir("rpc/crear_casa", cuerpo={"p_nombre": "Prueba de la app"})
try:
    codigo = subprocess.call([
        "flutter", "test", "test/nube_integracion_test.dart",
        f"--dart-define=SUPABASE_URL={url}",
        f"--dart-define=SUPABASE_PUBLISHABLE_KEY={publica}",
        f"--dart-define=PRUEBA_CLAVE={casa['clave']}",
        f"--dart-define=PRUEBA_TOKEN={casa['token']}",
    ], cwd=APP)
finally:
    pedir(f"casas?id=eq.{casa['casaId']}", metodo="DELETE")
sys.exit(codigo)
