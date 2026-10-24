// Webhook de Telegram: recibe los updates del bot y suscribe a los usuarios que abren el enlace
// de invitación con /start <token>.
//
// Flujo:
//   1. Telegram manda POST aquí con el update (message.chat.id, message.text).
//   2. Si TELEGRAM_WEBHOOK_SECRET está definido, se valida el header X-Telegram-Bot-Api-Secret-Token
//      (comparación en tiempo constante). Si no coincide → 401.
//   3. Si el texto empieza con /start y tiene payload (/start <token>), se llama a
//      familia_suscribir con p_canal="telegram" y p_identificador=chat.id.
//   4. Se responde al chat con un mensaje de confirmación o error.
//   5. Se devuelve 200 { ok: true } siempre que el secreto sea válido.
//
// Para activar el webhook, hay que ejecutar (una sola vez):
//   setWebhook
//     url: https://<dominio>/api/telegram/webhook
//     secret_token: <TELEGRAM_WEBHOOK_SECRET>
//     allowed_updates: ["message"]
//
// GET se usa para comprobar que la ruta existe (health check).

import { timingSafeEqual } from "node:crypto";
import { NextResponse } from "next/server";
import { enviarTexto } from "@/lib/telegram";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

/**
 * Verifica el secreto del webhook de Telegram. Si TELEGRAM_WEBHOOK_SECRET no está definido,
 * devuelve true (modo permisivo para desarrollo). Si está definido, compara en tiempo constante
 * el header X-Telegram-Bot-Api-Secret-Token con el secreto.
 */
function secretoValido(req: Request): boolean {
  const esperado = process.env.TELEGRAM_WEBHOOK_SECRET;
  if (!esperado) {
    console.warn("[telegram/webhook] TELEGRAM_WEBHOOK_SECRET no definido, modo permisivo");
    return true;
  }

  const recibido = req.headers.get("X-Telegram-Bot-Api-Secret-Token") ?? "";
  if (!recibido) return false;

  // Comparación en tiempo constante sobre buffers del mismo largo.
  const bufEsperado = Buffer.from(esperado, "utf-8");
  const bufRecibido = Buffer.from(recibido, "utf-8");
  if (bufEsperado.length !== bufRecibido.length) return false;
  return timingSafeEqual(bufEsperado, bufRecibido);
}

/** Llama a `public.familia_suscribir` vía REST de Supabase con la llave de servicio. */
async function suscribir(token: string, chatId: string): Promise<boolean> {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const key = process.env.SUPABASE_SECRET_KEY;
  if (!url || !key) {
    console.error("[telegram/webhook] faltan NEXT_PUBLIC_SUPABASE_URL o SUPABASE_SECRET_KEY");
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
      body: JSON.stringify({
        p_token: token,
        p_canal: "telegram",
        p_identificador: chatId,
      }),
      cache: "no-store",
    });
    if (!res.ok) {
      console.error(`[telegram/webhook] familia_suscribir: ${res.status} ${await res.text()}`);
      return false;
    }
    const dato = (await res.json()) as unknown;
    return dato === true;
  } catch (err) {
    console.error("[telegram/webhook] error llamando a familia_suscribir", err);
    return false;
  }
}

export async function POST(req: Request): Promise<Response> {
  if (!secretoValido(req)) {
    return NextResponse.json({ error: "secreto inválido" }, { status: 401 });
  }

  // A partir de aquí el secreto es válido: se procesa antes de responder.
  await procesarUpdate(req);
  return NextResponse.json({ ok: true });
}

/** Procesa el update de Telegram. */
async function procesarUpdate(req: Request): Promise<void> {
  let update: {
    message?: {
      chat?: { id?: number };
      text?: string;
    };
  };
  try {
    update = (await req.json()) as typeof update;
  } catch {
    return;
  }

  const chatId = update.message?.chat?.id;
  const texto = update.message?.text;
  if (!chatId || !texto) return;

  // Solo procesamos /start
  if (!texto.startsWith("/start")) return;

  const partes = texto.split(/\s+/);
  const payload = partes[1]; // El token después de /start

  if (payload) {
    // /start <token>: intentar suscribir
    const ok = await suscribir(payload, String(chatId));
    if (ok) {
      await enviarTexto(
        String(chatId),
        "Listo. Te avisamos por aquí si pasa algo en la casa.",
      );
    } else {
      await enviarTexto(
        String(chatId),
        "Ese enlace ya no vale. Pide uno nuevo.",
      );
    }
  } else {
    // /start sin payload: solo instrucciones
    await enviarTexto(
      String(chatId),
      "Para recibir los avisos, abre el enlace de invitación de la casa.",
    );
  }
}

/** Health check: confirma que la ruta existe. */
export async function GET(): Promise<Response> {
  return NextResponse.json({ ok: true, servicio: "telegram-webhook" });
}
