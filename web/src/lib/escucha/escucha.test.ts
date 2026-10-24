import { describe, expect, test } from "bun:test";
import { Anillo } from "./anillo";
import { eventoDe, unirCategorias } from "./eventos";
import { Compuerta, LineaBase, rmsDb } from "./nivel";

describe("rmsDb", () => {
  test("una señal a plena escala da 0 dB", () => {
    expect(rmsDb(new Float32Array(100).fill(1))).toBeCloseTo(0, 5);
  });
  test("a la décima parte da -20 dB", () => {
    expect(rmsDb(new Float32Array(100).fill(0.1))).toBeCloseTo(-20, 5);
  });
  test("el silencio no da -Infinity", () => {
    expect(rmsDb(new Float32Array(100))).toBe(-100);
  });
});

describe("LineaBase", () => {
  test("un golpe aislado casi no mueve el fondo", () => {
    const base = new LineaBase();
    for (let i = 0; i < 200; i++) base.actualizar(-60);
    base.actualizar(-10);
    expect(base.actual).toBeLessThan(-59.8);
  });
  test("un ruido que se queda (la TV) termina subiendo el fondo", () => {
    const base = new LineaBase();
    for (let i = 0; i < 200; i++) base.actualizar(-60);
    for (let i = 0; i < 3000; i++) base.actualizar(-40);
    expect(base.actual).toBeGreaterThan(-42);
  });
});

describe("Compuerta", () => {
  test("se abre con un salto sobre el fondo y se cierra después del sostén", () => {
    const c = new Compuerta(15, 1000);
    expect(c.evaluar(-50, -60, 0)).toBe(false);
    expect(c.evaluar(-40, -60, 100)).toBe(true);
    expect(c.evaluar(-60, -60, 900)).toBe(true);
    expect(c.evaluar(-60, -60, 1200)).toBe(false);
  });
});

describe("Anillo", () => {
  test("devuelve las últimas muestras en orden aunque haya dado la vuelta", () => {
    const a = new Anillo(4);
    a.escribir(new Float32Array([1, 2, 3]));
    a.escribir(new Float32Array([4, 5, 6]));
    expect([...a.ultimas(3)]).toEqual([4, 5, 6]);
    expect([...a.ultimas(10)]).toEqual([3, 4, 5, 6]);
  });
  test("antes de llenarse devuelve solo lo que hay", () => {
    const a = new Anillo(10);
    a.escribir(new Float32Array([7, 8]));
    expect([...a.ultimas(5)]).toEqual([7, 8]);
  });
});

describe("eventos", () => {
  test("la alarma de humo es una alerta", () => {
    expect(eventoDe([{ categoryName: "Smoke detector, smoke alarm", score: 0.7 }])?.tipo).toBe("alarma");
  });
  test("debajo del umbral no hay evento", () => {
    expect(eventoDe([{ categoryName: "Glass", score: 0.1 }])).toBeNull();
  });
  test("las clases que no nos importan se ignoran", () => {
    expect(eventoDe([{ categoryName: "Music", score: 0.9 }])).toBeNull();
  });
  test("une trozos quedándose con el máximo por clase", () => {
    const u = unirCategorias([
      [{ categoryName: "Speech", score: 0.4 }],
      [{ categoryName: "Speech", score: 0.6 }, { categoryName: "Bang", score: 0.5 }],
    ]);
    expect(u).toEqual([
      { categoryName: "Speech", score: 0.6 },
      { categoryName: "Bang", score: 0.5 },
    ]);
  });
});
