// Datos inventados para ver las pantallas sin backend: /f/demo?escenario=alerta. Es también el
// respaldo del pitch si falla la red. Las horas se calculan desde «ahora», así el demo siempre
// parece de hoy. Nada de esto es de una persona real.
import type { Alerta, Casa, DatosCasa, Evento } from "./tipos";

export const ESCENARIOS = ["todo-bien", "alerta", "para-saber", "sin-senal"] as const;
export type Escenario = (typeof ESCENARIOS)[number];

export function esEscenario(x: unknown): x is Escenario {
  return typeof x === "string" && (ESCENARIOS as readonly string[]).includes(x);
}

const MIN = 60_000;

function casaDemo(ultimoLatido: Date): Casa {
  return {
    id: "demo",
    nombre: "Carmen",
    condiciones: ["oxigeno", "hipertension"],
    contactos: [
      { nombre: "Josuep", relacion: "hijo", canal: "llamada", orden: 1, donde: "En Caracas" },
      { nombre: "Pedro", relacion: "vecino", canal: "llamada", orden: 2, donde: "En Caracas" },
    ],
    ultimoLatido: ultimoLatido.toISOString(),
    enchufado: true,
    bateria: 82,
  };
}

/** Su día, a horas fijas de Caracas. Solo se muestra lo que ya pasó a la hora del demo. */
const DIA: [string, Evento["tipo"], string][] = [
  ["07:12", "rutina", "Primer sonido del día: una puerta"],
  ["08:30", "estoy_bien", "Tocó «Estoy bien hoy»"],
  ["09:05", "rutina", "Oímos platos y el microondas"],
  ["12:40", "rutina", "TV o radio"],
  ["18:15", "rutina", "Oímos la cocina"],
];

/** Caracas no cambia de horario: siempre UTC−4. */
function hoyALas(ahora: Date, hhmm: string): Date {
  const hoy = new Intl.DateTimeFormat("en-CA", { timeZone: "America/Caracas" }).format(ahora);
  return new Date(`${hoy}T${hhmm}:00-04:00`);
}

/** Lo de rutina hasta `minAntes` minutos antes de ahora, y lo último (agua) justo ahí. */
function eventosDelDia(ahora: Date, minAntes = 2): Evento[] {
  const corte = ahora.getTime() - minAntes * MIN;
  const rutina = DIA.map(([hhmm, tipo, descripcion], i): Evento => ({
    id: `ev-${i}`,
    casaId: "demo",
    hora: hoyALas(ahora, hhmm).toISOString(),
    tipo,
    descripcion,
  })).filter((e) => new Date(e.hora).getTime() < corte - 10 * MIN);
  return [
    ...rutina,
    { id: "ev-agua", casaId: "demo", hora: new Date(corte).toISOString(), tipo: "rutina", descripcion: "Oímos agua corriendo" },
  ];
}

export function simular(escenario: Escenario, ahora: Date): DatosCasa {
  const t = (minAntes: number, seg = 0) =>
    new Date(ahora.getTime() - minAntes * MIN + seg * 1000).toISOString();

  switch (escenario) {
    case "todo-bien":
      return { casa: casaDemo(new Date(ahora.getTime() - MIN)), eventos: eventosDelDia(ahora), alertas: [] };

    case "alerta": {
      const humo: Evento = {
        id: "ev-humo",
        casaId: "demo",
        hora: t(2),
        tipo: "alarma",
        descripcion: "Oímos una alarma de humo",
      };
      const alerta: Alerta = {
        id: "al-humo",
        casaId: "demo",
        eventoId: humo.id,
        nivel: "rojo",
        estado: "escalada",
        creada: t(2),
        venceEn: t(1),
        escaladaEn: t(1),
      };
      return {
        casa: casaDemo(new Date(ahora.getTime() - 20_000)),
        eventos: [...eventosDelDia(ahora, 5), humo],
        alertas: [alerta],
      };
    }

    case "para-saber": {
      const golpe: Evento = {
        id: "ev-golpe",
        casaId: "demo",
        hora: t(30),
        tipo: "golpe",
        descripcion: "Oímos un golpe",
      };
      const tarde: Evento = {
        id: "ev-tarde",
        casaId: "demo",
        hora: t(120),
        tipo: "rutina",
        descripcion: "Hoy los sonidos de la mañana llegaron tarde",
        distinto: "Suele haber agua y platos temprano. Hoy el primero llegó casi una hora después.",
      };
      const falsa: Alerta = {
        id: "al-golpe",
        casaId: "demo",
        eventoId: golpe.id,
        nivel: "rojo",
        estado: "cancelada",
        creada: t(30),
        venceEn: t(29),
        cerradaEn: t(30, 8),
      };
      return {
        casa: casaDemo(new Date(ahora.getTime() - MIN)),
        eventos: [...eventosDelDia(ahora), golpe, tarde],
        alertas: [falsa],
      };
    }

    case "sin-senal":
      return { casa: casaDemo(new Date(ahora.getTime() - 25 * MIN)), eventos: eventosDelDia(ahora, 26), alertas: [] };
  }
}
