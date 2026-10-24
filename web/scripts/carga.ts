// Prueba de carga del pitch: N teléfonos escanean el QR en 5 s, abren /f/demo y leen la casa cada
// 5 s directo de Supabase, como hace vista-familia.tsx. Solo usa la llave pública y el token `demo`.
// Uso: cd web && bun --env-file=.env.local scripts/carga.ts [telefonos=50] [segundos=120] [web]
// Resultado del sábado 24-oct, desde la laptop en Caracas: docs/pendientes.md («Para el pitch»).
const URL_BASE = process.env.NEXT_PUBLIC_SUPABASE_URL;
const PUBLICA = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY;
if (!URL_BASE || !PUBLICA) throw new Error("Faltan NEXT_PUBLIC_SUPABASE_URL y NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY");

const [nArg, sArg, webArg] = process.argv.slice(2);
const N = Number(nArg ?? 50);
const DURACION_MS = Number(sArg ?? 120) * 1000;
const WEB = webArg ?? "https://platanus-hack-26-ve-team-25.vercel.app";
const LECTURA_MS = 5_000;
const ESCANEO_MS = 5_000;

const paginas: number[] = [];
const lecturas: number[] = [];
const fallas: Record<string, number> = {};
const falla = (k: string) => (fallas[k] = (fallas[k] ?? 0) + 1);
const dormir = (ms: number) => new Promise((r) => setTimeout(r, ms));

async function medir(pedir: () => Promise<Response>, destino: number[], tipo: string) {
  const t = performance.now();
  try {
    const res = await pedir();
    await res.arrayBuffer();
    if (!res.ok) return falla(`${tipo} ${res.status}`);
    destino.push(performance.now() - t);
  } catch (e) {
    falla(`${tipo} ${(e as Error).name}`);
  }
}

async function telefono() {
  await dormir(Math.random() * ESCANEO_MS);
  await medir(() => fetch(`${WEB}/f/demo`), paginas, "página");
  const fin = Date.now() + DURACION_MS;
  while (Date.now() < fin) {
    await dormir(LECTURA_MS);
    await medir(
      () =>
        fetch(`${URL_BASE}/rest/v1/rpc/familia_casa`, {
          method: "POST",
          headers: { apikey: PUBLICA!, "Content-Type": "application/json" },
          body: JSON.stringify({ p_token: "demo" }),
        }),
      lecturas,
      "lectura",
    );
  }
}

function resumen(nombre: string, xs: number[]) {
  const s = [...xs].sort((a, b) => a - b);
  const p = (q: number) => Math.round(s[Math.min(s.length - 1, Math.floor(q * s.length))] ?? 0);
  console.log(`${nombre}: ${s.length} ok · p50 ${p(0.5)} ms · p95 ${p(0.95)} ms · máx ${p(1)} ms`);
}

const t0 = Date.now();
await Promise.all(Array.from({ length: N }, telefono));
const seg = (Date.now() - t0) / 1000;
console.log(`${N} teléfonos durante ${seg.toFixed(0)} s (${(lecturas.length / seg).toFixed(1)} lecturas/s)`);
resumen("Abrir /f/demo", paginas);
resumen("Leer la casa", lecturas);
console.log("Fallas:", Object.keys(fallas).length ? fallas : "ninguna");
