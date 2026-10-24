// Llamadas a las funciones de Supabase (supabase/migrations/). La web nunca toca las tablas: la
// llave pública solo puede ejecutar familia_casa y familia_atender, y cada una ve únicamente la
// casa del token. Un fetch alcanza; no hace falta el cliente completo de Supabase.
import type { DatosCasa, EstadoAlerta } from "./tipos";

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
