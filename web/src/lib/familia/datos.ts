// De dónde salen los datos de una casa. Hoy solo existe la casa de demo, con datos simulados;
// cuando esté Supabase, aquí se busca el token y las pantallas no cambian.
import { esEscenario, simular, type Escenario } from "./simulado";
import type { DatosCasa } from "./tipos";

export const TOKEN_DEMO = "demo";

export function cargarCasa(token: string, escenario: unknown, ahora: Date): DatosCasa | null {
  if (token !== TOKEN_DEMO) return null;
  const e: Escenario = esEscenario(escenario) ? escenario : "todo-bien";
  return simular(e, ahora);
}
