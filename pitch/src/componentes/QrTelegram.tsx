/**
 * QR fijo en la esquina superior derecha (todas las láminas menos Cierre).
 * El SVG lo genera scripts/qr.mjs en public/qr-telegram.svg.
 */
export default function QrTelegram() {
  return (
    <div className="qr-fijo">
      <div className="qr-tarjeta">
        <img
          src="/qr-telegram.svg"
          alt="Código QR para unirse al bot de avisos de En Casa en Telegram (@CasaAvisoBot)"
          width={160}
          height={160}
        />
      </div>
      <span className="qr-etiqueta">@CasaAvisoBot</span>
    </div>
  );
}
