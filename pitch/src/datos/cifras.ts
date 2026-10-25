/**
 * Todas las cifras del deck, tipadas y con fuente.
 * Los componentes las consumen directamente: nada de números mágicos en el JSX.
 */

/** Cifra de contexto (KPI de la lámina 2) */
export interface Cifra {
  valor: string;
  /** Etiqueta corta que explica qué mide */
  etiqueta: string;
  /** Si true, el número va en tinta; si no, en verde */
  tinta?: boolean;
}

export const cifrasContexto: readonly Cifra[] = [
  {
    valor: "7,89 M",
    etiqueta: "de venezolanos en el exterior",
  },
  {
    valor: "400 000+",
    etiqueta: "adultos mayores viven solos",
  },
  {
    valor: "31 M+",
    etiqueta: "de adultos mayores están solos en el mundo",
    tinta: true,
  },
  {
    valor: "1 de 3",
    etiqueta: "sufre una caída cada año",
    tinta: true,
  },
] as const;

/* La serie de la migración (2015–2024) se quitó junto con la gráfica de la lámina 2;
   si vuelve a hacer falta, está en el historial de git. */

/* Las fuentes de las cuatro cifras ya no se pintan en la lámina: están anotadas en el
   README de `pitch/`, para tenerlas a mano si el jurado pregunta. */
