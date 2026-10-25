/**
 * Todas las cifras del deck, tipadas y con fuente.
 * Los componentes las consumen directamente: nada de números mágicos en el JSX.
 */

/** Cifra de contexto (KPI de la lámina 2) */
export interface Cifra {
  valor: string;
  /** Etiqueta corta que explica qué mide */
  etiqueta: string;
  /** Fuente de donde se sacó */
  fuente: string;
  /** Si true, el número va en tinta; si no, en verde */
  tinta?: boolean;
}

export const cifrasContexto: readonly Cifra[] = [
  {
    valor: "7,89 M",
    etiqueta: "de venezolanos en el exterior",
    fuente: "ACNUR/R4V, 2024",
  },
  {
    valor: "400 000+",
    etiqueta: "adultos mayores viven solos",
    fuente: "Convite AC/ENCOVI, 2023",
  },
  {
    valor: "31 M+",
    etiqueta: "de adultos mayores están solos en el mundo",
    fuente: "Diásporas juveniles · HelpAge/OIM",
    tinta: true,
  },
  {
    valor: "1 de 3",
    etiqueta: "sufre una caída cada año",
    fuente: "OMS, 2022",
    tinta: true,
  },
] as const;

/* La serie de la migración (2015–2024) se quitó junto con la gráfica de la lámina 2;
   si vuelve a hacer falta, está en el historial de git. */
