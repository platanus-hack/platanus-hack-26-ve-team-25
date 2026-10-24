// De dónde salen los datos de una casa. Con ?escenario= siempre son los simulados: así se
// construye, se prueba y se salva el pitch si falla la red. Si no, salen de Supabase. La casa de
// demo cae a los simulados si la base no responde, para que el QR del público nunca dé error.
import { esEscenario, simular } from "./simulado";
import { hayBaseDeDatos, leerCasa } from "./supabase";
import type { DatosCasa } from "./tipos";

export const TOKEN_DEMO = "demo";

export type Origen = "simulado" | "supabase";

export async function cargarCasa(
  token: string,
  escenario: unknown,
  ahora: Date,
): Promise<{ datos: DatosCasa; origen: Origen } | null> {
  if (esEscenario(escenario)) {
    return token === TOKEN_DEMO ? { datos: simular(escenario, ahora), origen: "simulado" } : null;
  }
  if (hayBaseDeDatos) {
    try {
      const datos = await leerCasa(token);
      if (datos) return { datos, origen: "supabase" };
    } catch (e) {
      console.error("No se pudo leer la casa de Supabase", e);
    }
  }
  return token === TOKEN_DEMO ? { datos: simular("todo-bien", ahora), origen: "simulado" } : null;
}
