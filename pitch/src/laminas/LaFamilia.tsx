import Marco from "../componentes/Marco";

/**
 * Lámina 4 · La familia
 * Izquierda: mockup del teléfono de la casa con la pregunta «¿Está bien?» y la cuenta de 60 s.
 * Derecha: página de la familia en estado de alerta (tarjeta roja con dos botones).
 *
 * El anillo de progreso SVG usa stroke-dasharray. Para un círculo de radio R,
 * la circunferencia es 2πR. Un 20 % de progreso deja 80 % vacío.
 */
const RADIO = 44;
const CIRC = 2 * Math.PI * RADIO;
const PROGRESO = 0.2; // 20 % congelado
const DASH = CIRC * PROGRESO;

export default function LaFamilia() {
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: "2cqh", height: "100%" }}>
      <img
        src="/presente-logo.svg"
        alt="Presente"
        className="portada-logo"
        width={918}
        height={180}
        style={{ alignSelf: "flex-start" }}
      />

      {/* Los dos paneles: teléfono (izq) y navegador (der), alineados al mismo centro vertical */}
      <div
        style={{
          display: "grid",
          gridTemplateColumns: "1fr 1.6fr",
          gap: "4cqw",
          flex: 1,
          minHeight: 0,
          alignItems: "center",
        }}
      >
        {/* Teléfono de la casa: proporción 9:19, vertical, centrado en su celda */}
        <div
          className="telefono"
          style={{
            width: "30cqh",
            height: "64cqh",
            borderRadius: "3cqh",
            border: "1px solid var(--borde)",
            background: "var(--superficie)",
            padding: "2.5cqh 2cqw",
            margin: "0 auto",
            justifyContent: "space-between",
            gap: "0",
          }}
        >
          <div className="telefono-reloj">16:24</div>
          <div className="telefono-pregunta" style={{ fontSize: "3.2cqh", whiteSpace: "nowrap" }}>¿Está bien?</div>
          <svg
            viewBox="0 0 100 100"
            aria-hidden="true"
            style={{ width: "14cqh", height: "14cqh", flex: "0 0 auto" }}
          >
            <circle
              cx={50}
              cy={50}
              r={RADIO}
              fill="none"
              stroke="var(--borde)"
              strokeWidth={4}
            />
            <circle
              cx={50}
              cy={50}
              r={RADIO}
              fill="none"
              stroke="var(--verde)"
              strokeWidth={4}
              strokeLinecap="round"
              strokeDasharray={`${DASH} ${CIRC - DASH}`}
              transform="rotate(-90 50 50)"
            />
            <text
              x={50}
              y={56}
              fontSize={18}
              fontWeight={700}
              textAnchor="middle"
              fill="var(--tinta)"
            >
              48 s
            </text>
          </svg>
          <div className="telefono-boton" style={{ paddingLeft: "calc(3.5cqw + 1cqw)" }}>
            <div className="telefono-riel" aria-hidden="true" />
            <span
              className="telefono-desliza"
              style={{
                position: "relative",
                zIndex: 1,
                fontSize: "1.45cqh",
                whiteSpace: "nowrap",
                overflow: "hidden",
              }}
            >
              Desliza si estás bien
            </span>
          </div>
        </div>

        {/* Marco del navegador centrado verticalmente en el mismo eje */}
        <div style={{ height: "64cqh", display: "flex", alignItems: "center" }}>
          <Marco url="platanus-hack-26-ve-team-25.vercel.app/f/carmen">
            <div style={{ padding: "2cqh 2cqw", display: "flex", flexDirection: "column", gap: "1.5cqh", height: "100%" }}>
              <div className="alerta">
                <div className="alerta-titulo">Carmen no responde</div>
                <div className="alerta-tiempo">1 min 12 s</div>
                <div className="alerta-botones">
                  <div className="alerta-boton solido">Llamar a Carmen</div>
                  <div className="alerta-boton borde">Llamar al vecino</div>
                </div>
              </div>
              <div className="alerta-estado">
                <span className="alerta-punto" />
                <span>Visto hace 4 s</span>
              </div>
            </div>
          </Marco>
        </div>
      </div>
    </div>
  );
}
