"use client";

// La foto que tomó el teléfono de la casa antes de llamar, dentro de la alerta roja. Se pide cada
// 5 s: la foto llega unos segundos después de escalar, y la descripción de Claude, otros más.
import { useEffect, useState } from "react";
import type { RespuestaFoto } from "@/lib/fotos/escena";

const CADA_MS = 5_000;

export function FotoDeLaCasa({ token, desde }: { token: string; desde: string }) {
  const [foto, setFoto] = useState<RespuestaFoto["foto"]>(null);

  useEffect(() => {
    let vivo = true;
    const desdeMs = new Date(desde).getTime();
    const leer = async () => {
      try {
        const r = await fetch(`/f/${encodeURIComponent(token)}/foto?desde=${desdeMs}`, { cache: "no-store" });
        if (!r.ok) return;
        const { foto: nueva } = (await r.json()) as RespuestaFoto;
        // El enlace firmado cambia en cada lectura: se cambia solo si cambió la foto o llegó la descripción.
        if (vivo && nueva) setFoto((f) => (f && f.hora === nueva.hora && f.escena ? f : nueva));
      } catch {
        // Sin red se reintenta en la próxima vuelta.
      }
    };
    void leer();
    const id = setInterval(leer, CADA_MS);
    return () => {
      vivo = false;
      clearInterval(id);
    };
  }, [token, desde]);

  if (!foto) return null;
  const e = foto.escena;
  return (
    <figure className="flex flex-col gap-2 overflow-hidden rounded-2xl bg-rojo-tarjeta pb-3.5">
      {/* El enlace firmado de Supabase vence en minutos: next/image lo guardaría en caché. */}
      {/* eslint-disable-next-line @next/next/no-img-element */}
      <img
        src={foto.url}
        alt={e ? e.descripcion : "Foto de la casa, todavía sin descripción"}
        className="aspect-[4/3] w-full bg-black object-cover"
      />
      <figcaption className="flex flex-col gap-1 px-4 text-base leading-[1.35]">
        <span className="font-bold">Lo que se ve</span>
        <span>{e ? e.descripcion : "Leyendo la foto…"}</span>
        {e?.personaEnElSuelo === "si" && <span className="font-bold">Parece que hay una persona en el suelo.</span>}
        {e?.humoOFuego && <span className="font-bold">Se ve humo o fuego.</span>}
        <span className="text-[14px] text-rojo-texto">
          {e ? "La describió una IA: puede equivocarse." : "La foto la tomó la casa antes de llamar."}
        </span>
      </figcaption>
    </figure>
  );
}
