"""Pasa cada audio de generar.py por Vosk como lo hace la casa, y escribe resultados.md.

Por cada frase, voz y condición de ruido se prueban dos ventanas de audio:

- «app»: la de la casa (ui/controlador.dart). YAMNet marca que alguien habla (~1 s después de
  que empieza la frase), la casa espera 1,5 s (`finDeFrase`) y le pasa a Vosk los últimos 5 s
  (`audioDelPedido`). Si la voz sigue, vuelve a reconocer cada 4 s (`repetirPedido`).
- «completa»: la frase entera, para separar lo que falla Vosk de lo que corta la ventana.

    uv run evaluar.py
"""

import csv
import json
from collections import defaultdict
from multiprocessing import Pool
from pathlib import Path

import numpy as np
import vosk

import casa
import generar
import pruebas

SR = 16000
AQUI = Path(__file__).parent
MODELO = AQUI / "modelos" / "vosk-model-small-es-0.42"
CONDICIONES = {"limpio": None, "tv a 10 dB": ("tv", 10), "tv a 5 dB": ("tv", 5), "calle a 5 dB": ("calle", 5)}

DETECTA = 1.0  # cuánto tarda YAMNet en marcar que alguien habla (ventanas de 0,96 s cada 0,5 s)
FIN_DE_FRASE = 1.5
AUDIO_DEL_PEDIDO = 5.0
REPETIR = 4.0
ANTES, DESPUES = 3.0, 2.0  # silencio (o ruido) alrededor de la frase

_modelo = None
_gramatica = json.dumps(casa.GRAMATICA, ensure_ascii=False)
_ruidos: dict[str, np.ndarray] = {}


def _iniciar() -> None:
    global _modelo
    vosk.SetLogLevel(-1)
    _modelo = vosk.Model(str(MODELO))
    for nombre in generar.RUIDOS:
        _ruidos[nombre] = np.frombuffer((generar.AUDIO / "ruido" / f"{nombre}.pcm").read_bytes(), np.int16).astype(np.float32)


def _voz_activa(x: np.ndarray) -> tuple[int, int, float]:
    """Dónde empieza y termina la voz (en muestras) y su nivel RMS mientras suena."""
    marco = SR // 50
    n = len(x) // marco
    rms = np.sqrt((x[: n * marco].reshape(n, marco) ** 2).mean(axis=1) + 1e-9)
    activos = np.nonzero(rms > rms.max() * 0.05)[0]
    return activos[0] * marco, (activos[-1] + 1) * marco, float(np.sqrt((rms[activos] ** 2).mean()))


def _mezcla(voz: np.ndarray, condicion: str) -> tuple[np.ndarray, float, float]:
    inicio, fin, nivel = _voz_activa(voz)
    voz = voz[inicio:fin]
    senal = np.concatenate([np.zeros(int(ANTES * SR), np.float32), voz, np.zeros(int(DESPUES * SR), np.float32)])
    if (c := CONDICIONES[condicion]) is not None:
        nombre, snr = c
        ruido = np.resize(_ruidos[nombre], len(senal))
        ruido *= nivel / (np.sqrt((ruido**2).mean()) + 1e-9) / 10 ** (snr / 20)
        senal = senal + ruido
    # Sin saturar: si la suma pasa del máximo, se baja todo junto (a Vosk no le importa el volumen).
    if (pico := np.abs(senal).max()) > 32000:
        senal *= 32000 / pico
    return senal, ANTES, ANTES + len(voz) / SR


def _ventanas(empieza: float, termina: float, ventana: str) -> list[tuple[float, float]]:
    if ventana == "completa":
        return [(empieza - 0.5, termina + 0.5)]
    # La primera siempre: una frase corta («ayuda») también la marca YAMNet. Las siguientes, solo
    # si la voz sigue cuando vuelve a tocar.
    salida, t = [], empieza + DETECTA
    while True:
        fin = t + FIN_DE_FRASE
        salida.append((fin - AUDIO_DEL_PEDIDO, fin))
        t += REPETIR
        if t >= termina:
            return salida


UMBRALES = (0.3, 0.4, 0.5, 0.6)  # 0,5 es el de la app


