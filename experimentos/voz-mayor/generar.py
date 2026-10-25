"""Genera con ElevenLabs las pruebas dichas por voces de personas mayores, y los ruidos de casa.

Todo queda en audio/ como PCM de 16 bits a 16 kHz, lo mismo que recibe Vosk en el teléfono. Lo
que ya existe no se vuelve a pedir, así que correrlo de nuevo no gasta créditos.

    uv run generar.py
"""

import hashlib
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

import elevenlabs as el
import pruebas

AUDIO = Path(__file__).parent / "audio"
MODELO = "eleven_multilingual_v2"

# De la biblioteca pública de ElevenLabs, filtrando español y edad «old». Acentos latinos (casi
# todas rioplatenses: no hay voces venezolanas mayores) y una española lenta, a propósito.
VOCES = {
    "titina": ("UOxKeHS7lixzgw35mtAR", "Grandma Titina, abuela, latinoamericana"),
    "nieve": ("nAFxIJGj7iSTeltygOfB", "Nieve, abuela argentina"),
    "tete": ("RTuKyXJgRGAQSx8Qz8Mf", "Tete, mujer mayor española, habla lento"),
    "charlie": ("Yb8JGzcZyW5YYzenhRCm", "El Abuelo Charlie, hombre mayor, latinoamericano"),
    "oslo": ("2lj4aExF052KSi14NJCI", "Oslo, abuelo, latinoamericano"),
    "arturo": ("N2HSRirbsHTZ8DE2WqjB", "Arturo Casares, hombre mayor, latinoamericano"),
}

RUIDOS = {
    "tv": "A television in a small living room playing a Latin American soap opera in Spanish: "
    "muffled dialogue between a man and a woman, soft dramatic music underneath",
    "calle": "Inside an apartment with the window open in a busy Latin American city: traffic, "
    "a motorcycle passing, distant voices, and an electric fan running nearby",
}


def nombre_de(texto: str) -> str:
    return hashlib.sha1(texto.encode()).hexdigest()[:12]


def voz_en_la_cuenta(voz_id: str) -> None:
    # Una voz de la biblioteca hay que agregarla a la cuenta antes de usarla por la API.
    mias = {v["voice_id"] for v in el.json_de("/v1/voices")["voices"]}
    if voz_id in mias:
        return
    publicas = [
        v
        for genero in ("female", "male")
        for v in el.json_de(
            "/v1/shared-voices",
            consulta={"page_size": 100, "language": "es", "age": "old", "gender": genero},
        )["voices"]
    ]
    dueno = next(v["public_owner_id"] for v in publicas if v["voice_id"] == voz_id)
    el.pedir(f"/v1/voices/add/{dueno}/{voz_id}", datos={"new_name": f"experimento {voz_id[:6]}"})


def decir(voz_id: str, texto: str, destino: Path) -> None:
    if destino.exists():
        return
    pcm = el.pedir(
        f"/v1/text-to-speech/{voz_id}",
        datos={"text": texto, "model_id": MODELO, "language_code": "es"},
        consulta={"output_format": "pcm_16000"},
    )
    destino.write_bytes(pcm)


def ruido(nombre: str, descripcion: str) -> None:
    destino = AUDIO / "ruido" / f"{nombre}.pcm"
    if destino.exists():
        return
    destino.parent.mkdir(parents=True, exist_ok=True)
    mp3 = el.pedir("/v1/sound-generation", datos={"text": descripcion, "duration_seconds": 20})
    subprocess.run(
        ["ffmpeg", "-loglevel", "error", "-y", "-i", "pipe:0", "-ac", "1", "-ar", "16000", "-f", "s16le", str(destino)],
        input=mp3,
        check=True,
    )


def main() -> None:
    lista = pruebas.todas()
    for nombre, descripcion in RUIDOS.items():
        ruido(nombre, descripcion)
    trabajos = []
    for clave, (voz_id, _) in VOCES.items():
        voz_en_la_cuenta(voz_id)
        carpeta = AUDIO / clave
        carpeta.mkdir(parents=True, exist_ok=True)
        trabajos += [(voz_id, t, carpeta / f"{nombre_de(t)}.pcm") for _, t, _ in lista]
    pendientes = [t for t in trabajos if not t[2].exists()]
    print(f"{len(trabajos)} audios, faltan {len(pendientes)}", flush=True)
    # El plan Creator deja 5 pedidos a la vez.
    with ThreadPoolExecutor(4) as pool:
        for i, _ in enumerate(pool.map(lambda t: decir(*t), pendientes), 1):
            if i % 50 == 0:
                print(f"  {i}/{len(pendientes)}", flush=True)
    print("listo")


if __name__ == "__main__":
    sys.exit(main())
