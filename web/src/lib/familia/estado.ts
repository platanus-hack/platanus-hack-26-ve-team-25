// Qué pantalla ve la familia, derivado de los datos de la casa. Es una función pura: los mismos
// datos y la misma hora dan siempre la misma pantalla, y por eso se prueba sin navegador.
import type { Alerta, Casa, DatosCasa, Evento, TipoEvento } from "./tipos";

/** Dos latidos perdidos (cada 90 s) y la casa se declara sin señal. Ver investigacion-alertas.md. */
export const SILENCIO_SIN_SENAL_MS = 180_000;

/** La familia es venezolana y el servidor corre en UTC: toda hora se muestra en la de Caracas. */
export const ZONA = "America/Caracas";

/** Lo que dice el aviso rojo, según lo que pasó. */
const TITULAR: Record<TipoEvento, (nombre: string) => string> = {
  alarma: (n) => `Alarma de humo en casa de ${n}`,
  vidrio: (n) => `Se rompió un vidrio en casa de ${n}`,
  golpe: (n) => `Un golpe fuerte en casa de ${n}`,
  grito: (n) => `Un grito en casa de ${n}`,
  apagon: (n) => `Se fue la luz en casa de ${n}`,
  panico: (n) => `${n} pidió ayuda`,
  huele_gas: (n) => `${n} dice que huele a gas`,
  me_siento_mal: (n) => `${n} dice que se siente mal`,
  rutina: (n) => `Algo distinto en casa de ${n}`,
  estoy_bien: (n) => `${n} dijo que está bien`,
};

/** Los que pidió la persona misma: no hubo pregunta ni cuenta regresiva. */
const LO_PIDIO: TipoEvento[] = ["panico", "huele_gas", "me_siento_mal"];

export type AvisoSuave = {
  hora: string;
  etiqueta: string; // "FALSA ALARMA"
  titulo: string;
  detalle: string;
};

export type Vista =
  | {
      tipo: "alerta";
      alerta: Alerta;
      titular: string;
      explicacion: string;
      hecho: string[];
    }
  | { tipo: "sin_senal"; desde: string; minutos: number; ultimos: Evento[] }
  | { tipo: "bien"; paraSaber: AvisoSuave[]; dia: Evento[]; ultimo?: Evento };

const ms = (iso: string) => new Date(iso).getTime();

export function hora(iso: string): string {
  return new Intl.DateTimeFormat("es-VE", {
    timeZone: ZONA,
    hour: "2-digit",
    minute: "2-digit",
    hourCycle: "h23",
  }).format(new Date(iso));
}

/** «Sáb 24 oct» */
export function fecha(ahora: Date): string {
  const partes = new Intl.DateTimeFormat("es-VE", {
    timeZone: ZONA,
    weekday: "short",
    day: "numeric",
    month: "short",
  }).formatToParts(ahora);
  const de = (t: string) => partes.find((p) => p.type === t)?.value.replace(".", "") ?? "";
  const dia = de("weekday");
  return `${dia.charAt(0).toUpperCase()}${dia.slice(1)} ${de("day")} ${de("month")}`;
}

/** «hace un momento», «hace 1 min», «hace 2 h» */
export function haceCuanto(iso: string, ahora: Date): string {
  const min = Math.floor((ahora.getTime() - ms(iso)) / 60_000);
  if (min < 1) return "hace un momento";
  if (min < 60) return `hace ${min} min`;
  return `hace ${Math.floor(min / 60)} h`;
}

/** El día de Caracas de una fecha, para quedarse solo con lo de hoy. */
function diaDe(d: Date): string {
  return new Intl.DateTimeFormat("en-CA", { timeZone: ZONA }).format(d);
}

/** «Josuep, su hijo» */
export function quien(c: { nombre: string; relacion: string }, articulo: "su" | "el"): string {
  return `${c.nombre}, ${articulo} ${c.relacion}`;
}

function contactosEnOrden(casa: Casa) {
  return [...casa.contactos].sort((a, b) => a.orden - b.orden);
}