def _reconocer(senal: np.ndarray, desde: float, hasta: float) -> str:
    trozo = senal[max(0, int(desde * SR)) : int(hasta * SR)].astype(np.int16).tobytes()
    r = vosk.KaldiRecognizer(_modelo, SR, _gramatica)
    r.SetWords(True)
    r.AcceptWaveform(trozo)
    return r.FinalResult()


def _probar(trabajo: tuple) -> list[dict]:
    voz, grupo, texto, esperado = trabajo
    audio = np.frombuffer((generar.AUDIO / voz / f"{generar.nombre_de(texto)}.pcm").read_bytes(), np.int16).astype(np.float32)
    filas = []
    for condicion in CONDICIONES:
        senal, empieza, termina = _mezcla(audio, condicion)
        for ventana in ("app", "completa"):
            crudos = [_reconocer(senal, d, h) for d, h in _ventanas(empieza, termina, ventana)]
            for umbral in UMBRALES:
                oido, obtenido = "", None
                # La casa actúa con lo primero que entiende.
                for crudo in crudos:
                    oido = casa.texto_confiable(crudo, umbral)
                    if oido and (obtenido := casa.actuar([oido])):
                        break
                filas.append(
                    dict(voz=voz, grupo=grupo, texto=texto, esperado=esperado or "", condicion=condicion,
                         ventana=ventana, umbral=umbral, segundos=round(termina - empieza, 2), oido=oido,
                         obtenido=obtenido or "", acierto=pruebas.acierta(esperado, obtenido))
                )
    return filas


def _pct(filas: list[dict]) -> str:
    return f"{100 * sum(f['acierto'] for f in filas) / len(filas):.0f} %" if filas else "—"


def _tabla(cabecera: list[str], filas: list[list[str]]) -> str:
    lineas = ["| " + " | ".join(cabecera) + " |", "|" + "---|" * len(cabecera)]
    return "\n".join(lineas + ["| " + " | ".join(f) + " |" for f in filas])


POSITIVOS = {"banco", "ordenes", "variantes"}
NEGATIVOS = {"casa": "Casa", "tv": "TV", "guion": "Guion"}
PRIVADOS = {"guion"}  # el guion del demo: su informe queda fuera del repo


def _umbrales(todas: list[dict]) -> str:
    frases_neg = {(f["voz"], f["texto"]) for f in todas if f["grupo"] not in POSITIVOS}
    cab = ["Confianza mínima", *(f"Entiende, {c}" for c in CONDICIONES), f"Falsos disparos (de {len(frases_neg)})"]
    tabla = []
    for u in UMBRALES:
        sel = [f for f in todas if f["umbral"] == u and f["ventana"] == "app"]
        pos = [f for f in sel if f["grupo"] in POSITIVOS]
        neg = [f for f in sel if f["grupo"] not in POSITIVOS]
        falsos = {(f["voz"], f["texto"]) for f in neg if not f["acierto"]}
        nombre = f"{u}" + (" (la de la app)" if u == casa.CONFIANZA_MINIMA else "")
        tabla.append([nombre, *(_pct([f for f in pos if f["condicion"] == c]) for c in CONDICIONES), str(len(falsos))])
    return (
        "\n\n## Si se cambia la confianza mínima\n\nCon la ventana de la app. Un falso disparo es una "
        "frase que no pide nada, dicha por una voz, que hace actuar a la casa en al menos una de las "
        "4 condiciones.\n\n"
        + _tabla(cab, tabla)
    )


