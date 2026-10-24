"use client";

// Subir la factura de la farmacia: foto, Claude la lee, la familia revisa y confirma. Solo lo que es
// del récipe se guarda; lo demás de la factura se muestra tachado para que se vea que se leyó.
import { useState } from "react";
import type { Origen } from "@/lib/familia/datos";
import { cruzar, FACTURA_DE_EJEMPLO, type Lectura, type RenglonLeido, type RespuestaLectura } from "@/lib/familia/factura";
import { nombreCompleto } from "@/lib/familia/inventario";
import { guardarCompra } from "@/lib/familia/supabase";
import type { Medicamento } from "@/lib/familia/tipos";
import { enlace } from "./pastillas";
import { Boton, Pantalla, Volver } from "./pantallas";

/** La foto se achica antes de salir del teléfono: una de 12 MP pesa 5 MB y Claude no necesita tanto. */
const LADO_MAX = 1600;

async function achicar(archivo: File): Promise<{ imagen: string; tipo: "image/jpeg" }> {
  const bitmap = await createImageBitmap(archivo);
  const escala = Math.min(1, LADO_MAX / Math.max(bitmap.width, bitmap.height));
  const lienzo = document.createElement("canvas");
  lienzo.width = Math.round(bitmap.width * escala);
  lienzo.height = Math.round(bitmap.height * escala);
  lienzo.getContext("2d")!.drawImage(bitmap, 0, 0, lienzo.width, lienzo.height);
  const url = lienzo.toDataURL("image/jpeg", 0.85);
  return { imagen: url.slice(url.indexOf(",") + 1), tipo: "image/jpeg" };
}

const ERRORES: Record<Exclude<RespuestaLectura, { lectura: Lectura }>["error"], string> = {
  sin_llave: "La lectura de facturas todavía no está activada. Puedes probar con la factura de ejemplo.",
  no_se_leyo: "No pudimos leer la factura. Tómale la foto de frente, con buena luz y que se vea entera.",
  muy_grande: "La foto es muy pesada. Prueba con otra.",
  token: "Este enlace no es de ninguna casa.",
  demasiadas: "Se leyeron varias facturas seguidas. Espera un minuto y vuelve a intentarlo.",
};

type Fila = { renglon: RenglonLeido; medicamentoId: string | null; cajas: string; porCaja: string };

type Paso =
  | { tipo: "elegir" }
  | { tipo: "leyendo" }
  | { tipo: "revisar"; lectura: Lectura; filas: Fila[] }
  | { tipo: "guardando"; lectura: Lectura; filas: Fila[] }
  | { tipo: "listo"; repetida: boolean; resumen: string[]; prueba: boolean };

const entero = (s: string) => (/^\d+$/.test(s.trim()) ? Number(s) : null);

/** Lo que se guardaría de una fila: un medicamento del récipe, cajas y pastillas por caja que valgan. */
function valida(f: Fila) {
  const cajas = entero(f.cajas);
  const porCaja = entero(f.porCaja);
  if (!f.medicamentoId || !cajas || !porCaja || cajas > 50 || porCaja > 500) return null;
  return { medicamentoId: f.medicamentoId, texto: f.renglon.texto, cajas, porCaja };
}

function filasDe(lectura: Lectura, recipe: Medicamento[]): Fila[] {
  return lectura.renglones.map((r) => {
    const m = cruzar(r, recipe);
    // Si la factura no dice de cuántas viene la caja, se propone la de la última compra.
    const porCaja = r.porCaja ?? m?.ultimaCompra?.porCaja ?? null;
    return { renglon: r, medicamentoId: m?.id ?? null, cajas: String(r.cajas || 1), porCaja: porCaja ? String(porCaja) : "" };
  });
}

