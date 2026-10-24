// Prueba las funciones de supabase/migrations/20261024160000_pastillas_e_inventario.sql contra la
// base de verdad: el récipe, la factura confirmada, las tomas que descuentan y el conteo a mano.
// Crea dos casas de prueba y las borra al final. Se salta sola si no están las llaves. Correr con
// `bun run test:integracion`, que le pasa .env.local.
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

type Casa = { casaId: string; clave: string; token: string };
type Tomada = { medicamento: string; quedan: number | null } | null;

describe.skipIf(!hayLlaves)("Supabase: pastillas e inventario", () => {
  let casa: Casa;
  let otra: Casa;
  let losartan: string;
  let ajena: string;

  const inventario = async (token: string) => (await rpc<DatosCasa>("familia_casa", { p_token: token })).inventario!;

  beforeAll(async () => {
    casa = await rpc("crear_casa", { p_nombre: "Prueba pastillas" }, SECRETA);
    otra = await rpc("crear_casa", { p_nombre: "Otra" }, SECRETA);
    losartan = await rpc<string>("familia_recetar", {
      p_token: casa.token,
      p_nombre: "Losartán",
      p_concentracion: "50 mg",
      p_comerciales: ["Cozaar"],
      p_tomas: [
        { clave: "losartan-manana", hora: "08:00", cantidad: 1 },
        { clave: "losartan-noche", hora: "20:00", cantidad: 1 },
      ],
    });
    ajena = await rpc<string>("familia_recetar", {
      p_token: otra.token,
      p_nombre: "Metformina",
      p_concentracion: "500 mg",
      p_tomas: [{ clave: "metformina", hora: "14:00" }],
    });
  });

  afterAll(async () => {
    for (const c of [casa, otra].filter(Boolean)) {
      await fetch(`${URL_BASE}/rest/v1/casas?id=eq.${c.casaId}`, {
        method: "DELETE",
        headers: { apikey: SECRETA!, Authorization: `Bearer ${SECRETA}` },
      });
    }
  });

  test("la llave pública no lee las tablas nuevas", async () => {
    for (const tabla of ["medicamentos", "tomas", "compras", "compra_renglones", "movimientos"]) {
      const res = await fetch(`${URL_BASE}/rest/v1/${tabla}?select=*`, { headers: { apikey: PUBLICA! } });
      expect(res.ok ? await res.json() : []).toEqual([]);
    }
  });

  test("una clave o una pastilla que no existen no descuentan nada", async () => {
    expect(await rpc<Tomada>("casa_tomar", { p_clave: "no-existe", p_pastilla: "losartan-noche" })).toBeNull();
    expect(await rpc<Tomada>("casa_tomar", { p_clave: casa.clave, p_pastilla: "no-existe" })).toBeNull();
    // La pastilla de otra casa tampoco, aunque la clave sea válida.
    expect(await rpc<Tomada>("casa_tomar", { p_clave: casa.clave, p_pastilla: "metformina" })).toBeNull();
  });

  test("el récipe sale en familia_casa, sin saber todavía cuántas quedan", async () => {
    const [m] = await inventario(casa.token);
    expect(m).toMatchObject({ id: losartan, nombre: "Losartán", comerciales: ["Cozaar"], quedan: null });
    expect(m.tomas).toEqual([
      { clave: "losartan-manana", hora: "08:00", cantidad: 1 },
      { clave: "losartan-noche", hora: "20:00", cantidad: 1 },
    ]);
    // Antes de la primera factura, tomar no inventa un número.
    expect(await rpc<Tomada>("casa_tomar", { p_clave: casa.clave, p_pastilla: "losartan-manana" })).toEqual({
      medicamento: "Losartán",
      quedan: null,
    });
  });

  test("recorrido: factura confirmada, tomas que descuentan una vez al día, conteo y aviso", async () => {
    const factura = {
      p_token: casa.token,
      p_farmacia: "Farmacia de Prueba",
      p_numero: "P-0001",
      p_fecha: "2026-10-24",
      p_renglones: [
        { medicamentoId: losartan, texto: "COZAAR 50MG X30", cajas: 2, porCaja: 30 },
        // Un medicamento de otra casa no se guarda, aunque venga en el pedido.
        { medicamentoId: ajena, texto: "METFORMINA 500MG X30", cajas: 1, porCaja: 30 },
      ],
    };
    const compra = await rpc<{ compra: string; repetida: boolean; guardados: number }>("familia_comprar", factura);
    expect(compra).toMatchObject({ repetida: false, guardados: 1 });

    let [m] = await inventario(casa.token);
    expect(m.quedan).toBe(60);
    expect(m.ultimaCompra).toEqual({ fecha: "2026-10-24", porCaja: 30 });

    // La misma factura otra vez no suma.
    expect(await rpc("familia_comprar", factura)).toEqual({ compra: compra.compra, repetida: true, guardados: 0 });

    // «Ya me la tomé»: descuenta una, y si la cola de la casa la reenvía el mismo día, no otra.
    expect(await rpc<Tomada>("casa_tomar", { p_clave: casa.clave, p_pastilla: "losartan-noche" })).toEqual({
      medicamento: "Losartán",
      quedan: 59,
    });
    expect((await rpc<Tomada>("casa_tomar", { p_clave: casa.clave, p_pastilla: "losartan-noche" }))!.quedan).toBe(59);

    // «Las conté y son 9»: con dos al día no llega a una semana, y sale el aviso.
    expect(await rpc<number>("familia_ajustar", { p_token: casa.token, p_medicamento: losartan, p_quedan: 9 })).toBe(9);
    const datos = await rpc<DatosCasa>("familia_casa", { p_token: casa.token });
    [m] = datos.inventario!;
    expect(m.quedan).toBe(9);
    const vista = derivarVista(datos, new Date());
    if (vista.tipo !== "bien") throw new Error(vista.tipo);
    expect(vista.paraSaber[0]).toMatchObject({ etiqueta: "HAY QUE COMPRAR", titulo: "Quedan 9 pastillas de Losartán 50 mg" });
  });

  test("el token de otra casa no compra ni cuenta pastillas ajenas", async () => {
    const renglones = [{ medicamentoId: losartan, texto: "x", cajas: 1, porCaja: 30 }];
    expect(await rpc("familia_comprar", { p_token: otra.token, p_renglones: renglones })).toBeNull();
    expect(await rpc("familia_ajustar", { p_token: otra.token, p_medicamento: losartan, p_quedan: 100 })).toBeNull();
    expect(await rpc("familia_comprar", { p_token: "no-existe", p_renglones: renglones })).toBeNull();
    expect((await inventario(casa.token))[0].quedan).toBe(9);
  });
});