def _informe(todas: list[dict]) -> str:
    filas = [f for f in todas if f["umbral"] == casa.CONFIANZA_MINIMA]
    pos = [f for f in filas if f["grupo"] in POSITIVOS]
    neg = [f for f in filas if f["grupo"] not in POSITIVOS]
    voces = sorted({f["voz"] for f in filas})
    partes = []

    partes.append("## Lo que la casa entiende\n\nPorcentaje de frases que dan lo esperado, por voz y condición.\n")
    cab = ["Condición", "Ventana", "Banco (71)", "Órdenes (28)", "Variantes (17)", "Todas"]
    tabla = []
    for c in CONDICIONES:
        for v in ("app", "completa"):
            sel = [f for f in pos if f["condicion"] == c and f["ventana"] == v]
            tabla.append([c, v, *(_pct([f for f in sel if f["grupo"] == g]) for g in ("banco", "ordenes", "variantes")), _pct(sel)])
    partes.append(_tabla(cab, tabla))

    partes.append("\n\n## Por voz (ventana de la app)\n")
    cab = ["Voz", *CONDICIONES]
    partes.append(_tabla(cab, [
        [f"{v} ({generar.VOCES[v][1]})", *(_pct([f for f in pos if f["voz"] == v and f["condicion"] == c and f["ventana"] == "app"]) for c in CONDICIONES)]
        for v in voces
    ]))

    partes.append("\n\n## Lo que no debe disparar nada\n\nFalsos disparos con la ventana de la app: frases dichas en una casa o en la TV que hacen actuar a la casa.\n")
    grupos = [g for g in NEGATIVOS if any(f["grupo"] == g for f in neg)]
    cab = ["Condición", *(f"{NEGATIVOS[g]} ({len({f['texto'] for f in neg if f['grupo'] == g})})" for g in grupos)]
    tabla = []
    for c in CONDICIONES:
        sel = [f for f in neg if f["condicion"] == c and f["ventana"] == "app"]
        tabla.append([c, *(f"{sum(not f['acierto'] for f in sel if f['grupo'] == g)} de {sum(f['grupo'] == g for f in sel)}" for g in grupos)])
    partes.append(_tabla(cab, tabla))
    disparos = defaultdict(list)
    for f in neg:
        if not f["acierto"] and f["ventana"] == "app":
            disparos[(f["grupo"], f["texto"])].append(f"{f['voz']}, {f['condicion']}: «{f['oido']}» → {f['obtenido']}")
    if disparos:
        partes.append("\n\nCuáles dispararon:\n")
        for (g, t), casos in sorted(disparos.items(), key=lambda kv: -len(kv[1])):
            partes.append(f"- **{g}** «{t}» ({len(casos)}): " + "; ".join(casos[:3]) + (" …" if len(casos) > 3 else ""))

    partes.append("\n\n## Las frases que más fallan\n\nCon la ventana de la app y sin ruido, entre las 6 voces.\n")
    por_frase = defaultdict(list)
    for f in pos:
        if f["condicion"] == "limpio" and f["ventana"] == "app":
            por_frase[(f["texto"], f["esperado"])].append(f)
    peores = sorted(por_frase.items(), key=lambda kv: sum(f["acierto"] for f in kv[1]))[:15]
    partes.append(_tabla(["Frase", "Esperado", "Aciertos", "Lo que se entendió (una voz)", "Dura"], [
        [t, e, f"{sum(f['acierto'] for f in fs)} de {len(fs)}",
         next((f"«{f['oido']}»" for f in fs if not f["acierto"]), "—"),
         f"{max(f['segundos'] for f in fs):.1f} s"]
        for (t, e), fs in peores
    ]))
    partes.append(_umbrales(todas))
    return "\n".join(partes) + "\n"


def main() -> None:
    lista = pruebas.todas()
    trabajos = [(v, g, t, e) for v in generar.VOCES for g, t, e in lista]
    with Pool(8, initializer=_iniciar) as pool:
        filas = [f for parte in pool.imap_unordered(_probar, trabajos, chunksize=8) for f in parte]
    if any(f["grupo"] in PRIVADOS for f in filas):
        (AQUI / "resultados-guion.md").write_text("# Resultados con el guion del demo (no va al repo)\n\n" + _informe(filas))
    filas = [f for f in filas if f["grupo"] not in PRIVADOS]
    # El CSV guarda solo la confianza de la app: el resto se recalcula corriendo esto de nuevo.
    de_la_app = [f for f in filas if f["umbral"] == casa.CONFIANZA_MINIMA]
    with open(AQUI / "resultados.csv", "w", newline="") as archivo:
        w = csv.DictWriter(archivo, fieldnames=list(de_la_app[0]))
        w.writeheader()
        w.writerows(sorted(de_la_app, key=lambda f: (f["voz"], f["grupo"], f["texto"], f["condicion"], f["ventana"])))
    (AQUI / "resultados.md").write_text("# Resultados\n\n" + _informe(filas))
    print((AQUI / "resultados.md").read_text())


if __name__ == "__main__":
    main()
