// Nivel de sonido y compuerta barata: corren siempre, antes del modelo.

/** Nivel RMS de un bloque en dBFS: 0 es el máximo digital, el silencio queda cerca de -100. */
export function rmsDb(bloque: Float32Array): number {
  let suma = 0;
  for (let i = 0; i < bloque.length; i++) suma += bloque[i] * bloque[i];
  const rms = Math.sqrt(suma / Math.max(1, bloque.length));
  return 20 * Math.log10(Math.max(rms, 1e-5));
}

/**
 * El ruido de fondo de la casa. Sigue al nivel con un promedio lento y casi no se deja
 * arrastrar por los picos: un golpe no sube el fondo, pero una TV que se queda prendida sí,
 * poco a poco.
 */
export class LineaBase {
  private valor: number | null = null;

  constructor(
    private readonly alfa = 0.02,
    private readonly alfaPico = 0.002,
    private readonly margenPicoDb = 6,
  ) {}

  actualizar(db: number): number {
    if (this.valor === null) {
      this.valor = db;
    } else {
      const esPico = db > this.valor + this.margenPicoDb;
      this.valor += (esPico ? this.alfaPico : this.alfa) * (db - this.valor);
    }
    return this.valor;
  }

  get actual(): number {
    return this.valor ?? -100;
  }
}

/** Se abre cuando el nivel salta `umbralDb` sobre el fondo y se sostiene `sostenMs`. */
export class Compuerta {
  private abiertaHasta = 0;

  constructor(
    private readonly umbralDb = 15,
    private readonly sostenMs = 1500,
  ) {}

  evaluar(db: number, fondo: number, ahoraMs: number): boolean {
    if (db - fondo >= this.umbralDb) this.abiertaHasta = ahoraMs + this.sostenMs;
    return ahoraMs < this.abiertaHasta;
  }
}
