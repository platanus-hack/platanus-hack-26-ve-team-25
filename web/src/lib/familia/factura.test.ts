import { describe, expect, test } from "bun:test";
import { cruzar, FACTURA_DE_EJEMPLO, miligramos, normalizar, type RenglonLeido } from "./factura";
import type { Medicamento } from "./tipos";

const med = (id: string, nombre: string, concentracion: string, comerciales: string[] = []): Medicamento => ({
  id,
  nombre,
  comerciales,
  concentracion,
  quedan: null,
  tomas: [],
});

const RECIPE = [med("los", "Losartán", "50 mg", ["Cozaar"]), med("met", "Metformina", "500 mg", ["Glucophage"])];

const renglon = (r: Partial<RenglonLeido>): RenglonLeido => ({
  texto: "",
  nombre: "",
  principioActivo: null,
  concentracion: null,
  porCaja: null,
  cajas: 1,
  ...r,
});

describe("normalizar y miligramos", () => {
  test("sin acentos ni signos", () => {
    expect(normalizar("LOSARTÁN Potásico, 50MG.")).toBe("losartan potasico 50mg");
  });
  test("la concentración en mg, con coma decimal o en gramos", () => {
    expect(miligramos("50MG")).toBe(50);
    expect(miligramos("0,5 g")).toBe(500);
    expect(miligramos("x30 tab")).toBeNull();
  });
});

describe("cruzar con el récipe", () => {
  test("el nombre comercial basta: Cozaar es el losartán", () => {
    expect(cruzar(renglon({ texto: "COZAAR 50MG X30 TAB", nombre: "Cozaar" }), RECIPE)?.id).toBe("los");
  });

  test("el genérico con su sal también", () => {
    expect(cruzar(renglon({ texto: "LOSARTAN POTASICO 50 MG", principioActivo: "losartán" }), RECIPE)?.id).toBe("los");
  });

  test("otra concentración no es el mismo medicamento", () => {
    expect(cruzar(renglon({ texto: "LOSARTAN 100MG X30", principioActivo: "losartán", concentracion: "100 mg" }), RECIPE)).toBeNull();
  });

  test("lo que no está en el récipe no cruza", () => {
    expect(cruzar(renglon({ texto: "ACETAMINOFEN 500MG", principioActivo: "paracetamol" }), RECIPE)).toBeNull();
    expect(cruzar(renglon({ texto: "CREMA DENTAL 100ML" }), RECIPE)).toBeNull();
  });

  test("un pedazo de palabra no cuenta", () => {
    expect(cruzar(renglon({ texto: "METFORMINAX" }), RECIPE)).toBeNull();
  });

  test("si hay dos del mismo nombre y la factura no dice cuál, que elija la familia", () => {
    const dos = [...RECIPE, med("los100", "Losartán", "100 mg")];
    expect(cruzar(renglon({ texto: "LOSARTAN X30" }), dos)).toBeNull();
    expect(cruzar(renglon({ texto: "LOSARTAN 100MG X30" }), dos)?.id).toBe("los100");
  });

  test("la factura de ejemplo trae dos del récipe y dos que no", () => {
    expect(FACTURA_DE_EJEMPLO.renglones.map((r) => cruzar(r, RECIPE)?.id ?? null)).toEqual(["los", "met", null, null]);
  });
});