function FilaFactura({ fila, recipe, onCambio }: { fila: Fila; recipe: Medicamento[]; onCambio: (f: Fila) => void }) {
  const es = recipe.find((m) => m.id === fila.medicamentoId);
  const lista = valida(fila);
  return (
    <li
      className={`flex flex-col gap-2.5 rounded-[18px] border-[1.5px] px-4 py-3.5 ${es ? "border-borde bg-white" : "border-dashed border-borde bg-transparent"}`}
    >
      <span className={`font-mono text-[15px] ${es ? "text-texto" : "text-gris line-through"}`}>{fila.renglon.texto}</span>
      <select
        value={fila.medicamentoId ?? ""}
        onChange={(e) => onCambio({ ...fila, medicamentoId: e.target.value || null })}
        aria-label="Qué medicamento del récipe es"
        className="h-12 rounded-xl border-[1.5px] border-borde bg-white px-3 text-[17px]"
      >
        <option value="">No es del récipe: no se guarda</option>
        {recipe.map((m) => (
          <option key={m.id} value={m.id}>
            {nombreCompleto(m)}
          </option>
        ))}
      </select>
      {es && (
        <div className="flex items-center gap-2 text-[17px]">
          <input
            inputMode="numeric"
            value={fila.cajas}
            onChange={(e) => onCambio({ ...fila, cajas: e.target.value })}
            aria-label="Cuántas cajas"
            className="h-12 w-16 rounded-xl border-[1.5px] border-borde bg-white px-3 text-center"
          />
          <span>{entero(fila.cajas) === 1 ? "caja" : "cajas"} de</span>
          <input
            inputMode="numeric"
            value={fila.porCaja}
            onChange={(e) => onCambio({ ...fila, porCaja: e.target.value })}
            placeholder="?"
            aria-label="Cuántas pastillas trae cada caja"
            className="h-12 w-16 rounded-xl border-[1.5px] border-borde bg-white px-3 text-center"
          />
          <span>pastillas</span>
        </div>
      )}
      {es && (
        <span className={`text-[15px] ${lista ? "text-gris" : "font-bold text-amarillo-tinta"}`}>
          {lista ? `Suma ${lista.cajas * lista.porCaja} pastillas` : "Falta cuántas cajas y de cuántas pastillas"}
        </span>
      )}
    </li>
  );
}

