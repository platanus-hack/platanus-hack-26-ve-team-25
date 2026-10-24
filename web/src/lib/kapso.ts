// Cliente mínimo de Kapso para mandar WhatsApp desde el servidor.
//
// Solo se usa desde rutas del servidor (webhook, vigilante): la llave `KAPSO_API_KEY` nunca
// debe exponerse al navegador. Si faltan las variables, `hayWhatsapp` es false y `enviarTexto`
// devuelve un error en vez de lanzar, para que el vigilante pueda seguir corriendo aunque
// WhatsApp esté apagado.
//
// Ventana de 24 h de Meta: texto libre solo funciona dentro de las 24 h que abre el primer
// mensaje del usuario. Fuera de esa ventana, Meta exige plantilla aprobada; este cliente NO
// implementa plantillas, así que si el usuario no respondió en 24 h el aviso falla con
// `error: "fuera de ventana de 24 h"` (o similar de la API).

const URL_KAPSO = "https://api.kapso.ai/meta/whatsapp/v24.0";

export const hayWhatsapp = Boolean(
  process.env.KAPSO_API_KEY && process.env.KAPSO_PHONE_NUMBER_ID,
);

/** Solo dígitos, con código de país. Quita lo que no sea número. */
function limpiarTelefono(tel: string): string {
  return tel.replace(/\D/g, "");
}

/**
 * Envía un texto por WhatsApp vía Kapso.
 * No lanza: devuelve `{ ok: false, error }` si falta configuración, si falla el fetch, si
 * Kapso responde con error, o si el timeout de 8 s se vence.
 */
export async function enviarTexto(
  telefono: string,
  texto: string,
): Promise<{ ok: true } | { ok: false; error: string }> {
  const apiKey = process.env.KAPSO_API_KEY;
  const phoneId = process.env.KAPSO_PHONE_NUMBER_ID;
  if (!apiKey || !phoneId) {
    return { ok: false, error: "sin credenciales de Kapso" };
  }

  const tel = limpiarTelefono(telefono);
  if (!tel) return { ok: false, error: "teléfono vacío" };

  const url = `${URL_KAPSO}/${phoneId}/messages`;
  try {
    const res = await fetch(url, {
      method: "POST",
      headers: {
        "X-API-Key": apiKey,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        messaging_product: "whatsapp",
        recipient_type: "individual",
        to: tel,
        type: "text",
        text: { body: texto },
      }),
      signal: AbortSignal.timeout(8000),
    });
    if (!res.ok) {
      const detalle = await res.text().catch(() => "");
      return { ok: false, error: `Kapso ${res.status}: ${detalle.slice(0, 200)}` };
    }
    return { ok: true };
  } catch (err) {
    const msg = err instanceof Error ? err.message : "error desconocido";
    return { ok: false, error: msg };
  }
}

/**
 * Arma el texto del aviso en español. Corto, con un solo emoji al inicio para que destaque
 * en la notificación sin saturar. Incluye el enlace al panel de la familia para que toquen
 * y vean el contexto.
 */
export function textoDeAlerta(datos: {
  nombre: string;
  descripcion: string;
  enlace: string;
}): string {
  return `🔴 ${datos.nombre}: ${datos.descripcion}\n${datos.enlace}`;
}
