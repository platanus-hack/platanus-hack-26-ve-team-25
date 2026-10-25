/**
 * Lámina 4 · Cierre
 *
 * Una sola cosa: la pregunta que el producto hace todos los días, devuelta a quien mira.
 * El pitch abre acusando («¿Por qué esperar a que ocurra una emergencia?») y cierra con la
 * frase con la que la casa empieza cada conversación con el adulto mayor. Todo lo demás
 * —columnas, QR grande, gracias— se quitó a propósito: la pregunta sola, sin competencia.
 *
 * El QR de Telegram sigue apareciendo en la esquina superior derecha, porque ese es fijo en
 * todas las láminas (lo pinta App.tsx, no esta).
 */
export default function Cierre() {
  return (
    <div
      style={{
        display: "grid",
        placeItems: "center",
        height: "100%",
        textAlign: "center",
      }}
    >
      <div
        style={{
          fontSize: "22cqh",
          fontWeight: 700,
          lineHeight: 1,
          letterSpacing: "-0.04em",
          color: "var(--tinta)",
          textWrap: "balance",
        }}
      >
        ¿Está bien?
      </div>
    </div>
  );
}
