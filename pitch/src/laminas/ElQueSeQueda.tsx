import GraficaArea from "../componentes/GraficaArea";
import { cifrasContexto } from "../datos/cifras";

/**
 * Lámina 2 · El que se queda (fusionada con Los números)
 * Columna derecha: foto a sangre con fundido.
 * Columna izquierda: titular, 4 KPIs en grid 2×2, gráfica de migración.
 */
export default function ElQueSeQueda() {
  return (
    <>
      <img
        src="/foto-senor.jpg"
        alt="Adulto mayor mirando por la ventana"
        className="foto-sangre"
      />
      <div
        style={{
          position: "relative",
          zIndex: 1,
          flex: 1,
          // La foto ocupa 70.15cqh de ancho (su alto por su proporción 0.7015). El texto se
          // detiene antes de esa orilla, más el padding de la lámina y un respiro:
          // 100cqw − 70.15cqh (foto) − 6cqw (padding derecho) − 2cqw (respiro).
          maxWidth: "calc(100cqw - 70.15cqh - 8cqw)",
          display: "flex",
          flexDirection: "column",
          gap: "2.6cqh",
          minHeight: 0,
        }}
      >
        {/* Titular */}
        <h2
          style={{
            fontSize: "5.5cqh",
            fontWeight: 700,
            lineHeight: 1.05,
            color: "var(--tinta)",
            textWrap: "balance",
            textAlign: "center",
            letterSpacing: "-0.02em",
            margin: 0,
          }}
        >
          El que se queda, se queda solo
        </h2>

        {/* KPIs en grid 2×2 */}
        <div className="kpi-lista">
          {cifrasContexto.map((c, i) => (
            <div key={i} className="kpi">
              <div className={`kpi-numero ${c.tinta ? "tinta" : ""}`}>{c.valor}</div>
              <div className="kpi-etiqueta">{c.etiqueta}</div>
              <div className="kpi-fuente">{c.fuente}</div>
            </div>
          ))}
        </div>

        {/* Gráfica de migración: se queda con todo el alto que sobre, sin desbordar */}
        <div className="grafica" style={{ flex: 1, minHeight: 0 }}>
          <GraficaArea />
          <div
            style={{
              fontSize: "1.1cqh",
              color: "var(--gris)",
              textAlign: "center",
            }}
          >
            ACNUR/R4V, 2024
          </div>
        </div>
      </div>
    </>
  );
}
