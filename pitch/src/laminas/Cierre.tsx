/**
 * Lámina 4 · Cierre
 *
 * Una sola cosa: una pregunta dirigida a quien mira, no al producto, y debajo el QR para
 * instalarse la app.
 *
 * El pitch abre acusando («¿Por qué esperar a que ocurra una emergencia?») y cierra preguntando
 * cuánto tarda él en enterarse. Eso es lo que compra el cliente: no un aparato ni un modelo de
 * audio, tiempo. Los 47 minutos, los 60 segundos y el Telegram que llega caben en esa pregunta.
 *
 * `QR_descarga_app.jpeg` lleva a la prueba interna de Play Store (`com.abrahan.presente`).
 */
export default function Cierre() {
  return (
    <div
      style={{
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "center",
        gap: "4cqh",
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
          color: "var(--tinta)",
          maxWidth: "92%",
        }}
      >
        ¿Cuánto tardarías
        <br />
        en enterarte?
      </div>

      <div
        style={{
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          gap: "1.8cqh",
        }}
      >
        <div className="qr-descarga">
          <img
            src="/QR_descarga_app.jpeg"
            alt="Código QR para instalar la app de Presente en el teléfono"
            width={300}
            height={300}
          />
        </div>
        <div className="qr-descarga-texto">Descarga aquí</div>
      </div>
    </div>
  );
}
