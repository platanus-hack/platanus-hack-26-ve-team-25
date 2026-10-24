"use client";

// Las pastillas de la casa: cuántas quedan de cada una, hasta cuándo alcanzan y qué comprar. La cuenta
// sale de lib/familia/inventario.ts; aquí solo se pinta y se corrige el conteo a mano.
import { useMemo, useState } from "react";
import type { Origen } from "@/lib/familia/datos";
import { hora } from "@/lib/familia/estado";
import {
  AVISO_DIAS,
  compraDe,
  contarTodo,
  cuandoSeAcaba,
  cuantoComprar,
  nombreCompleto,
  quedanTexto,
  type Cuenta,
} from "@/lib/familia/inventario";
import { ajustarPastillas } from "@/lib/familia/supabase";
import type { Medicamento } from "@/lib/familia/tipos";
import { Boton, Pantalla, Volver } from "./pantallas";

/** «/f/demo/pastillas?escenario=para-saber»: los simulados siguen siéndolo al navegar. */
export function enlace(token: string, ruta: string, escenario: string | null): string {
  return `/f/${token}${ruta}${escenario ? `?escenario=${escenario}` : ""}`;
}

function cuantasAlDia(c: Cuenta): string {
  const n = c.porDia.toLocaleString("es-VE");
  const horas = c.medicamento.tomas.map((t) => t.hora).join(" y ");
  return c.porDia === 0 ? "Sin tomas en el récipe" : `${n} al día · ${horas}`;
}

function Estado({ c, ahora }: { c: Cuenta; ahora: Date }) {
  if (c.quedan === null) {
    return (
      <span className="text-base leading-[1.35] text-texto">
        No sabemos cuántas quedan. Sube la factura de la última compra o cuéntalas.
      </span>
    );
  }
  if (c.hayQueComprar) {
    return (
      <span className="rounded-[14px] bg-amarillo-fondo px-3.5 py-3 text-base leading-[1.35] text-amarillo-tinta">
        <strong className="text-tinta">Hay que comprar.</strong> Se acaban {cuandoSeAcaba(c.seAcaba!, ahora)}, en
        la toma de las {hora(c.seAcaba!)}. Para un mes: {cuantoComprar(compraDe(c))}.
      </span>
    );
  }
  if (c.dias === Infinity) return <span className="text-base text-texto">Alcanzan para más de un año.</span>;
  if (c.dias === null) return null;
  return (
    <span className="text-base text-texto">
      Alcanzan para {c.dias} días: se acaban {cuandoSeAcaba(c.seAcaba!, ahora)}.
    </span>
  );
}

function Corregir({ onGuardar }: { onGuardar: (n: number) => Promise<void> }) {
  const [valor, setValor] = useState("");
  const [guardando, setGuardando] = useState(false);
  const n = Number(valor.replace(",", "."));
  const vale = valor !== "" && Number.isFinite(n) && n >= 0 && n <= 5000;
  return (
    <details className="group">
      <summary className="flex min-h-11 cursor-pointer list-none items-center self-start text-[15px] font-bold text-verde underline underline-offset-4 [&::-webkit-details-marker]:hidden">
        Las conté y son otras
      </summary>
      <form
        className="flex gap-2"
        onSubmit={async (e) => {
          e.preventDefault();
          if (!vale) return;
          setGuardando(true);
          await onGuardar(n);
          setGuardando(false);
          setValor("");
        }}
      >
        <input
          inputMode="decimal"
          value={valor}
          onChange={(e) => setValor(e.target.value)}
          placeholder="Cuántas quedan"
          aria-label="Cuántas pastillas quedan"
          className="h-12 min-w-0 flex-1 rounded-xl border-[1.5px] border-borde bg-white px-3 text-[17px]"
        />
        <button
          type="submit"
          disabled={!vale || guardando}
          className="h-12 rounded-xl bg-verde px-4 text-[17px] font-bold text-white disabled:opacity-40"
        >
          {guardando ? "Guardando…" : "Guardar"}
        </button>
      </form>
    </details>
  );
}

export function Pastillas({
  token,
  nombre,
  inicial,
  origen,
  escenario,
}: {
  token: string;
  nombre: string;
  inicial: Medicamento[];
  origen: Origen;
  escenario: string | null;
}) {
  const [inventario, setInventario] = useState(inicial);
  const [error, setError] = useState<string | null>(null);
  const [ahora] = useState(() => new Date());
  const cuentas = useMemo(() => contarTodo(inventario, ahora), [inventario, ahora]);

  const corregir = async (id: string, quedan: number) => {
    setError(null);
    let nuevo: number | null = quedan;
    if (origen === "supabase") {
      nuevo = await ajustarPastillas(token, id, quedan).catch(() => null);
      if (nuevo === null) {
        setError("No se pudo guardar el conteo. Revisa la conexión y prueba otra vez.");
        return;
      }
    }
    setInventario((inv) => inv.map((m) => (m.id === id ? { ...m, quedan: Number(nuevo) } : m)));
  };

  return (
    <Pantalla>
      <Volver href={enlace(token, "", escenario)}>Casa de {nombre}</Volver>
      <h1 className="text-[30px] leading-tight font-bold">Sus pastillas</h1>
      <p className="text-[17px] leading-[1.4] text-texto">
        Cada vez que {nombre} toca «Ya me la tomé», descontamos una. Te avisamos cuando queden para menos
        de {AVISO_DIAS} días.
      </p>

      {cuentas.length === 0 && (
        <p className="rounded-[18px] border-[1.5px] border-borde bg-white px-[18px] py-4 text-[17px] leading-[1.4] text-texto">
          Todavía no hay récipe cargado. Pronto se podrá cargar con una foto del récipe.
        </p>
      )}

      {cuentas.map((c) => (
        <article
          key={c.medicamento.id}
          className="flex flex-col gap-2.5 rounded-[18px] border-[1.5px] border-borde bg-white px-[18px] py-4"
        >
          <div className="flex items-start justify-between gap-3">
            <div className="flex flex-col gap-1">
              <span className="text-[21px] leading-tight font-bold">{nombreCompleto(c.medicamento)}</span>
              <span className="text-[15px] text-gris">{cuantasAlDia(c)}</span>
            </div>
            {c.quedan !== null && (
              <span className="flex shrink-0 flex-col items-end" aria-label={quedanTexto(c.quedan)}>
                <span className="text-[30px] leading-none font-bold tabular-nums">{c.quedan.toLocaleString("es-VE")}</span>
                <span className="mt-1 text-[13px] text-gris">quedan</span>
              </span>
            )}
          </div>
          <Estado c={c} ahora={ahora} />
          <Corregir onGuardar={(n) => corregir(c.medicamento.id, n)} />
        </article>
      ))}

      {error && <p role="alert" className="text-base font-bold text-rojo">{error}</p>}

      <div className="mt-auto flex flex-col gap-2.5 pt-2">
        {cuentas.length > 0 && (
          <Boton href={enlace(token, "/pastillas/factura", escenario)} variante="verde">
            Subir la factura de la farmacia
          </Boton>
        )}
      </div>
    </Pantalla>
  );
}
