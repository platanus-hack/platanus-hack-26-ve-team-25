"""Qué se le hace decir a cada voz y qué debería hacer la casa al oírlo.

Cada prueba es (grupo, texto, esperado). `esperado` es lo que devuelve casa.actuar, «pedido» a
secas cuando vale cualquier pedido (una frase que dice dos cosas abre la alerta igual), o None
cuando la casa no debe hacer nada.
"""

from pathlib import Path

import casa

# Como lo diría una persona mayor, sin calcar el banco: estas miden cuánto aguanta la gramática.
VARIANTES = [
    ("¡Ay, ayuda, ayuda!", "pedido"),
    ("Ayúdenme, por favor, que me caí.", "pedido"),
    ("Me caí y no me puedo levantar.", "pedido"),
    ("Ay, me siento malita.", "pedido"),
    ("Me duele mucho el pecho.", "pedido"),
    ("Socorro, auxilio.", "pedido"),
    ("No me puedo parar del piso.", "pedido"),
    ("Llamen a una ambulancia, rápido.", "pedido"),
    ("Me estoy ahogando.", "pedido"),
    ("Ay, Dios mío, ayuda.", "pedido"),
    ("Huele como a gas en la cocina.", "pedido:hueleGas"),
    ("Lucero, por favor, llama a mi hija.", "orden:llamarHijo"),
    ("Lucero, llámame a mi hijo.", "orden:llamarHijo"),
    ("Lucero, tranquila, estoy bien.", "orden:estoyBien"),
    ("Lucero, ya estoy bien, fue sin querer.", "orden:estoyBien"),
    ("Sí, ya me la tomé.", "orden:yaMeLaTome"),
    ("No, no llames.", "orden:cancelar"),
]

# Lo que se dice en una casa y no debe abrir «¿Está bien?».
CASA = [
    "Voy a hacer un cafecito.",
    "¿Dónde dejé los lentes?",
    "Qué calor está haciendo hoy.",
    "Mi hijo me llamó ayer desde Madrid.",
    "Esa novela está buenísima.",
    "Hoy hay que comprar pan y queso.",
    "Se fue la luz otra vez en el edificio.",
    "Ese perro no deja de ladrar.",
    "Mañana tengo cita con el doctor.",
    "Le voy a decir a mi hija que venga el domingo.",
    "Qué rico huele ese guiso.",
    "Estoy viendo el noticiero.",
    "Bueno, me voy a acostar un rato.",
    "La vecina me trajo unas arepas.",
    "No encuentro el control de la tele.",
]

TV = [
    "En el capítulo de hoy, Ricardo descubre la verdad.",
    "¡Te amo, María Fernanda, pero no puedo quedarme!",
    "Y ahora, el pronóstico del tiempo para Caracas.",
    "Compre ya y reciba un segundo producto gratis.",
    "El partido termina uno a cero.",
    "¡Doctor, el paciente se nos va!",
    "Señora, ¿usted está bien? ¿Quiere que llame a alguien?",
]

# Lo que dice quien presenta en el pitch, frase por frase: con la casa encendida en la tarima,
# ninguna debería abrir «¿Está bien?». Va en guion.txt, fuera del repo, porque es el guion del
# demo; sin ese archivo el grupo no se prueba.
_GUION = Path(__file__).parent / "guion.txt"
GUION = [l.strip() for l in _GUION.read_text().splitlines() if l.strip()] if _GUION.exists() else []


def todas() -> list[tuple[str, str, str | None]]:
    pruebas: list[tuple[str, str, str | None]] = []
    for tipo, frases in casa.BANCO.items():
        pruebas += [("banco", f, f"pedido:{tipo}") for f in frases]
    nombre = casa.NOMBRE
    for orden, destinos in casa.DESTINOS.items():
        pruebas += [("ordenes", f"{nombre}, llama {d}.", f"orden:{orden}") for d in destinos]
    pruebas += [("ordenes", f"{nombre}, {f}.", "orden:estoyBien") for f in casa.ESTOY_BIEN]
    pruebas += [("ordenes", f"{f.capitalize()}.", "orden:yaMeLaTome") for f in casa.YA_ME_LA_TOME]
    pruebas += [("ordenes", f"{f.capitalize()}.", "orden:cancelar") for f in ("no", "cancela", "no llames", "detente")]
    pruebas += [("variantes", t, e) for t, e in VARIANTES]
    pruebas += [("casa", t, None) for t in CASA]
    pruebas += [("tv", t, None) for t in TV]
    pruebas += [("guion", t, None) for t in GUION]
    return pruebas


def acierta(esperado: str | None, obtenido: str | None) -> bool:
    if esperado == "pedido":
        return bool(obtenido and obtenido.startswith("pedido:"))
    return esperado == obtenido


if __name__ == "__main__":
    from collections import Counter

    p = todas()
    print(len(p), "pruebas", dict(Counter(g for g, _, _ in p)), sum(len(t) for _, t, _ in p), "caracteres por voz")
    # Escrito, todo tiene que dar lo esperado, salvo las variantes que a propósito no están en
    # el banco («llámame», «huele como a gas»): esas miden lo que la gramática no cubre.
    for g, t, e in p:
        if not acierta(e, casa.actuar([t])):
            print(f"  {'(fuera del banco)' if g == 'variantes' else 'PRUEBA MAL HECHA'}: {t!r}")
