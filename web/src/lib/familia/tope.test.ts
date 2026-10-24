import { describe, expect, test } from "bun:test";
import { crearTope } from "./tope";

const MIN = 60_000;

describe("crearTope", () => {
  test("deja pasar hasta el tope por minuto y frena el siguiente", () => {
    const puede = crearTope({ porMinuto: 3, porHora: 20 });
    expect([puede("demo", 0), puede("demo", 1), puede("demo", 2)]).toEqual([true, true, true]);
    expect(puede("demo", 3)).toBe(false);
  });

  test("al pasar el minuto vuelve a dejar pasar", () => {
    const puede = crearTope({ porMinuto: 1, porHora: 20 });
    expect(puede("demo", 0)).toBe(true);
    expect(puede("demo", MIN - 1)).toBe(false);
    expect(puede("demo", MIN)).toBe(true);
  });

  test("frena por hora aunque cada minuto esté bajo el tope", () => {
    const puede = crearTope({ porMinuto: 3, porHora: 4 });
    const usos = [0, 1, 2 * MIN, 2 * MIN + 1].map((t) => puede("demo", t));
    expect(usos).toEqual([true, true, true, true]);
    expect(puede("demo", 5 * MIN)).toBe(false);
    expect(puede("demo", 60 * MIN)).toBe(true);
  });

  test("los intentos frenados no cuentan como uso", () => {
    const puede = crearTope({ porMinuto: 1, porHora: 2 });
    expect(puede("demo", 0)).toBe(true);
    for (let i = 1; i < 10; i++) expect(puede("demo", i)).toBe(false);
    expect(puede("demo", MIN)).toBe(true);
  });

  test("cada casa tiene su propio tope", () => {
    const puede = crearTope({ porMinuto: 1, porHora: 20 });
    expect(puede("demo", 0)).toBe(true);
    expect(puede("demo", 1)).toBe(false);
    expect(puede("otra", 1)).toBe(true);
  });
});
