import { describe, expect, test } from "bun:test";
import { atender, derivarVista, fecha, haceCuanto, hora, SILENCIO_SIN_SENAL_MS } from "./estado";
import { ESCENARIOS, simular } from "./simulado";
import type { DatosCasa } from "./tipos";

// Sábado 24-oct-2026, 14:07 en Caracas (18:07 UTC).
const AHORA = new Date("2026-10-24T18:07:00Z");

describe("horas en Caracas", () => {
  test("la hora se muestra en Caracas aunque el servidor esté en UTC", () => {
    expect(hora("2026-10-24T18:05:00Z")).toBe("14:05");
  });
  test("la fecha corta empieza en mayúscula y sin punto", () => {
    expect(fecha(AHORA)).toBe("Sáb 24 oct");
  });
  test("haceCuanto redondea hacia abajo", () => {
    expect(haceCuanto("2026-10-24T18:06:50Z", AHORA)).toBe("hace un momento");
    expect(haceCuanto("2026-10-24T18:05:59Z", AHORA)).toBe("hace 1 min");
    expect(haceCuanto("2026-10-24T15:00:00Z", AHORA)).toBe("hace 3 h");
  });
});

describe("derivarVista", () => {
  test("cada escenario simulado da su pantalla", () => {
    const tipos = ESCENARIOS.map((e) => derivarVista(simular(e, AHORA), AHORA).tipo);
    expect(tipos).toEqual(["bien", "alerta", "bien", "sin_senal"]);
  });

  test("la alerta urgente cuenta qué pasó y cuánto se esperó", () => {
    const vista = derivarVista(simular("alerta", AHORA), AHORA);
    if (vista.tipo !== "alerta") throw new Error(vista.tipo);
    expect(vista.titular).toBe("Un golpe fuerte en casa de Carmen");
    expect(vista.explicacion).toBe(
      "Oímos un golpe fuerte a las 14:05. Le preguntamos si estaba bien y no respondió en 60 segundos.",
    );
    expect(vista.hecho).toContain("Desde su casa llamamos a Josuep, su hijo");
  });

  test("el pánico no dice que se le preguntó: lo pidió ella", () => {
    const datos = simular("alerta", AHORA);
    datos.eventos = datos.eventos.map((e) => (e.id === "ev-golpe-fuerte" ? { ...e, tipo: "panico" } : e));
    const vista = derivarVista(datos, AHORA);
    if (vista.tipo !== "alerta") throw new Error(vista.tipo);
    expect(vista.titular).toBe("Carmen pidió ayuda");
    expect(vista.hecho).not.toContain("Le preguntamos en su casa si estaba bien");
  });

  test("la alerta urgente gana aunque la casa esté sin señal", () => {
    const datos = simular("alerta", AHORA);
    datos.casa.ultimoLatido = new Date(AHORA.getTime() - SILENCIO_SIN_SENAL_MS * 2).toISOString();
    expect(derivarVista(datos, AHORA).tipo).toBe("alerta");
  });

  test("una alerta atendida ya no es urgente", () => {
    const datos = simular("alerta", AHORA);
    datos.alertas = datos.alertas.map((a) => atender(a, AHORA, "Josuep"));
    expect(derivarVista(datos, AHORA).tipo).toBe("bien");
  });

  test("una alerta pendiente todavía no es urgente: la casa sigue preguntando", () => {
    const datos = simular("alerta", AHORA);
    datos.alertas = datos.alertas.map((a) => ({ ...a, estado: "pendiente" as const }));
    expect(derivarVista(datos, AHORA).tipo).toBe("bien");
  });

  test("sin señal justo después del límite, no antes", () => {
    const con = (silencioMs: number): DatosCasa => {
      const d = simular("todo-bien", AHORA);
      d.casa.ultimoLatido = new Date(AHORA.getTime() - silencioMs).toISOString();
      return d;
    };
    expect(derivarVista(con(SILENCIO_SIN_SENAL_MS), AHORA).tipo).toBe("bien");
    expect(derivarVista(con(SILENCIO_SIN_SENAL_MS + 1000), AHORA).tipo).toBe("sin_senal");
  });

  test("para saber junta la compra, la falsa alarma y el día distinto, lo más nuevo primero", () => {
    const vista = derivarVista(simular("para-saber", AHORA), AHORA);
    if (vista.tipo !== "bien") throw new Error(vista.tipo);
    expect(vista.paraSaber.map((a) => a.etiqueta)).toEqual(["HAY QUE COMPRAR", "FALSA ALARMA", "DÍA DISTINTO"]);
    expect(vista.paraSaber[1].detalle).toBe("No te molestamos: respondió en 8 segundos.");
  });

  test("su día solo trae lo de hoy, lo más nuevo primero", () => {
    const datos = simular("todo-bien", AHORA);
    datos.eventos.push({ id: "ayer", casaId: "demo", hora: "2026-10-23T22:00:00Z", tipo: "rutina", descripcion: "Ayer" });
    const vista = derivarVista(datos, AHORA);
    if (vista.tipo !== "bien") throw new Error(vista.tipo);
    expect(vista.dia.map((e) => e.id)).not.toContain("ayer");
    expect(vista.ultimo?.descripcion).toBe("Oímos agua corriendo");
    expect(hora(vista.dia.at(-1)!.hora)).toBe("07:12");
  });
});

describe("atender", () => {
  test("solo una alerta escalada se puede atender", () => {
    const [alerta] = simular("alerta", AHORA).alertas;
    const hecha = atender(alerta, AHORA, "Josuep");
    expect(hecha.estado).toBe("atendida");
    expect(hecha.atendidaPor).toBe("Josuep");
    expect(atender(hecha, AHORA, "Pedro").atendidaPor).toBe("Josuep");
  });
});
