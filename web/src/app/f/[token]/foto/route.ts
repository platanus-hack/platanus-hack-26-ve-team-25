// La última foto de la casa para la familia, si la hay: la que tomó el teléfono antes de llamar por
// una emergencia, con lo que Claude dice que se ve. Solo con el enlace de la familia, y la imagen va
// como un enlace firmado que vence en 10 minutos: el bucket nunca es público.
// `?desde=<ms>` pide solo las fotos tomadas desde que empezó la alerta que se está mirando.
import { type DatosDeFoto, nombreDeFoto, type RespuestaFoto, ultimaFoto } from "@/lib/fotos/escena";
import { bajarJson, casaDeToken, enlaceFirmado, listar } from "@/lib/fotos/storage";

const responder = (r: RespuestaFoto, status = 200) =>
  Response.json(r, { status, headers: { "Cache-Control": "no-store" } });

export async function GET(request: Request, ctx: RouteContext<"/f/[token]/foto">) {
  const { token } = await ctx.params;
  try {
    const casa = await casaDeToken(token);
    if (!casa) return responder({ foto: null }, 404);
    const desde = Number(new URL(request.url).searchParams.get("desde")) || 0;
    const ms = ultimaFoto(await listar(casa), Date.now(), desde);
    if (ms === null) return responder({ foto: null });
    const [datos, url] = await Promise.all([
      bajarJson<DatosDeFoto>(nombreDeFoto(casa, ms, "json")),
      enlaceFirmado(nombreDeFoto(casa, ms, "jpg")),
    ]);
    return responder({ foto: { ...datos, url } });
  } catch (e) {
    console.error("[familia/foto]", e);
    return responder({ foto: null }, 502);
  }
}