export function SubirFactura({
  token,
  nombre,
  recipe,
  origen,
  escenario,
}: {
  token: string;
  nombre: string;
  recipe: Medicamento[];
  origen: Origen;
  escenario: string | null;
}) {
  const [paso, setPaso] = useState<Paso>({ tipo: "elegir" });
  const [error, setError] = useState<string | null>(null);

  const revisar = (lectura: Lectura) => {
    if (!lectura.esFactura || lectura.renglones.length === 0) {
      setError("Esa foto no parece una factura de farmacia.");
      setPaso({ tipo: "elegir" });
      return;
    }
    setPaso({ tipo: "revisar", lectura, filas: filasDe(lectura, recipe) });
  };

  const leer = async (archivo: File) => {
    setError(null);
    setPaso({ tipo: "leyendo" });
    try {
      const cuerpo = await achicar(archivo);
      const res = await fetch(`/f/${token}/pastillas/factura/leer`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(cuerpo),
      });
      const r = (await res.json()) as RespuestaLectura;
      if ("error" in r) {
        setError(ERRORES[r.error]);
        setPaso({ tipo: "elegir" });
      } else revisar(r.lectura);
    } catch {
      setError(ERRORES.no_se_leyo);
      setPaso({ tipo: "elegir" });
    }
  };

  const guardar = async (lectura: Lectura, filas: Fila[]) => {
    const renglones = filas.map(valida).filter((r) => r !== null);
    setError(null);
    setPaso({ tipo: "guardando", lectura, filas });
    const resumen = renglones.map((r) => {
      const m = recipe.find((x) => x.id === r.medicamentoId)!;
      return `${r.cajas * r.porCaja} pastillas de ${nombreCompleto(m)}`;
    });
    if (origen !== "supabase") {
      setPaso({ tipo: "listo", repetida: false, resumen, prueba: true });
      return;
    }
    const fecha = lectura.fecha && /^\d{4}-\d{2}-\d{2}$/.test(lectura.fecha) ? lectura.fecha : null;
    const r = await guardarCompra(token, renglones, { ...lectura, fecha }).catch(() => null);
    if (!r) {
      setError("No se pudo guardar. Revisa la conexión y prueba otra vez.");
      setPaso({ tipo: "revisar", lectura, filas });
      return;
    }
    setPaso({ tipo: "listo", repetida: r.repetida, resumen, prueba: false });
  };

  const volver = <Volver href={enlace(token, "/pastillas", escenario)}>Pastillas de {nombre}</Volver>;

  if (paso.tipo === "listo") {
    return (
      <Pantalla>
        {volver}
        <h1 className="text-[30px] leading-tight font-bold">
          {paso.repetida ? "Esta factura ya estaba" : "Listo, quedó guardada"}
        </h1>
        <p className="text-[19px] leading-[1.4] text-texto">
          {paso.repetida
            ? "La habíamos cargado antes, así que no sumamos nada otra vez."
            : `Sumamos ${paso.resumen.join(" y ")}.`}
        </p>
        {paso.prueba && (
          <p className="text-[15px] leading-[1.4] text-gris">Son datos de prueba: en esta casa simulada no se guarda nada.</p>
        )}
        <div className="mt-auto">
          <Boton href={enlace(token, "/pastillas", escenario)} variante="verde">
            Ver cuántas quedan
          </Boton>
        </div>
      </Pantalla>
    );
  }

  if (paso.tipo === "revisar" || paso.tipo === "guardando") {
    const { lectura, filas } = paso;
    const n = filas.map(valida).filter(Boolean).length;
    const deFactura = [lectura.farmacia, lectura.numero && `Factura ${lectura.numero}`, lectura.fecha]
      .filter(Boolean)
      .join(" · ");
    const cambiar = (i: number, f: Fila) =>
      setPaso({ ...paso, tipo: "revisar", filas: filas.map((x, j) => (j === i ? f : x)) });
    return (
      <Pantalla>
        {volver}
        <h1 className="text-[30px] leading-tight font-bold">¿Está bien lo que leímos?</h1>
        <p className="text-[17px] leading-[1.4] text-texto">
          Revisa las cantidades. Solo guardamos lo que está en el récipe de {nombre}.
        </p>
        {deFactura && <span className="text-[15px] text-gris">{deFactura}</span>}
        <ul className="flex flex-col gap-2.5">
          {filas.map((f, i) => (
            <FilaFactura key={i} fila={f} recipe={recipe} onCambio={(nueva) => cambiar(i, nueva)} />
          ))}
        </ul>
        {error && <p role="alert" className="text-base font-bold text-rojo">{error}</p>}
        <div className="mt-auto flex flex-col gap-2.5 pt-2">
          <button
            type="button"
            disabled={n === 0 || paso.tipo === "guardando"}
            onClick={() => guardar(lectura, filas)}
            className="flex h-16 w-full items-center justify-center rounded-[18px] bg-verde text-[21px] font-bold text-white transition-transform active:scale-[0.98] disabled:opacity-40"
          >
            {paso.tipo === "guardando"
              ? "Guardando…"
              : n === 0
                ? "Nada del récipe para guardar"
                : `Guardar ${n === 1 ? "1 medicamento" : `${n} medicamentos`}`}
          </button>
          <Boton onClick={() => setPaso({ tipo: "elegir" })} variante="borde-verde">
            Otra foto
          </Boton>
        </div>
      </Pantalla>
    );
  }

  return (
    <Pantalla>
      {volver}
      <h1 className="text-[30px] leading-tight font-bold">La factura de la farmacia</h1>
      <p className="text-[17px] leading-[1.4] text-texto">
        Tómale una foto a la factura cuando compren las pastillas de {nombre}. La leemos, tú revisas, y
        sumamos al inventario lo que es del récipe. La foto no se guarda.
      </p>
      {error && <p role="alert" className="text-base font-bold text-rojo">{error}</p>}
      <div className="mt-auto flex flex-col gap-2.5 pt-2">
        <label
          className={`flex h-16 w-full cursor-pointer items-center justify-center gap-3 rounded-[18px] bg-verde text-[21px] font-bold text-white transition-transform has-focus-visible:outline-3 has-focus-visible:outline-offset-3 has-focus-visible:outline-verde active:scale-[0.98] ${paso.tipo === "leyendo" ? "pointer-events-none opacity-80" : ""}`}
        >
          {paso.tipo === "leyendo" && (
            <svg className="size-6 motion-safe:animate-spin" viewBox="0 0 24 24" fill="none" aria-hidden="true">
              <circle cx="12" cy="12" r="9" stroke="currentColor" strokeOpacity="0.3" strokeWidth="3" />
              <path d="M21 12a9 9 0 0 0-9-9" stroke="currentColor" strokeWidth="3" strokeLinecap="round" />
            </svg>
          )}
          {paso.tipo === "leyendo" ? "Leyendo la factura…" : "Tomar o elegir la foto"}
          <input
            type="file"
            accept="image/*"
            className="sr-only"
            disabled={paso.tipo === "leyendo"}
            onChange={(e) => {
              const archivo = e.target.files?.[0];
              e.target.value = "";
              if (archivo) leer(archivo);
            }}
          />
        </label>
        <Boton onClick={() => revisar(FACTURA_DE_EJEMPLO)} variante="borde-verde">
          Probar con una factura de ejemplo
        </Boton>
      </div>
    </Pantalla>
  );
}
