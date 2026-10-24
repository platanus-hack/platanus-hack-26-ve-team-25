// Tope de lecturas de factura por casa. El token `demo` es público (es el del QR), así que sin
// esto cualquiera del público podría gastar los créditos de Claude subiendo fotos. Vive en la
// memoria de cada instancia de Vercel: con varias instancias no es exacto, pero acota el gasto.

export type Tope = { porMinuto: number; porHora: number };

export const TOPE_FACTURA: Tope = { porMinuto: 3, porHora: 20 };

const MINUTO = 60_000;
const HORA = 3_600_000;

/** Devuelve una función que dice si la clave puede usar una vez más, y si puede, lo anota. */
export function crearTope(tope: Tope): (clave: string, ahora: number) => boolean {
  const usos = new Map<string, number[]>();
  return (clave, ahora) => {
    const enLaHora = (usos.get(clave) ?? []).filter((t) => ahora - t < HORA);
    const enElMinuto = enLaHora.filter((t) => ahora - t < MINUTO).length;
    const puede = enElMinuto < tope.porMinuto && enLaHora.length < tope.porHora;
    if (puede) enLaHora.push(ahora);
    usos.set(clave, enLaHora);
    return puede;
  };
}
