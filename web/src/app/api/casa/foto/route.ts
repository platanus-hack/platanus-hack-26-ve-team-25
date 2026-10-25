// La foto que toma el teléfono de la casa justo antes de llamar por una emergencia (la alerta
// escaló, o se pidió emergencias). El teléfono manda el JPEG con su clave y recibe la respuesta
// apenas la foto queda guardada: no espera nada más. Después, con after(), Claude la describe y
// la foto sale por Telegram con su descripción a la familia suscrita.
//
// Autenticación: `Authorization: Bearer <clave de la casa>`. Cuerpo: el JPEG. `?motivo=` dice por
// qué se llamó («Nadie respondió: llamando a Josuep»).
import Anthropic from "@anthropic-ai/sdk";
import { betaZodOutputFormat } from "@anthropic-ai/sdk/helpers/beta/zod";
import { after } from "next/server";
import { hora } from "@/lib/familia/estado";
import { crearTope } from "@/lib/familia/tope";
import {
  type DatosDeFoto,
  Escena,
  fotosVencidas,
  MAX_BYTES_FOTO,
  nombreDeFoto,
  SISTEMA_ESCENA,
  textoDeLaFoto,
  TOPE_FOTOS,
} from "@/lib/fotos/escena";
import { borrar, casaDeClave, casaYSuscritos, listar, subir } from "@/lib/fotos/storage";
import { enviarFoto } from "@/lib/telegram";

const puedeSubir = crearTope(TOPE_FOTOS);

/** Claude tarda unos segundos; Telegram, otros. Todo corre después de responder. */
export const maxDuration = 60;

const error = (motivo: string, status: number) => Response.json({ error: motivo }, { status });

/** Lo que Claude ve en la foto, o null si no hay llave, se negó o falló: la foto sale igual. */
async function describir(jpg: Uint8Array): Promise<Escena | null> {
  if (!process.env.ANTHROPIC_API_KEY) return null;
  try {
    const client = new Anthropic({ timeout: 25_000 });
    const res = await client.beta.messages.parse({
      model: "claude-opus-5-5",
      max_tokens: 16000,
      // Si un clasificador rechaza la foto por error, la reintenta otro modelo en la misma llamada.
      betas: ["server-side-fallback-2026-07-01"],
      fallbacks: "default",
      system: SISTEMA_ESCENA,
      // Es una emergencia: la descripción tiene que llegar en segundos, no ser exhaustiva.
      output_config: { effort: "low", format: betaZodOutputFormat(Escena) },
      messages: [
        {
          role: "user",
          content: [
            {
              type: "image",
              source: { type: "base64", media_type: "image/jpeg", data: Buffer.from(jpg).toString("base64") },
            },
            { type: "text", text: "¿Qué se ve en la casa?" },
          ],
        },
      ],
    });
    if (res.stop_reason === "refusal") return null;
    return res.parsed_output ?? null;
  } catch (e) {
    if (e instanceof Anthropic.RateLimitError) console.error("[casa/foto] Claude: demasiadas", e.message);
    else if (e instanceof Anthropic.APIError) console.error(`[casa/foto] Claude: ${e.status}`, e.message);
    else console.error("[casa/foto] no se pudo describir", e);
    return null;
  }
}

export async function POST(request: Request) {
  const clave = (request.headers.get("authorization") ?? "").replace(/^Bearer\s+/i, "").trim();
  const casa = clave ? await casaDeClave(clave).catch(() => null) : null;
  if (!casa) return error("clave", 401);

  const jpg = new Uint8Array(await request.arrayBuffer());
  if (jpg.length > MAX_BYTES_FOTO) return error("muy_grande", 413);
  // Un JPEG empieza con FF D8.
  if (jpg.length < 4 || jpg[0] !== 0xff || jpg[1] !== 0xd8) return error("no_es_jpeg", 415);
  const ms = Date.now();
  if (!puedeSubir(casa, ms)) return error("demasiadas", 429);

  const motivo = (new URL(request.url).searchParams.get("motivo") ?? "").trim().slice(0, 200) || "La casa está llamando";
  const datos: DatosDeFoto = { motivo, hora: new Date(ms).toISOString(), escena: null };
  try {
    await subir(nombreDeFoto(casa, ms, "jpg"), jpg, "image/jpeg");
    await subir(nombreDeFoto(casa, ms, "json"), JSON.stringify(datos), "application/json");
  } catch (e) {
    console.error("[casa/foto] no se pudo guardar", e);
    return error("no_se_guardo", 502);
  }

  after(async () => {
    datos.escena = await describir(jpg);
    if (datos.escena) {
      await subir(nombreDeFoto(casa, ms, "json"), JSON.stringify(datos), "application/json").catch((e) =>
        console.error("[casa/foto] no se guardó la descripción", e),
      );
    }
    try {
      const { nombre, telegram } = await casaYSuscritos(casa);
      const pie = textoDeLaFoto(nombre, datos, hora(datos.hora));
      const envios = await Promise.all(telegram.map((chat) => enviarFoto(chat, jpg, pie)));
      for (const r of envios) if (!r.ok) console.error("[casa/foto] Telegram:", r.error);
    } catch (e) {
      console.error("[casa/foto] no se mandó por Telegram", e);
    }
    // Las fotos viven 24 h: después queda solo lo que ya se mandó.
    await listar(casa)
      .then((nombres) => borrar(fotosVencidas(nombres, Date.now())))
      .catch((e) => console.error("[casa/foto] no se borraron las viejas", e));
  });

  return Response.json({ ok: true }, { status: 201 });
}
