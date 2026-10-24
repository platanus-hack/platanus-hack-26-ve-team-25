// Llamadas a las funciones de Supabase (supabase/migrations/). La web nunca toca las tablas: la
// llave pública solo puede ejecutar las funciones familia_* (y casa_*), y cada una ve únicamente
// la casa del token. Un fetch alcanza; no hace falta el cliente completo de Supabase.
import type { DatosCasa, EstadoAlerta, Toma } from "./tipos";

const URL_BASE = process.env.NEXT_PUBLIC_SUPABASE_URL;
const LLAVE = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY;

export const hayBaseDeDatos = Boolean(URL_BASE && LLAVE);

async function rpc<T>(funcion: string, args: Record<string, unknown>): Promise<T> {
  const res = await fetch(`${URL_BASE}/rest/v1/rpc/${funcion}`, {
    method: "POST",
    headers: { apikey: LLAVE!, "Content-Type": "application/json" },
    body: JSON.stringify(args),
    cache: "no-store",
  });
  if (!res.ok) throw new Error(`${funcion}: ${res.status} ${await res.text()}`);
  return res.json() as Promise<T>;
}

/** null si el token no existe o fue revocado. */
export function leerCasa(token: string): Promise<DatosCasa | null> {
  return rpc("familia_casa", { p_token: token });
}

export function atenderAlerta(token: string, alertaId: string, quien: string): Promise<EstadoAlerta | null> {
  return rpc("familia_atender", { p_token: token, p_alerta: alertaId, p_quien: quien });
}

/** Un renglón de factura ya confirmado por la familia, de un medicamento del récipe. */
export type RenglonCompra = { medicamentoId: string; texto: string; cajas: number; porCaja: number };

export type ResultadoCompra = { compra: string; repetida: boolean; guardados: number };

/** null si el token no existe o ningún renglón era del récipe. */
export function guardarCompra(
  token: string,
  renglones: RenglonCompra[],
  factura: { farmacia?: string | null; numero?: string | null; fecha?: string | null },
  quien = "la familia",
): Promise<ResultadoCompra | null> {
  return rpc("familia_comprar", {
    p_token: token,
    p_renglones: renglones,
    p_farmacia: factura.farmacia ?? null,
    p_numero: factura.numero ?? null,
    p_fecha: factura.fecha ?? null,
    p_quien: quien,
  });
}

/** «Conté y quedan 12». Devuelve cuántas quedan ahora, o null si no se pudo. */
export function ajustarPastillas(token: string, medicamentoId: string, quedan: number): Promise<number | null> {
  return rpc("familia_ajustar", { p_token: token, p_medicamento: medicamentoId, p_quedan: quedan });
}

/** Agrega o actualiza un medicamento del récipe. Lo usará la lectura del récipe por foto. */
export function recetar(
  token: string,
  m: { nombre: string; concentracion: string; comerciales: string[]; tomas: Toma[] },
): Promise<string | null> {
  return rpc("familia_recetar", {
    p_token: token,
    p_nombre: m.nombre,
    p_concentracion: m.concentracion,
    p_comerciales: m.comerciales,
    p_tomas: m.tomas,
  });
}
