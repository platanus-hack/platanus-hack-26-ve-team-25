// Cliente mínimo de Telegram Bot API para mandar avisos desde el servidor.
//
// Mismo contrato que `kapso.ts` para que el vigilante pueda despachar por ambos canales sin
// distinguir la forma de enviar. Si falta `TELEGRAM_BOT_TOKEN`, `hayTelegram` es false y
// `enviarTexto` devuelve un error en vez de lanzar.
//
// Nota: Telegram no permite que el bot escriba primero al usuario; el usuario tiene que pulsar
// «Iniciar» (o abrir un /start con payload) al menos una vez antes de que el bot pueda mandar
// mensajes. Eso se maneja en el webhook de /api/telegram.

const URL_TELEGRAM_BASE = "https://api.telegram.org";

export const hayTelegram = Boolean(process.env.TELEGRAM_BOT_TOKEN);

/**
 * Envía un texto por Telegram vía la Bot API (sendMessage).
 * No lanza: devuelve `{ ok: false, error }` si falta configuración, si falla el fetch, si
 * Telegram responde con error, o si el timeout de 8 s se vence.
 */
export async function enviarTexto(
  chatId: string,
  texto: string,
): Promise<{ ok: true } | { ok: false; error: string }> {
  const token = process.env.TELEGRAM_BOT_TOKEN;
  if (!token) {
    return { ok: false, error: "sin TELEGRAM_BOT_TOKEN" };
  }

  const id = chatId.replace(/\D/g, "");
  if (!id) return { ok: false, error: "chat_id vacío" };

  const url = `${URL_TELEGRAM_BASE}/bot${token}/sendMessage`;
  try {
    const res = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        chat_id: id,
        text: texto,
        disable_web_page_preview: true,
      }),
      signal: AbortSignal.timeout(8000),
    });
    if (!res.ok) {
      const detalle = await res
        .json()
        .catch(() => null)
        .then((j) => {
          if (j && typeof j === "object" && "description" in j) {
            const d = (j as { description?: unknown }).description;
            if (typeof d === "string") return d;
          }
          return "";
        });
      const resumen = detalle || (await res.text().catch(() => ""));
      return { ok: false, error: `Telegram ${res.status}: ${resumen.slice(0, 200)}` };
    }
    return { ok: true };
  } catch (err) {
    const msg = err instanceof Error ? err.message : "error desconocido";
    return { ok: false, error: msg };
  }
}
