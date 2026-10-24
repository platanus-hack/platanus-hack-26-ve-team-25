// Vigilante: corre periódicamente (cron externo que llama este GET), escala las alertas
// vencidas y manda los WhatsApp pendientes.
//
// Autenticación: `Authorization: Bearer <CRON_SECRET>` o `?secreto=<CRON_SECRET>`. Si falta
// `CRON_SECRET` en el entorno o no coincide, responde 401.
//
// Flujo:
//   1. `public.escalar_vencidas()` — pasa `pendiente` → `escalada` las vencidas (atómico).
//   2. `public.avisos_pendientes()` — lee las escaladas sin `avisada_en` con sus teléfonos.
//   3. Por cada fila: arma el enlace, manda el WhatsApp, y si fue bien, sella `avisada_en`.
//
// Devuelve `{ escaladas, enviados, fallidos }` para que el cron pueda loguear.

import { NextResponse } from "next/server";
import { enviarTexto as enviarWhatsApp } from "@/lib/kapso";
import { enviarTexto as enviarTelegram } from "@/lib/telegram";
import { textoDeAlerta } from "@/lib/avisos";


type AlertaEscalada = {
  id: string;
  casa_id: string;
};

type AvisoPendiente = {
  alerta_id: string;
  casa_id: string;
  nombre: string;
  canal: string;
  identificador: string;
  token: string;
  nivel: string;
  descripcion: string;
  escalada_en: string;
};

/** Llama a una función RPC de Supabase con la llave de servicio. */
async function rpcSecret<T>(funcion: string, args: Record<string, unknown>): Promise<T> {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const key = process.env.SUPABASE_SECRET_KEY;
  if (!url || !key) {
    throw new Error(`[vigilar] faltan credenciales de Supabase para ${funcion}`);
  }
  const res = await fetch(`${url}/rest/v1/rpc/${funcion}`, {
    method: "POST",
    headers: {
      apikey: key,
      Authorization: `Bearer ${key}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(args),
    cache: "no-store",
  });
  if (!res.ok) {
    throw new Error(`${funcion}: ${res.status} ${await res.text()}`);
  }
  return (await res.json()) as T;
}

function autenticado(req: Request): boolean {
  const secreto = process.env.CRON_SECRET;
  if (!secreto) return false;

  const header = req.headers.get("authorization") ?? "";
  const bearer = header.startsWith("Bearer ") ? header.slice(7).trim() : "";
  if (bearer && bearer === secreto) return true;

  const qs = new URL(req.url).searchParams.get("secreto");
  return qs !== null && qs === secreto;
}

/** Base para armar enlaces: `NEXT_PUBLIC_URL_BASE` o el origen del request. */
function baseDelEnlace(req: Request): string {
  const env = process.env.NEXT_PUBLIC_URL_BASE;
  if (env) return env.replace(/\/+$/, "");
  const u = new URL(req.url);
  return `${u.protocol}//${u.host}`;
}

export async function GET(req: Request): Promise<Response> {
  if (!autenticado(req)) {
    return NextResponse.json({ error: "no autorizado" }, { status: 401 });
  }

  try {
    const escaladas = await rpcSecret<AlertaEscalada[]>(
      "escalar_vencidas",
      {}, // p_casa default null → todas las casas
    );
    const avisos = await rpcSecret<AvisoPendiente[]>("avisos_pendientes", {
      p_limite: 50,
    });

    const base = baseDelEnlace(req);
    let enviados = 0;
    let fallidos = 0;

    for (const aviso of avisos) {
      const enlace = `${base}/f/${aviso.token}`;
      const texto = textoDeAlerta({
        nombre: aviso.nombre,
        descripcion: aviso.descripcion,
        enlace,
      });
      
      // Despachar según el canal de suscripción
      const resultado =
        aviso.canal === "telegram"
          ? await enviarTelegram(aviso.identificador, texto)
          : aviso.canal === "whatsapp"
            ? await enviarWhatsApp(aviso.identificador, texto)
            : { ok: false as const, error: `canal desconocido: ${aviso.canal}` };
      
      if (resultado.ok) {
        enviados++;
        // Se sella aunque haya varios destinatarios para la misma alerta: el primero que logre
        // enviar marca la fila; los demás siguen enviando (porque la fila ya estaba en
        // memoria) pero el `marcar_avisada` posterior será no-op. Ver comentario en la
        // migración sobre el sello por alerta y por destinatario.
        await rpcSecret<boolean>("marcar_avisada", {
          p_alerta: aviso.alerta_id,
          p_canal: aviso.canal,
          p_identificador: aviso.identificador,
        });
      } else {
        fallidos++;
        console.error(
          `[vigilar] falló envío ${aviso.canal} a ${aviso.identificador} para alerta ${aviso.alerta_id}: ${resultado.error}`,
        );
      }
    }

    return NextResponse.json({
      escaladas: escaladas.length,
      enviados,
      fallidos,
    });
  } catch (err) {
    const msg = err instanceof Error ? err.message : "error desconocido";
    console.error("[vigilar]", msg);
    return NextResponse.json({ error: msg }, { status: 500 });
  }
}
