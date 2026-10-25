import { describe, expect, test } from "bun:test";
import {
  type DatosDeFoto,
  fotosVencidas,
  msDeFoto,
  nombreDeFoto,
  textoDeLaFoto,
  ultimaFoto,
  VIDA_DE_LA_FOTO_MS,
} from "./escena";

const CASA = "6046abad-109b-46a3-88b3-91738a0d7e94";
const T = 1_793_000_000_000; // domingo 25 de octubre de 2026

describe("nombres de las fotos", () => {
  test("ordenar por nombre es ordenar por hora, y se vuelve a leer la hora", () => {
    const viejo = nombreDeFoto(CASA, 999_999_999_999, "jpg");
    const nuevo = nombreDeFoto(CASA, T, "jpg");
    expect([nuevo, viejo].sort()).toEqual([viejo, nuevo]);
    expect(msDeFoto(nuevo)).toBe(T);
    expect(msDeFoto(`${CASA}/otra-cosa.png`)).toBeNull();
  });

  test("la última es la más nueva con descripción guardada, desde que empezó la alerta", () => {
    const nombres = [T - 60_000, T - 10_000, T].flatMap((ms) => [
      nombreDeFoto(CASA, ms, "jpg"),
      nombreDeFoto(CASA, ms, "json"),
    ]);
    expect(ultimaFoto(nombres, T + 1000)).toBe(T);
    // Una foto sin su .json todavía no se muestra.
    expect(ultimaFoto([nombreDeFoto(CASA, T, "jpg")], T + 1000)).toBeNull();
    // Las de antes de la alerta no son de esta alerta.
    expect(ultimaFoto(nombres.slice(0, 2), T + 1000, T - 30_000)).toBeNull();
  });

  test("a las 24 h la foto ya no se muestra y se borra", () => {
    const nombres = [nombreDeFoto(CASA, T, "jpg"), nombreDeFoto(CASA, T, "json")];
    const despues = T + VIDA_DE_LA_FOTO_MS;
    expect(ultimaFoto(nombres, despues - 1)).toBe(T);
    expect(ultimaFoto(nombres, despues)).toBeNull();
    expect(fotosVencidas(nombres, despues - 1)).toEqual([]);
    expect(fotosVencidas(nombres, despues)).toEqual(nombres);
  });
});

describe("el texto de Telegram", () => {
  const datos: DatosDeFoto = {
    motivo: "Nadie respondió a «¿Está bien?»: llamando a Josuep",
    hora: new Date(T).toISOString(),
    escena: null,
  };

  test("sin descripción sale igual, con la casa, la hora y el motivo", () => {
    const t = textoDeLaFoto("Carmen", datos, "3:42 p. m.");
    expect(t).toContain("Casa de Carmen · 3:42 p. m.");
    expect(t).toContain("llamando a Josuep");
    expect(t).not.toContain("Lo que se ve");
  });

  test("con descripción avisa de una persona en el suelo y del humo, y dice que es una IA", () => {
    const t = textoDeLaFoto(
      "Carmen",
      {
        ...datos,
        escena: {
          descripcion: "Una sala con poca luz. Una persona está tendida junto al sofá.",
          hayPersona: true,
          personaEnElSuelo: "si",
          humoOFuego: true,
        },
      },
      "3:42 p. m.",
    );
    expect(t).toContain("Lo que se ve: Una sala con poca luz.");
    expect(t).toContain("Parece que hay una persona en el suelo. Se ve humo o fuego.");
    expect(t).toContain("una IA");
  });

  test("nunca pasa de los 1024 caracteres que admite el pie de una foto", () => {
    const largo = { ...datos, motivo: "x".repeat(2000) };
    expect(textoDeLaFoto("Carmen", largo, "3:42").length).toBeLessThanOrEqual(1024);
  });
});