function vistaAlerta(casa: Casa, alerta: Alerta, evento: Evento | undefined): Vista {
  const tipo = evento?.tipo ?? "alarma";
  const lo_pidio = LO_PIDIO.includes(tipo);
  const espera = Math.round((ms(alerta.venceEn) - ms(alerta.creada)) / 1000);
  const primero = contactosEnOrden(casa)[0];

  const explicacion = lo_pidio
    ? `Lo pidió desde su pantalla a las ${hora(alerta.creada)}.`
    : `Sonó a las ${hora(alerta.creada)}. Le preguntamos si estaba bien y no respondió en ${espera} segundos.`;

  const hecho = [
    ...(lo_pidio ? [] : ["Le preguntamos en su casa si estaba bien"]),
    ...(primero ? [`Desde su casa llamamos a ${quien(primero, "su")}`] : []),
    "Te avisamos por aquí y por WhatsApp",
  ];

  return { tipo: "alerta", alerta, titular: TITULAR[tipo](casa.nombre), explicacion, hecho };
}

function avisosSuaves(datos: DatosCasa, hoy: string): AvisoSuave[] {
  const eventoDe = new Map(datos.eventos.map((e) => [e.id, e]));
  const deHoy = (iso: string) => diaDe(new Date(iso)) === hoy;

  const falsas = datos.alertas
    .filter((a) => a.estado === "cancelada" && deHoy(a.creada))
    .map((a): AvisoSuave & { orden: number } => {
      const ev = eventoDe.get(a.eventoId);
      const tardo = a.cerradaEn ? Math.round((ms(a.cerradaEn) - ms(a.creada)) / 1000) : null;
      return {
        orden: ms(a.creada),
        hora: hora(a.creada),
        etiqueta: "FALSA ALARMA",
        titulo: `${ev?.descripcion ?? "Oímos algo"} y deslizó «Estoy bien»`,
        detalle:
          tardo === null
            ? "No te molestamos: respondió desde la casa."
            : `No te molestamos: respondió en ${tardo} segundos.`,
      };
    });

  const distintos = datos.eventos
    .filter((e) => e.tipo === "rutina" && e.distinto && deHoy(e.hora))
    .map((e) => ({
      orden: ms(e.hora),
      hora: hora(e.hora),
      etiqueta: "DÍA DISTINTO",
      titulo: e.descripcion,
      detalle: e.distinto!,
    }));

  return [...falsas, ...distintos]
    .sort((a, b) => b.orden - a.orden)
    .map(({ orden: _, ...aviso }) => aviso);
}

/**
 * El orden importa: una alerta roja sin atender gana sobre todo, porque es lo único que pide que
 * alguien haga algo ya. Después, el silencio de la casa. Si no, todo bien.
 */
export function derivarVista(datos: DatosCasa, ahora: Date): Vista {
  const { casa, eventos, alertas } = datos;
  const eventoDe = new Map(eventos.map((e) => [e.id, e]));

  const urgente = alertas
    .filter((a) => a.nivel === "rojo" && a.estado === "escalada")
    .sort((a, b) => ms(b.creada) - ms(a.creada))[0];
  if (urgente) return vistaAlerta(casa, urgente, eventoDe.get(urgente.eventoId));

  const recientes = [...eventos].sort((a, b) => ms(b.hora) - ms(a.hora));
  const silencio = ahora.getTime() - ms(casa.ultimoLatido);
  if (silencio > SILENCIO_SIN_SENAL_MS) {
    return {
      tipo: "sin_senal",
      desde: casa.ultimoLatido,
      minutos: Math.floor(silencio / 60_000),
      ultimos: recientes.slice(0, 2),
    };
  }

  const hoy = diaDe(ahora);
  const dia = recientes.filter((e) => diaDe(new Date(e.hora)) === hoy);
  return { tipo: "bien", paraSaber: avisosSuaves(datos, hoy), dia, ultimo: dia[0] };
}

/** «Ya hablé con ella»: la misma transición que `Alerta.atender` en Dart. */
export function atender(alerta: Alerta, ahora: Date, quienAtiende: string): Alerta {
  if (alerta.estado !== "escalada") return alerta;
  return { ...alerta, estado: "atendida", cerradaEn: ahora.toISOString(), atendidaPor: quienAtiende };
}
