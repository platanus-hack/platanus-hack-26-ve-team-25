// Prueba las funciones de supabase/migrations/ contra la base de verdad: el recorrido completo de
// una alerta y que los secretos no se crucen entre casas. Crea una casa de prueba y la borra al
// final. Se salta sola si no están las llaves (bun las lee de .env.local).
import { afterAll, beforeAll, describe, expect, test } from "bun:test";
import { derivarVista } from "./estado";
import type { DatosCasa } from "./tipos";

const URL_BASE = process.env.NEXT_PUBLIC_SUPABASE_URL;
const PUBLICA = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY;
const SECRETA = process.env.SUPABASE_SECRET_KEY;
const hayLlaves = Boolean(URL_BASE && PUBLICA && SECRETA);

async function rpc<T>(funcion: string, args: Record<string, unknown>, llave = PUBLICA!): Promise<T> {
  const res = await fetch(`${URL_BASE}/rest/v1/rpc/${funcion}`, {
    method: "POST",
    headers: { apikey: llave, "Content-Type": "application/json" },
    body: JSON.stringify(args),
  });
  if (!res.ok) throw new Error(`${funcion}: ${res.status} ${await res.text()}`);
  return res.json() as Promise<T>;
}

const esperar = (ms: number) => new Promise((r) => setTimeout(r, ms));

describe.skipIf(!hayLlaves)("Supabase: casa y familia", () => {
  let casa: { casaId: string; clave: string; token: string };
  let otra: { casaId: string; clave: string; token: string };

  beforeAll(async () => {
    const contactos = [{ nombre: "Prueba", relacion: "hijo", canal: "whatsapp", orden: 1 }];
    casa = await rpc("crear_casa", { p_nombre: "Prueba", p_contactos: contactos }, SECRETA);
    otra = await rpc("crear_casa", { p_nombre: "Otra" }, SECRETA);
  });

  afterAll(async () => {
    for (const c of [casa, otra].filter(Boolean)) {
      await fetch(`${URL_BASE}/rest/v1/casas?id=eq.${c.casaId}`, {
        method: "DELETE",
        headers: { apikey: SECRETA!, Authorization: `Bearer ${SECRETA}` },
      });
    }
  });

  test("la llave pública no lee las tablas ni da de alta casas", async () => {
    const res = await fetch(`${URL_BASE}/rest/v1/casas?select=*`, { headers: { apikey: PUBLICA! } });
    expect(res.ok ? await res.json() : []).toEqual([]);
    await expect(rpc("crear_casa", { p_nombre: "Intrusa" })).rejects.toThrow();
  });

  test("un token inventado no ve nada", async () => {
    expect(await rpc("familia_casa", { p_token: "no-existe" })).toBeNull();
    expect(await rpc("casa_latido", { p_clave: "no-existe", p_enchufado: true, p_bateria: 50 })).toBe(false);
  });

  test("la clave de una casa no escribe en otra", async () => {
    const evento = await rpc<string>("casa_evento", { p_clave: otra.clave, p_tipo: "golpe", p_descripcion: "x" });
    expect(await rpc("casa_alerta", { p_clave: casa.clave, p_evento: evento })).toBeNull();
  });

  test("recorrido: latido, evento, alerta que vence, escala, la familia la atiende", async () => {
    expect(await rpc("casa_latido", { p_clave: casa.clave, p_enchufado: true, p_bateria: 77 })).toBe(true);
    const evento = await rpc<string>("casa_evento", {
      p_clave: casa.clave,
      p_tipo: "alarma",
      p_descripcion: "Oímos una alarma de humo",
    });
    const alerta = await rpc<string>("casa_alerta", { p_clave: casa.clave, p_evento: evento, p_espera_s: 5 });

    let datos = await rpc<DatosCasa>("familia_casa", { p_token: casa.token });
    expect(datos.casa.bateria).toBe(77);
    expect(datos.alertas[0].estado).toBe("pendiente");
    expect(derivarVista(datos, new Date()).tipo).toBe("bien");

    await esperar(5500);
    datos = await rpc<DatosCasa>("familia_casa", { p_token: casa.token });
    expect(datos.alertas[0].estado).toBe("escalada");
    const vista = derivarVista(datos, new Date());
    expect(vista.tipo).toBe("alerta");
    if (vista.tipo === "alerta") expect(vista.titular).toBe("Alarma de humo en casa de Prueba");

    // La casa ya no puede cancelarla: «Estoy bien» llegó tarde.
    expect(await rpc("casa_responder", { p_clave: casa.clave, p_alerta: alerta, p_respuesta: "cancelar" })).toBe(
      "escalada",
    );
    expect(await rpc("familia_atender", { p_token: casa.token, p_alerta: alerta, p_quien: "Prueba" })).toBe(
      "atendida",
    );
    // El token de otra casa no la toca.
    expect(await rpc("familia_atender", { p_token: otra.token, p_alerta: alerta })).toBeNull();
  }, 15_000);

  test("«Estoy bien» a tiempo la cancela y queda como falsa alarma", async () => {
    const evento = await rpc<string>("casa_evento", { p_clave: casa.clave, p_tipo: "golpe", p_descripcion: "Oímos un golpe" });
    const alerta = await rpc<string>("casa_alerta", { p_clave: casa.clave, p_evento: evento });
    expect(await rpc("casa_responder", { p_clave: casa.clave, p_alerta: alerta, p_respuesta: "cancelar" })).toBe(
      "cancelada",
    );
    const datos = await rpc<DatosCasa>("familia_casa", { p_token: casa.token });
    const vista = derivarVista(datos, new Date());
    if (vista.tipo !== "bien") throw new Error(vista.tipo);
    expect(vista.paraSaber[0].etiqueta).toBe("FALSA ALARMA");
  });

  test("el pánico nace escalado, sin esperar", async () => {
    const evento = await rpc<string>("casa_evento", { p_clave: casa.clave, p_tipo: "panico", p_descripcion: "Pidió ayuda" });
    await rpc("casa_alerta", { p_clave: casa.clave, p_evento: evento, p_urgente: true });
    const vista = derivarVista(await rpc<DatosCasa>("familia_casa", { p_token: casa.token }), new Date());
    expect(vista.tipo).toBe("alerta");
  });
});
