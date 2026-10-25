"""Lo que hace la casa con lo que dice Vosk, copiado de la app para probarlo fuera del teléfono.

Las frases se leen de los mismos archivos de Dart (app/lib/dominio/), así que si el equipo cambia
el banco, el experimento usa el banco nuevo. La lógica es una copia de:

- `normalizar` (respuesta.dart), `textoConfiable` (datos/frases.dart),
- `ordenPorVoz` (comandos.dart) y `pedidoPorVoz` (pedidos.dart),
- `_actuar` (ui/controlador.dart): primero las órdenes, después los pedidos.
"""

import json
import re
from pathlib import Path

DOMINIO = Path(__file__).resolve().parents[2] / "app" / "lib" / "dominio"
CONFIANZA_MINIMA = 0.5  # datos/frases.dart


def _fuente(nombre: str) -> str:
    # Sin comentarios de línea: algunos traen palabras que no son frases.
    texto = (DOMINIO / nombre).read_text()
    return "\n".join(l for l in texto.splitlines() if not l.strip().startswith("//"))


def _cadenas(bloque: str) -> list[str]:
    return re.findall(r"'([^']*)'", bloque)


def _lista(fuente: str, nombre: str) -> list[str]:
    m = re.search(rf"const {nombre}\s*=\s*[\[{{](.*?)[\]}}];", fuente, re.S)
    if not m:
        raise SystemExit(f"No encontré {nombre} en el código de la app")
    return _cadenas(m.group(1))


def _mapa(fuente: str, nombre: str, enum: str) -> dict[str, list[str]]:
    m = re.search(rf"{nombre}\s*=\s*<.+?>\{{(.*?)\n\}};", fuente, re.S)
    if not m:
        raise SystemExit(f"No encontré {nombre} en el código de la app")
    return {
        clave: _cadenas(cuerpo)
        for clave, cuerpo in re.findall(rf"{enum}\.(\w+):\s*\[(.*?)\]", m.group(1), re.S)
    }


_pedidos = _fuente("pedidos.dart")
_comandos = _fuente("comandos.dart")

BANCO = _mapa(_pedidos, "bancoDePedidos", "TipoEvento")
NOMBRE = re.search(r"nombreDeLaCasa\s*=\s*'([^']+)'", _comandos).group(1)
LLAMAR = _lista(_comandos, "_llamar")
DESTINOS = _mapa(_comandos, "_destinos", "Orden")
PALABRAS_DE_CANCELAR = set(_lista(_comandos, "_palabrasDeCancelar"))
CANCELAR = _lista(_comandos, "_cancelar")
YA_ME_LA_TOME = _lista(_comandos, "_yaMeLaTome")
ESTOY_BIEN = _lista(_comandos, "_estoyBien")

FRASES_DE_ORDENES = [
    *(f"{NOMBRE.lower()} {l} {d}" for destinos in DESTINOS.values() for d in destinos for l in LLAMAR),
    *CANCELAR,
    *YA_ME_LA_TOME,
    *(f"{NOMBRE.lower()} {f}" for f in ESTOY_BIEN),
]
# datos/frases.dart: [...todasLasFrases, ...frasesDeOrdenes, '[unk]']
GRAMATICA = [*(f for frases in BANCO.values() for f in frases), *FRASES_DE_ORDENES, "[unk]"]

_TILDES = str.maketrans("áéíóúü", "aeiouu")


def normalizar(texto: str) -> list[str]:
    limpio = re.sub(r"[^a-zñ ]", " ", texto.lower().translate(_TILDES))
    return limpio.split()


def texto_confiable(resultado: str, umbral: float = CONFIANZA_MINIMA) -> str:
    palabras = json.loads(resultado).get("result") or []
    return " ".join(p["word"] for p in palabras if p.get("conf", 0) >= umbral and p["word"] != "[unk]")


def _frase(f: str) -> str:
    return " " + " ".join(normalizar(f)) + " "


def orden_por_voz(versiones: list[str]) -> str | None:
    nombre = " ".join(normalizar(NOMBRE))
    for version in versiones:
        texto = _frase(version)
        en_nombre = texto.find(f" {nombre} ")
        if en_nombre >= 0:
            despues = " " + texto[en_nombre + len(nombre) + 2 :]
            if any(_frase(f) in despues for f in ESTOY_BIEN):
                return "estoyBien"
            for orden, destinos in DESTINOS.items():
                for l in LLAMAR:
                    if any(f" {l}{_frase(d)}" in despues for d in destinos):
                        return orden
        if any(_frase(f) in texto for f in YA_ME_LA_TOME):
            return "yaMeLaTome"
        palabras = normalizar(version)
        if palabras and all(p in PALABRAS_DE_CANCELAR for p in palabras):
            return "cancelar"
    return None


def pedido_por_voz(versiones: list[str]) -> str | None:
    for version in versiones:
        texto = _frase(version)
        for tipo, frases in BANCO.items():
            if any(_frase(f) in texto for f in frases):
                return tipo
    return None


def actuar(versiones: list[str]) -> str | None:
    """Lo que la casa haría: «orden:llamarHijo», «pedido:panico» o None."""
    if orden := orden_por_voz(versiones):
        return f"orden:{orden}"
    if pedido := pedido_por_voz(versiones):
        return f"pedido:{pedido}"
    return None


if __name__ == "__main__":
    # Los mismos casos que cuentan los comentarios de la app.
    assert actuar(["lucero llama a mi hijo"]) == "orden:llamarHijo"
    assert actuar(["llama a mi hijo"]) == "pedido:panico"  # sin el nombre no es orden
    assert actuar(["lucero estoy bien"]) == "orden:estoyBien"
    assert actuar(["estoy bien"]) is None  # sin el nombre la TV no calla la alarma
    assert actuar(["no no llames"]) == "orden:cancelar"
    assert actuar(["no me puedo parar"]) == "pedido:meSientoMal"  # no cancela
    assert actuar(["ya me la tomé"]) == "orden:yaMeLaTome"
    assert actuar(["huele a gas"]) == "pedido:hueleGas"
    print(f"{sum(map(len, BANCO.values()))} pedidos en {len(BANCO)} tipos, "
          f"{len(FRASES_DE_ORDENES)} frases de órdenes, gramática de {len(GRAMATICA)}")
