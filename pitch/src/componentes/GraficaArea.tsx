import { migracion } from "../datos/cifras";

/**
 * Gráfica de área de la migración venezolana 2015–2024.
 *
 * ViewBox: 520×200, más ancho que alto porque en la lámina convive con los KPIs y con la
 * foto: si fuera más cuadrada, `meet` la dejaría con franjas vacías a los lados.
 *
 * Márgenes reservados para etiquetas:
 *   - izq 0 (la gráfica arranca en el mismo eje vertical que el titular y los KPI; las
 *     cifras del eje y van dentro del área, encima de cada línea de rejilla)
 *   - der 16
 *   - arriba 18 (para la etiqueta del punto más alto)
 *   - abajo 26 (años)
 *
 * El eje y va de 0 a 8 millones. Cada punto se mapea:
 *   x = izq + (i / (n-1)) * ancho
 *   y = arriba + alto - (valor / 8) * alto
 *
 * El área se rellena bajo la línea con verde claro y la línea en verde.
 * El primer y último punto se etiquetan con su valor.
 */
const VIEW_W = 520;
const VIEW_H = 200;
const PAD = { izq: 0, der: 16, arriba: 18, abajo: 26 };
const Y_MAX = 8; // millones, deja aire sobre el 7,89

function formatoMillones(v: number): string {
  // El spec muestra "0,7 M" y "7,89 M": redondeamos a 1 decimal si es < 1, si no mantenemos 2.
  if (v < 1) {
    return v.toFixed(1).replace(".", ",");
  }
  return v.toString().replace(".", ",");
}

export default function GraficaArea() {
  const n = migracion.length;
  if (n === 0) return null;

  const w = VIEW_W - PAD.izq - PAD.der;
  const h = VIEW_H - PAD.arriba - PAD.abajo;

  // Construimos los puntos: [x, y] para cada año
  const puntos: [number, number][] = migracion.map((d, i) => {
    const x = PAD.izq + (i / (n - 1)) * w;
    const y = PAD.arriba + h - (d.millones / Y_MAX) * h;
    return [x, y];
  });

  // Path de la línea
  const linea = puntos.map((p, i) => `${i === 0 ? "M" : "L"}${p[0].toFixed(1)},${p[1].toFixed(1)}`).join(" ");

  // Path del área: línea + cierra abajo a la derecha y abajo a la izquierda
  // Como ya verificamos n > 0, primero y último existen.
  const primero = puntos[0];
  const ultimo = puntos[puntos.length - 1];
  if (!primero || !ultimo) return null;

  const area =
    `${linea} L${ultimo[0].toFixed(1)},${(PAD.arriba + h).toFixed(1)} ` +
    `L${primero[0].toFixed(1)},${(PAD.arriba + h).toFixed(1)} Z`;

  // Etiquetas del eje Y. El cero no se rotula: la base de la gráfica ya es cero y el
  // "0,7 M" del primer punto lo dice sin repetirlo.
  const marcasY = [2, 4, 6, 8];

  // Primer y último punto para etiquetar
  const primeroPunto = migracion[0];
  const ultimoPunto = migracion[n - 1];
  if (!primeroPunto || !ultimoPunto) return null;

  const [primerX, primerY] = primero;
  const [ultimoX, ultimoY] = ultimo;

  return (
    <svg
      viewBox={`0 0 ${VIEW_W} ${VIEW_H}`}
      preserveAspectRatio="xMinYMid meet"
      role="img"
      aria-label={`Migración venezolana de ${primeroPunto.millones} millones en ${primeroPunto.ano} a ${ultimoPunto.millones} millones en ${ultimoPunto.ano}`}
    >
      {/* Líneas horizontales de rejilla */}
      {marcasY.map((m) => {
        const y = PAD.arriba + h - (m / Y_MAX) * h;
        return (
          <line
            key={m}
            x1={PAD.izq}
            x2={VIEW_W - PAD.der}
            y1={y}
            y2={y}
            stroke="#232320"
            strokeWidth={1}
          />
        );
      })}

      {/* Etiquetas eje Y: dentro del área, encima de cada línea de rejilla, para que la
          gráfica arranque en el mismo eje vertical que el titular y los KPI */}
      {marcasY.map((m) => {
        const y = PAD.arriba + h - (m / Y_MAX) * h;
        return (
          <text
            key={`l-${m}`}
            x={PAD.izq + 3}
            y={y - 5}
            fontSize={9}
            textAnchor="start"
            fill="#85857c"
          >
            {m}
          </text>
        );
      })}

      {/* Área */}
      <path d={area} fill="rgba(126, 226, 168, 0.14)" />

      {/* Línea */}
      <path d={linea} fill="none" stroke="#7ee2a8" strokeWidth={2} />

      {/* Etiquetas del primer y último punto */}
      <text x={primerX + 4} y={primerY + 10} fontSize={11} fontWeight={600} fill="#7ee2a8">
        {formatoMillones(primeroPunto.millones)} M
      </text>
      <text x={ultimoX - 4} y={ultimoY - 8} fontSize={12} fontWeight={700} fill="#7ee2a8" textAnchor="end">
        {formatoMillones(ultimoPunto.millones)} M
      </text>

      {/* Puntos */}
      <circle cx={primerX} cy={primerY} r={2.5} fill="#7ee2a8" />
      <circle cx={ultimoX} cy={ultimoY} r={3} fill="#7ee2a8" />

      {/* Eje X: años (primer, medio, último). El primero se alinea a la izquierda y el
          último a la derecha para que no se salgan por los bordes ahora que la gráfica
          arranca en el margen del texto. */}
      {[0, Math.floor((n - 1) / 2), n - 1].map((i) => {
        const d = migracion[i];
        const p = puntos[i];
        if (!d || !p) return null;
        const [x] = p;
        const ancla = i === 0 ? "start" : i === n - 1 ? "end" : "middle";
        return (
          <text
            key={`a-${i}`}
            x={x}
            y={PAD.arriba + h + 16}
            fontSize={10}
            textAnchor={ancla}
            fill="#85857c"
          >
            {d.ano}
          </text>
        );
      })}
    </svg>
  );
}
