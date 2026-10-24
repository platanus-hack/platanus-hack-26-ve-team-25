// Cuántas pastillas quedan, cuántos días alcanzan y cuándo hay que comprar. Como estado.ts, es una
// función pura: el mismo inventario a la misma hora da siempre la misma cuenta. Lo que queda lo suma
// la base (un libro de movimientos: facturas, tomas y conteos); aquí solo se proyecta hacia adelante.
import { ZONA } from "./estado";
import type { Medicamento } from "./tipos";

/**
 * Con menos de 7 días se avisa. La familia suele estar fuera del país: tiene que conseguir quién
 * compre, y en Venezuela un medicamento puede faltar en una farmacia y hay que buscarlo en otra.
 * Una semana da para eso sin avisar tan temprano que se vuelva ruido.
 */
export const AVISO_DIAS = 7;

/** La compra que se sugiere cubre un mes de tomas. */
export const DIAS_DE_COMPRA = 30;

/** Más allá de un año no se proyecta: para la pantalla es «alcanza de sobra». */
const HORIZONTE_DIAS = 366;

const DIA_MS = 86_400_000;

export type Cuenta = {
  medicamento: Medicamento;
  /** Pastillas al día según las tomas del récipe. */
  porDia: number;
  quedan: number | null;
  /** La primera toma que ya no se puede cubrir (ISO), o null si no se sabe o alcanza de sobra. */
  seAcaba: string | null;
  /** Días completos que faltan para `seAcaba`. null si no se sabe; Infinity si alcanza de sobra. */
  dias: number | null;
  /** El día de Caracas (AAAA-MM-DD) desde el que hay que comprar: `seAcaba` menos AVISO_DIAS. */
  comprarDesde: string | null;
  hayQueComprar: boolean;
  /** Para un mes de tomas, cuántas pastillas faltan y en cuántas cajas (si se sabe de cuántas vienen). */
  faltanMes: number;
  cajas: number | null;
};

/** La compra sugerida, lista para un mensaje de WhatsApp o para el carrito de una farmacia. */
export type Pedido = {
  nombre: string;
  concentracion: string;
  comerciales: string[];
  pastillas: number;
  cajas: number | null;
  porCaja: number | null;
};

/** El día de Caracas de un instante, «2026-10-24». */
export function diaCaracas(d: Date): string {
  return new Intl.DateTimeFormat("en-CA", { timeZone: ZONA }).format(d);
}

/** Caracas no cambia de horario: siempre UTC−4. */
function enCaracas(dia: string, hhmm: string): Date {
  return new Date(`${dia}T${hhmm}:00-04:00`);
}

function masDias(dia: string, n: number): string {
  return new Date(Date.parse(`${dia}T12:00:00Z`) + n * DIA_MS).toISOString().slice(0, 10);
}

export function porDia(m: Medicamento): number {
  return m.tomas.reduce((s, t) => s + t.cantidad, 0);
}

/**
 * Recorre las tomas desde ahora, descontando, hasta la primera que no alcanza. Las tomas de hoy que
 * ya pasaron no cuentan: si se la tomó ya está descontada, y si no, ya no se la va a tomar a esa hora.
 */
function primeraSinCubrir(m: Medicamento, quedan: number, ahora: Date): Date | null {
  const tomas = [...m.tomas].sort((a, b) => a.hora.localeCompare(b.hora));
  const hoy = diaCaracas(ahora);
  let resto = quedan;
  for (let d = 0; d < HORIZONTE_DIAS; d++) {
    const dia = masDias(hoy, d);
    for (const t of tomas) {
      const cuando = enCaracas(dia, t.hora);
      if (cuando <= ahora) continue;
      if (resto < t.cantidad) return cuando;
      resto -= t.cantidad;
    }
  }
  return null;
}

export function contar(m: Medicamento, ahora: Date): Cuenta {
  const diario = porDia(m);
  const porCaja = m.ultimaCompra?.porCaja ?? null;
  const base = { medicamento: m, porDia: diario, quedan: m.quedan };

  // Sin tomas no se gasta; sin conteo no se sabe. En los dos casos no hay fecha ni aviso.
  if (m.quedan === null || diario === 0) {
    return { ...base, seAcaba: null, dias: null, comprarDesde: null, hayQueComprar: false, faltanMes: 0, cajas: null };
  }

  const faltanMes = Math.max(0, Math.ceil(diario * DIAS_DE_COMPRA - m.quedan));
  const cajas = porCaja && faltanMes > 0 ? Math.ceil(faltanMes / porCaja) : porCaja ? 0 : null;
  const seAcaba = primeraSinCubrir(m, m.quedan, ahora);
  if (!seAcaba) {
    return { ...base, seAcaba: null, dias: Infinity, comprarDesde: null, hayQueComprar: false, faltanMes, cajas };
  }

  const dias = Math.floor((seAcaba.getTime() - ahora.getTime()) / DIA_MS);
  const comprarDesde = masDias(diaCaracas(seAcaba), -AVISO_DIAS);
  return {
    ...base,
    seAcaba: seAcaba.toISOString(),
    dias,
    comprarDesde,
    hayQueComprar: dias < AVISO_DIAS,
    faltanMes,
    cajas,
  };
}

