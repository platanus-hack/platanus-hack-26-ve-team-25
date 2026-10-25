/**
 * Lámina 4 · Cierre
 *
 * Una sola cosa: una pregunta dirigida a quien mira, no al producto.
 *
 * El pitch abre acusando («¿Por qué esperar a que ocurra una emergencia?») y cierra preguntando
 * cuánto tarda él en enterarse. Eso es lo que compra el cliente: no un aparato ni un modelo de
 * audio, tiempo. Los 47 minutos, los 60 segundos y el Telegram que llega caben en esa pregunta.
 * Todo lo demás —columnas, QR grande, gracias— se quitó a propósito.
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
          fontSize: "14cqh",
          fontWeight: 700,
          lineHeight: 1.05,
          letterSpacing: "-0.04em",
          maxWidth: "92%",
          color: "var(--tinta)",
          textWrap: "balance",
        }}
      >
        ¿Cuánto tardarías
        <br />
        en enterarte?
      </div>
    </div>
  );
}
