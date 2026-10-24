// Webhook de Kapso: recibe los mensajes de WhatsApp de la familia y los suscribe a la casa.
//
// Flujo:
//   1. La familia toca el botón de bienvenida → se abre wa.me con el mensaje listo.
//   2. El mensaje llega a Kapso → Kapso hace POST aquí.
//   3. Se valida la firma HMAC-SHA256 con `KAPSO_WEBHOOK_SECRET`.
//   4. Se extrae el token del mensaje (`(casa <token>)`) y el teléfono del emisor.
//   5. Se llama a `public.familia_suscribir` con la llave secreta del servidor.
//
// Para que esto funcione, hay que registrar esta URL en el dashboard de Kapso con el evento
// `whatsapp.message.received`. Kapso reintenta si no respondemos 200, así que respondemos
// 200 siempre que la firma sea válida, aunque el mensaje no encaje.
//
// Hay que responder en menos de 10 s (límite de Kapso); por eso no hacemos nada costoso
// antes de responder.

import { createHmac, timingSafeEqual } from "node:crypto";
import { NextResponse } from "next/server";


// Regex tolerante: acepta "Quiero cuidar a Carmen (casa demo)" y variantes con espacios o
// mayúsculas en "casa". El token puede tener letras, números, guiones y guiones bajos.
const REGEX_TOKEN = /\(casa\s+([A-Za-z0-9_-]+)\)/i;

/**
 * Verifica la firma HMAC-SHA256 en hex. Compara en tiempo constante sobre buffers del mismo
 * largo; si el largo difiere, devuelve false sin revelar nada (el largo de un HMAC-SHA256
 * hex siempre es 64, así que la diferencia de largo ya indica que la firma es inválida).
 */
function firmaValida(cuerpo: string, firma: string, secreto: string): boolean {
  const esperada = createHmac("sha256", secreto).update(cuerpo).digest("hex");
  const bufFirma = Buffer.from(firma, "hex");
  const bufEsperada = Buffer.from(esperada, "hex");
  if (bufFirma.length !== bufEsperada.length) return false;
  return timingSafeEqual(bufFirma, bufEsperada);
}

/** Llama a `public.familia_suscribir` vía REST de Supabase con la llave de servicio. */
async function suscribir(token: string, telefono: string): Promise<boolean> {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const key = process.env.SUPABASE_SECRET_KEY;
  if (!url || !key) {
    console.error("[kapso/webhook] faltan NEXT_PUBLIC_SUPABASE_URL o SUPABASE_SECRET_KEY");
    return false;
  }
  try {
    const res = await fetch(`${url}/rest/v1/rpc/familia_suscribir`, {
      method: "POST",
      headers: {
        apikey: key,
        Authorization: `Bearer ${key}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ p_token: token, p_canal: "whatsapp", p_identificador: telefono }),
      cache: "no-store",
    });
    if (!res.ok) {
      console.error(`[kapso/webhook] familia_suscribir: ${res.status} ${await res.text()}`);
      return false;
    }
    const dato = (await res.json()) as unknown;
    return dato === true;
  } catch (err) {
    console.error("[kapso/webhook] error llamando a familia_suscribir", err);
    return false;
  }
}

export async function POST(req: Request): Promise<Response> {
  const secreto = process.env.KAPSO_WEBHOOK_SECRET;
  if (!secreto) {
    console.error("[kapso/webhook] falta KAPSO_WEBHOOK_SECRET");
    return NextResponse.json({ error: "webhook no configurado" }, { status: 500 });
  }

  const firma = req.headers.get("X-Webhook-Signature") ?? "";
  const cuerpo = await req.text();

  if (!firma || !firmaValida(cuerpo, firma, secreto)) {
    return NextResponse.json({ error: "firma inválida" }, { status: 401 });
  }

  // A partir de aquí la firma es válida: se procesa antes de responder aunque el mensaje no
  // encaje, para que Kapso no reintente. Se espera la promesa: en Vercel la función se congela
  // al devolver la respuesta y una promesa suelta se perdería antes de llegar a la base. Es una
  // sola consulta rápida, dentro de los 10 s que da Kapso.
  await procesarMensaje(cuerpo);
  return NextResponse.json({ ok: true });
}

/** Procesa el mensaje en background (no bloquea la respuesta). */
async function procesarMensaje(cuerpo: string): Promise<void> {
  let payload: {
    message?: { from?: string; text?: { body?: string } };
    conversation?: { phone_number?: string };
  };
  try {
    payload = JSON.parse(cuerpo) as typeof payload;
  } catch {
    return;
  }

  const texto = payload.message?.text?.body;
  if (!texto) return; // ignorar mensajes sin texto (audio, imagen, etc.)

  const telefono = payload.message?.from ?? payload.conversation?.phone_number;
  if (!telefono) return;

  const match = REGEX_TOKEN.exec(texto);
  if (!match) return;
  const token = match[1];

  await suscribir(token, telefono);
}
