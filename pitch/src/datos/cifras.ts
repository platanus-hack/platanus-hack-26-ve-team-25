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

/** Serie de la migración venezolana 2015–2024 (en millones). Fuente: ACNUR/R4V, 2024 */
export const migracion: readonly { ano: number; millones: number }[] = [
  { ano: 2015, millones: 0.695 },
  { ano: 2016, millones: 1.0 },
  { ano: 2017, millones: 1.6 },
  { ano: 2018, millones: 2.6 },
  { ano: 2019, millones: 3.93 },
  { ano: 2020, millones: 5.4 },
  { ano: 2021, millones: 6.0 },
  { ano: 2022, millones: 7.1 },
  { ano: 2023, millones: 7.7 },
  { ano: 2024, millones: 7.89 },
] as const;

/* Las series de tiemposAviso y accidentes se eliminaron: ya no se usan en el deck. */
