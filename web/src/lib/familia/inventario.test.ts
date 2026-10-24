import { describe, expect, test } from "bun:test";
import { avisosDeCompra, derivarVista } from "./estado";
import { AVISO_DIAS, contar, contarTodo, cuandoSeAcaba, mensajeDeCompra, pedido, quedanTexto } from "./inventario";
import { simular } from "./simulado";
import type { Medicamento } from "./tipos";

// Sábado 24-oct-2026, 14:07 en Caracas (18:07 UTC), como en estado.test.ts.
const AHORA = new Date("2026-10-24T18:07:00Z");

const losartan = (quedan: number | null): Medicamento => ({
  id: "los",
  nombre: "Losartán",
  comerciales: ["Cozaar"],
  concentracion: "50 mg",
  quedan,
  tomas: [
    { clave: "losartan-noche", hora: "20:00", cantidad: 1 },
    { clave: "losartan-manana", hora: "08:00", cantidad: 1 },
  ],
  ultimaCompra: { fecha: "2026-10-04", porCaja: 30 },
});

const metformina = (quedan: number | null): Medicamento => ({
  id: "met",
  nombre: "Metformina",
  comerciales: [],
  concentracion: "500 mg",
  quedan,
  tomas: [{ clave: "metformina", hora: "14:00", cantidad: 1 }],
});

describe("contar", () => {
  test("9 de losartán, dos al día: se acaba el jueves a las 8 y hay que comprar", () => {
    const c = contar(losartan(9), AHORA);
    expect(c.porDia).toBe(2);
    // Sáb 20:00, y de domingo a miércoles dos por día: 1 + 8 = 9. El jueves 08:00 ya no hay.
    expect(c.seAcaba).toBe("2026-10-29T12:00:00.000Z");
    expect(c.dias).toBe(4);
    expect(c.comprarDesde).toBe("2026-10-22");
    expect(c.hayQueComprar).toBe(true);
    expect(c.faltanMes).toBe(51);
    expect(c.cajas).toBe(2);
  });

  test(`el aviso salta con menos de ${AVISO_DIAS} días, no con ${AVISO_DIAS} justos`, () => {
    expect(contar(losartan(15), AHORA).dias).toBe(7);
    expect(contar(losartan(15), AHORA).hayQueComprar).toBe(false);
    expect(contar(losartan(13), AHORA).dias).toBe(6);
    expect(contar(losartan(13), AHORA).hayQueComprar).toBe(true);
  });

  test("las tomas de hoy que ya pasaron no se descuentan", () => {
    // Son las 14:07: la de las 14:00 ya pasó. Con 1 alcanza para el domingo, no para el lunes.
    const c = contar(metformina(1), AHORA);
    expect(c.seAcaba).toBe("2026-10-26T18:00:00.000Z");
    expect(c.dias).toBe(1);
  });

  test("con 0 se acaba en la próxima toma, hoy mismo", () => {
    const c = contar(losartan(0), AHORA);
    expect(c.dias).toBe(0);
    expect(cuandoSeAcaba(c.seAcaba!, AHORA)).toBe("hoy");
  });

  test("media pastilla por toma", () => {
    const m = { ...metformina(1), tomas: [{ clave: "media", hora: "08:00", cantidad: 0.5 }] };
    expect(contar(m, AHORA).seAcaba).toBe("2026-10-27T12:00:00.000Z");
  });

  test("si no se sabe cuántas quedan, no hay fecha ni aviso", () => {
    const c = contar(losartan(null), AHORA);
    expect(c.dias).toBeNull();
    expect(c.hayQueComprar).toBe(false);
  });

  test("sin tomas no se gasta", () => {
    const c = contar({ ...losartan(3), tomas: [] }, AHORA);
    expect(c.dias).toBeNull();
    expect(c.hayQueComprar).toBe(false);
  });

  test("con más de un año alcanza de sobra", () => {
    const c = contar(metformina(5000), AHORA);
    expect(c.dias).toBe(Infinity);
    expect(c.hayQueComprar).toBe(false);
    expect(c.faltanMes).toBe(0);
  });

  test("sin saber de cuántas viene la caja, se sugieren pastillas", () => {
    const c = contar(metformina(3), AHORA);
    expect(c.cajas).toBeNull();
    expect(c.faltanMes).toBe(27);
  });
});

describe("qué comprar", () => {
  test("lo que se acaba primero va primero, y lo que no se sabe al final", () => {
    const orden = contarTodo([metformina(null), metformina(20), losartan(9)], AHORA).map((c) => c.quedan);
    expect(orden).toEqual([9, 20, null]);
  });

  test("el pedido trae solo lo que tiene aviso, para un mes", () => {
    expect(pedido([losartan(9), metformina(20)], AHORA)).toEqual([
      { nombre: "Losartán", concentracion: "50 mg", comerciales: ["Cozaar"], pastillas: 51, cajas: 2, porCaja: 30 },
    ]);
  });

  test("el mensaje para WhatsApp, o nada si no hay que comprar", () => {
    expect(mensajeDeCompra("Carmen", [losartan(9), metformina(20)], AHORA)).toBe(
      "Hay que comprar pastillas para Carmen:\n" +
        "• Losartán 50 mg: quedan 9 pastillas, alcanza hasta el jue 29 oct. Para un mes: 2 cajas de 30.",
    );
    expect(mensajeDeCompra("Carmen", [metformina(20)], AHORA)).toBeNull();
  });

  test("quedan, en singular y en cero", () => {
    expect(quedanTexto(1)).toBe("Queda 1 pastilla");
    expect(quedanTexto(0)).toBe("No quedan pastillas");
    expect(quedanTexto(4.5)).toBe("Quedan 4,5 pastillas");
  });
});

describe("el aviso en /f/[token]", () => {
  test("dice cuántas quedan, cuándo se acaban y qué comprar", () => {
    expect(avisosDeCompra([losartan(9)], AHORA)).toEqual([
      {
        hora: "",
        etiqueta: "HAY QUE COMPRAR",
        titulo: "Quedan 9 pastillas de Losartán 50 mg",
        detalle: "Se acaban el jue 29 oct, en la toma de las 08:00. Para un mes: 2 cajas de 30.",
        enlace: "pastillas",
      },
    ]);
  });

  test("en el escenario «para saber», comprar va antes que lo demás", () => {
    const vista = derivarVista(simular("para-saber", AHORA), AHORA);
    if (vista.tipo !== "bien") throw new Error(vista.tipo);
    expect(vista.paraSaber[0].etiqueta).toBe("HAY QUE COMPRAR");
  });

  test("con pastillas de sobra no hay aviso", () => {
    const vista = derivarVista(simular("todo-bien", AHORA), AHORA);
    if (vista.tipo !== "bien") throw new Error(vista.tipo);
    expect(vista.paraSaber).toEqual([]);
  });
});
