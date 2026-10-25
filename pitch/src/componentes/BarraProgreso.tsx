/**
 * Barra de progreso segmentada (no puntos).
 * Cada segmento representa una lámina:
 *  - pasado: ya mostrada
 *  - activo: lámina actual (verde)
 *  - pendiente: aún no mostrada (gris claro)
 */
interface Props {
  actual: number;
  total: number;
}

export default function BarraProgreso({ actual, total }: Props) {
  const segmentos: ("pasado" | "activo" | "pendiente")[] = [];
  for (let i = 1; i <= total; i++) {
    if (i < actual) segmentos.push("pasado");
    else if (i === actual) segmentos.push("activo");
    else segmentos.push("pendiente");
  }

  return (
    <div className="barra-progreso" aria-hidden="true">
      {segmentos.map((estado, i) => (
        <div
          key={i}
          className={`barra-segmento ${estado === "activo" ? "activo" : estado === "pasado" ? "pasado" : ""}`}
        />
      ))}
    </div>
  );
}
