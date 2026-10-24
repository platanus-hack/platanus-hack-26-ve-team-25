"use client";

import { useEffect, useMemo, useState } from "react";
import { atender, derivarVista } from "@/lib/familia/estado";
import type { DatosCasa } from "@/lib/familia/tipos";
import { AlertaUrgente, SinSenal, TodoBien } from "./pantallas";

/** Dónde recuerda el teléfono la última casa abierta, para que la web instalada abra ahí. */
export const CLAVE_ULTIMA_CASA = "familia:ultima-casa";

/** Cada cuánto se recalcula «hace 1 min» y si la casa se quedó sin señal. */
const TIC_MS = 15_000;

export function VistaFamilia({ token, inicial }: { token: string; inicial: DatosCasa }) {
  const [datos, setDatos] = useState(inicial);
  const [ahora, setAhora] = useState(() => new Date());

  useEffect(() => {
    const id = setInterval(() => setAhora(new Date()), TIC_MS);
    return () => clearInterval(id);
  }, []);

  useEffect(() => {
    try {
      localStorage.setItem(CLAVE_ULTIMA_CASA, `${location.pathname}${location.search}`);
    } catch {
      // Navegación privada: la raíz mostrará la portada, nada más.
    }
  }, [token]);

  const vista = useMemo(() => derivarVista(datos, ahora), [datos, ahora]);

  switch (vista.tipo) {
    case "alerta":
      return (
        <AlertaUrgente
          casa={datos.casa}
          vista={vista}
          onAtendida={() =>
            // Con Supabase esto será una escritura; hoy, con datos simulados, vive en la pantalla.
            setDatos((d) => ({
              ...d,
              alertas: d.alertas.map((a) => (a.id === vista.alerta.id ? atender(a, new Date(), "familia") : a)),
            }))
          }
        />
      );
    case "sin_senal":
      return <SinSenal casa={datos.casa} vista={vista} ahora={ahora} />;
    case "bien":
      return <TodoBien casa={datos.casa} vista={vista} ahora={ahora} />;
  }
}
