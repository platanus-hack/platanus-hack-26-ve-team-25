// Carga en la casa de demo (token «demo») el récipe inventado de Carmen: el mismo de
// app/lib/datos/simulado.dart, con las mismas claves de pastilla. Se puede correr las veces que sea:
// actualiza, no duplica. Cuántas quedan se carga después, con la factura de ejemplo en
// /f/demo/pastillas/factura o con «Las conté y son otras».
// Uso: cd web && bun --env-file=.env.local scripts/recipe-demo.ts
import { RECIPE_DEMO } from "../src/lib/familia/simulado";

const URL_BASE = process.env.NEXT_PUBLIC_SUPABASE_URL;
const PUBLICA = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY;
if (!URL_BASE || !PUBLICA) throw new Error("Faltan NEXT_PUBLIC_SUPABASE_URL y NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY");

for (const m of RECIPE_DEMO) {
  const res = await fetch(`${URL_BASE}/rest/v1/rpc/familia_recetar`, {
    method: "POST",
    headers: { apikey: PUBLICA, "Content-Type": "application/json" },
    body: JSON.stringify({
      p_token: "demo",
      p_nombre: m.nombre,
      p_concentracion: m.concentracion,
      p_comerciales: m.comerciales,
      p_tomas: m.tomas,
    }),
  });
  if (!res.ok) throw new Error(`${m.nombre}: ${res.status} ${await res.text()}`);
  console.log(`${m.nombre} ${m.concentracion}: ${await res.json()}`);
}
