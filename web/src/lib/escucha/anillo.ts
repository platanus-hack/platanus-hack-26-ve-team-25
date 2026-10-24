/**
 * Los últimos segundos de audio, en memoria. Se pisa a sí mismo: el audio nunca se guarda
 * ni se envía, solo sirve para clasificar también lo que sonó justo antes del disparo.
 */
export class Anillo {
  private readonly datos: Float32Array;
  private pos = 0;
  private lleno = false;

  constructor(capacidad: number) {
    this.datos = new Float32Array(Math.max(1, Math.floor(capacidad)));
  }

  escribir(bloque: Float32Array): void {
    for (let i = 0; i < bloque.length; i++) {
      this.datos[this.pos] = bloque[i];
      this.pos = (this.pos + 1) % this.datos.length;
      if (this.pos === 0) this.lleno = true;
    }
  }

  /** Copia de las últimas `n` muestras, de la más vieja a la más nueva. */
  ultimas(n: number): Float32Array {
    const disponibles = this.lleno ? this.datos.length : this.pos;
    const m = Math.min(Math.max(0, Math.floor(n)), disponibles);
    const salida = new Float32Array(m);
    const inicio = (this.pos - m + this.datos.length) % this.datos.length;
    for (let i = 0; i < m; i++) salida[i] = this.datos[(inicio + i) % this.datos.length];
    return salida;
  }
}
