// Da de alta la casa de demo (Carmen) con el token público «demo», el del QR del pitch.
// Imprime la clave de la casa UNA vez: va en app/config/local.json del teléfono, nunca en el repo.
// Uso: cd web && bun scripts/crear-casa-demo.ts
const URL_BASE = process.env.NEXT_PUBLIC_SUPABASE_URL;
const SECRETA = process.env.SUPABASE_SECRET_KEY;
if (!URL_BASE || !SECRETA) throw new Error("Faltan NEXT_PUBLIC_SUPABASE_URL y SUPABASE_SECRET_KEY en .env.local");

const res = await fetch(`${URL_BASE}/rest/v1/rpc/crear_casa`, {
  method: "POST",
  headers: { apikey: SECRETA, "Content-Type": "application/json" },
  body: JSON.stringify({
    p_nombre: "Carmen",
    p_condiciones: ["oxigeno", "hipertension"],
    p_contactos: [
      { nombre: "Josuep", relacion: "hijo", canal: "whatsapp", orden: 1, donde: "En Caracas" },
      { nombre: "Pedro", relacion: "vecino", canal: "llamada", orden: 2, donde: "En Caracas" },
    ],
    // El token de demo es público a propósito: es el del QR. Las casas reales usan 128 bits de azar.
    p_token: "demo",
  }),
});
if (!res.ok) throw new Error(`${res.status} ${await res.text()}`);
const { casaId, clave } = (await res.json()) as { casaId: string; clave: string };
console.log(`Casa de demo creada: ${casaId}`);
console.log(`Clave de la casa (guárdala en app/config/local.json, no se vuelve a mostrar):\n${clave}`);

export {};