/** Lo que se acaba primero va primero. */
export function contarTodo(inventario: Medicamento[], ahora: Date): Cuenta[] {
  const orden = (c: Cuenta) => (c.dias === null ? Number.MAX_VALUE : c.dias);
  return inventario.map((m) => contar(m, ahora)).sort((a, b) => orden(a) - orden(b));
}

/** Cuánto comprar para un mes, en pastillas y, si se sabe de cuántas viene la caja, en cajas. */
export function compraDe(c: Cuenta): Pick<Pedido, "pastillas" | "cajas" | "porCaja"> {
  return { pastillas: c.faltanMes, cajas: c.cajas, porCaja: c.medicamento.ultimaCompra?.porCaja ?? null };
}

/**
 * Qué comprar ahora: solo lo que tiene aviso, para un mes. Es el punto de enganche para el WhatsApp
 * a la familia y, más adelante, para mandar el pedido a una farmacia con entrega (docs/pendientes.md).
 */
export function pedido(inventario: Medicamento[], ahora: Date): Pedido[] {
  return contarTodo(inventario, ahora)
    .filter((c) => c.hayQueComprar)
    .map((c) => ({
      nombre: c.medicamento.nombre,
      concentracion: c.medicamento.concentracion,
      comerciales: c.medicamento.comerciales,
      ...compraDe(c),
    }));
}

/** Una línea para la pantalla principal: lo que se acaba primero manda. null si no hay récipe. */
export function resumenPastillas(inventario: Medicamento[], ahora: Date): string | null {
  const cuentas = contarTodo(inventario, ahora).filter((c) => c.dias !== null);
  if (inventario.length === 0) return null;
  if (cuentas.length === 0) return "Sus pastillas: falta saber cuántas quedan";
  const dias = cuentas[0].dias!;
  if (dias === Infinity) return "Sus pastillas alcanzan de sobra";
  if (dias === 0) return "Sus pastillas: una se acaba hoy";
  return `Sus pastillas alcanzan para ${dias} ${dias === 1 ? "día" : "días"}`;
}

/** «Losartán 50 mg» */
export function nombreCompleto(m: { nombre: string; concentracion: string }): string {
  return m.concentracion ? `${m.nombre} ${m.concentracion}` : m.nombre;
}

/** «2 cajas de 30», o «60 pastillas» si no se sabe de cuántas viene la caja. */
export function cuantoComprar(p: Pick<Pedido, "pastillas" | "cajas" | "porCaja">): string {
  if (p.cajas && p.porCaja) return `${p.cajas} ${p.cajas === 1 ? "caja" : "cajas"} de ${p.porCaja}`;
  return `${p.pastillas} pastillas`;
}

/** «hoy», «mañana», «el mié 28 oct» */
export function cuandoSeAcaba(iso: string, ahora: Date): string {
  const dia = diaCaracas(new Date(iso));
  const hoy = diaCaracas(ahora);
  if (dia === hoy) return "hoy";
  if (dia === masDias(hoy, 1)) return "mañana";
  const partes = new Intl.DateTimeFormat("es-VE", {
    timeZone: ZONA,
    weekday: "short",
    day: "numeric",
    month: "short",
  }).formatToParts(new Date(iso));
  const de = (t: string) => partes.find((p) => p.type === t)?.value.replace(".", "") ?? "";
  return `el ${de("weekday")} ${de("day")} ${de("month")}`;
}

/** «Quedan 5 pastillas», «Queda 1 pastilla», «No quedan pastillas» */
export function quedanTexto(n: number): string {
  if (n <= 0) return "No quedan pastillas";
  const k = Number.isInteger(n) ? String(n) : n.toLocaleString("es-VE");
  return n === 1 ? "Queda 1 pastilla" : `Quedan ${k} pastillas`;
}

/**
 * El mensaje de compra para la familia. Kapso todavía no está: cuando esté, esto es lo que se manda
 * por WhatsApp al primer contacto, una vez al día como mucho (docs/pendientes.md, «Aviso de compra»).
 */
export function mensajeDeCompra(nombreCasa: string, inventario: Medicamento[], ahora: Date): string | null {
  const cuentas = contarTodo(inventario, ahora).filter((c) => c.hayQueComprar);
  if (cuentas.length === 0) return null;
  const lineas = cuentas.map(
    (c) =>
      `• ${nombreCompleto(c.medicamento)}: ${quedanTexto(c.quedan ?? 0).toLowerCase()}, alcanza hasta ${cuandoSeAcaba(c.seAcaba!, ahora)}. Para un mes: ${cuantoComprar(compraDe(c))}.`,
  );
  return [`Hay que comprar pastillas para ${nombreCasa}:`, ...lineas].join("\n");
}
