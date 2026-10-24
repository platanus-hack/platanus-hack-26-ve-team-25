"use client";

import { useEffect, useMemo, useState } from "react";
import type { Origen } from "@/lib/familia/datos";
import { atender, derivarVista } from "@/lib/familia/estado";
import { resumenPastillas } from "@/lib/familia/inventario";
import { atenderAlerta, leerCasa } from "@/lib/familia/supabase";
import type { DatosCasa } from "@/lib/familia/tipos";
import { AlertaUrgente, SinSenal, TodoBien } from "./pantallas";
import { enlace } from "./pastillas";

/** Dónde recuerda el teléfono la última casa abierta, para que la web instalada abra ahí. */
export const CLAVE_ULTIMA_CASA = "familia:ultima-casa";

/** Cada cuánto se recalcula «hace 1 min» y si la casa se quedó sin señal. */
const TIC_MS = 15_000;

/**
 * Cada cuánto se vuelve a leer la casa. Cada lectura además escala lo vencido en la base. Con 50
 * personas mirando son 10 lecturas por segundo, que Supabase gratis aguanta. Si hace falta menos,
 * el siguiente paso es Realtime.
 */
const LECTURA_MS = 5_000;

export function VistaFamilia({
  token,
  inicial,
  origen,
  escenario,
}: {
  token: string;
  inicial: DatosCasa;
  origen: Origen;
  /** El escenario simulado, para que los enlaces lo conserven. */
  escenario: string | null;
}) {
  const [datos, setDatos] = useState(inicial);
  const [ahora, setAhora] = useState(() => new Date());

  useEffect(() => {
    const id = setInterval(() => setAhora(new Date()), TIC_MS);
    return () => clearInterval(id);
  }, []);

  useEffect(() => {
    if (origen !== "supabase") return;
    let vivo = true;
    const leer = async () => {
      // Con la pestaña escondida no se lee: al volver, se lee al instante.
      if (document.hidden) return;
      try {
        const nuevos = await leerCasa(token);
        if (vivo && nuevos) {
          setDatos(nuevos);
          setAhora(new Date());
        }
      } catch {
        // Sin red: se queda lo último que se leyó, y el «hace N min» lo deja ver.
      }
    };
    const id = setInterval(leer, LECTURA_MS);
    document.addEventListener("visibilitychange", leer);
    return () => {
      vivo = false;
      clearInterval(id);
      document.removeEventListener("visibilitychange", leer);
    };
  }, [origen, token]);

  useEffect(() => {
    try {
      localStorage.setItem(CLAVE_ULTIMA_CASA, `${location.pathname}${location.search}`);
    } catch {
      // Navegación privada: la raíz mostrará la portada, nada más.
    }
  }, [token]);

  const vista = useMemo(() => derivarVista(datos, ahora), [datos, ahora]);
  const resumen = useMemo(() => resumenPastillas(datos.inventario ?? [], ahora), [datos, ahora]);
  const pastillas = resumen ? { texto: resumen, href: enlace(token, "/pastillas", escenario) } : null;

  const alAtender = (alertaId: string) => {
    // Se marca en pantalla al instante; con Supabase, la próxima lectura trae lo que quedó en la base.
    setDatos((d) => ({
      ...d,
      alertas: d.alertas.map((a) => (a.id === alertaId ? atender(a, new Date(), "la familia") : a)),
    }));
    if (origen === "supabase") atenderAlerta(token, alertaId, "la familia").catch(() => {});
  };

  switch (vista.tipo) {
    case "alerta":
      return <AlertaUrgente casa={datos.casa} vista={vista} onAtendida={() => alAtender(vista.alerta.id)} />;
    case "sin_senal":
      return <SinSenal casa={datos.casa} vista={vista} ahora={ahora} />;
    case "bien":
      return <TodoBien casa={datos.casa} vista={vista} ahora={ahora} pastillas={pastillas} />;
  }
}
