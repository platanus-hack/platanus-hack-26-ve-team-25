// De las 521 clases de YAMNet a lo que le importa a la familia.
// Los nombres son los de yamnet_label_list.txt, que viene dentro del modelo.

export type TipoEvento = "alarma" | "vidrio" | "golpe" | "grito" | "tv" | "rutina";

const CLASES: Record<string, TipoEvento> = {
  "Smoke detector, smoke alarm": "alarma",
  "Fire alarm": "alarma",
  Alarm: "alarma",
  Glass: "vidrio",
  Shatter: "vidrio",
  "Thump, thud": "golpe",
  Bang: "golpe",
  Slam: "golpe",
  Screaming: "grito",
  Shout: "grito",
  Yell: "grito",
  "Crying, sobbing": "grito",
  "Wail, moan": "grito",
  Television: "tv",
  Radio: "tv",
  Speech: "rutina",
  "Water tap, faucet": "rutina",
  "Sink (filling or washing)": "rutina",
  "Dishes, pots, and pans": "rutina",
  "Cutlery, silverware": "rutina",
  "Microwave oven": "rutina",
  "Toilet flush": "rutina",
  Door: "rutina",
  Doorbell: "rutina",
  Knock: "rutina",
};

export const ETIQUETA: Record<TipoEvento, string> = {
  alarma: "Alarma",
  vidrio: "Vidrio roto",
  golpe: "Golpe",
  grito: "Grito o llanto",
  tv: "TV o radio",
  rutina: "Rutina",
};

/** Los que pueden ser una emergencia. La TV y la rutina cuentan que la casa está viva. */
export const ES_ALERTA: Record<TipoEvento, boolean> = {
  alarma: true,
  vidrio: true,
  golpe: true,
  grito: true,
  tv: false,
  rutina: false,
};

export interface Categoria {
  categoryName: string;
  score: number;
}

export interface Evento {
  tipo: TipoEvento;
  clase: string;
  score: number;
}

/** Une los trozos que devuelve el clasificador quedándose con el puntaje más alto por clase. */
export function unirCategorias(trozos: Categoria[][]): Categoria[] {
  const max = new Map<string, number>();
  for (const trozo of trozos)
    for (const c of trozo) max.set(c.categoryName, Math.max(max.get(c.categoryName) ?? 0, c.score));
  return [...max]
    .map(([categoryName, score]) => ({ categoryName, score }))
    .sort((a, b) => b.score - a.score);
}

/** El evento más probable de la ventana, si alguna clase que nos importa pasa el umbral. */
export function eventoDe(categorias: Categoria[], umbral = 0.3): Evento | null {
  let mejor: Evento | null = null;
  for (const c of categorias) {
    const tipo = CLASES[c.categoryName];
    if (tipo && c.score >= umbral && (!mejor || c.score > mejor.score))
      mejor = { tipo, clase: c.categoryName, score: c.score };
  }
  return mejor;
}
