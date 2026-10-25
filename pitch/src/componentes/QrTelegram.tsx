/**
 * QR fijo en la esquina superior derecha (láminas 1 y 2).
 * El SVG lo genera scripts/qr.mjs en public/qr-telegram.svg.
 * El tamaño sale de `--qr-tamano` en globals.css: una sola variable para las dos láminas.
 */
export default function QrTelegram() {
  return (
    <div className="qr-fijo">
      <div className="qr-tarjeta">
        <img
          src="/qr-telegram.svg"
          alt="Código QR para unirse al bot de avisos de Presente en Telegram (@CasaAvisoBot)"
          width={160}
          height={160}
        />
      </div>
      <span className="qr-etiqueta">@CasaAvisoBot</span>
    </div>
  );
}
