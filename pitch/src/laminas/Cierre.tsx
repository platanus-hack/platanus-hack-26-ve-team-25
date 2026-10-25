/**
 * Lámina 4 · Cierre
 * Frase grande, tres columnas con las propiedades clave, QR grande y gracias.
 * En esta lámina el QR chico fijo se oculta (controlado en App.tsx).
 * Grid de 3 filas: título (auto), columnas centradas (1fr), QR y gracias (auto).
 */
export default function Cierre() {
  return (
    <div
      style={{
        display: "grid",
        gridTemplateRows: "auto 1fr auto",
        height: "100%",
        textAlign: "center",
      }}
    >
      {/* Fila 1: titular centrado */}
      <div style={{ paddingTop: "2cqh" }}>
        <div
          style={{
            fontSize: "7.5cqh",
            fontWeight: 700,
            lineHeight: 1.05,
            color: "var(--tinta)",
            letterSpacing: "-0.03em",
            textWrap: "balance",
          }}
        >
          Oye. Pregunta. Avisa.
        </div>
      </div>

      {/* Fila 2: tres columnas centradas verticalmente, texto más grande */}
      <div
        style={{
          display: "grid",
          gridTemplateColumns: "repeat(3, 1fr)",
          gap: "6cqw",
          padding: "0 4cqw",
          placeContent: "center",
        }}
      >
        <div
          style={{
            textAlign: "center",
            fontSize: "2.4cqh",
            color: "var(--texto)",
            paddingTop: "1.5cqh",
            borderTop: "1px solid var(--linea)",
          }}
        >
          Todo el audio en el teléfono
        </div>
        <div
          style={{
            textAlign: "center",
            fontSize: "2.4cqh",
            color: "var(--texto)",
            paddingTop: "1.5cqh",
            borderTop: "1px solid var(--linea)",
          }}
        >
          60 segundos para contestar
        </div>
        <div
          style={{
            textAlign: "center",
            fontSize: "2.4cqh",
            color: "var(--texto)",
            paddingTop: "1.5cqh",
            borderTop: "1px solid var(--linea)",
          }}
        >
          Si la casa se cae, la base escala
        </div>
      </div>

      {/* Fila 3: QR grande + texto + gracias */}
      <div
        style={{
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          gap: "1.5cqh",
          paddingBottom: "2cqh",
        }}
      >
        <div
          style={{
            background: "#fff",
            border: "1px solid var(--borde)",
            borderRadius: "1.5cqh",
            padding: "1.5cqh",
            display: "inline-flex",
          }}
        >
          <img
            src="/qr-telegram.svg"
            alt="Código QR para ver la casa de Carmen en Telegram (@CasaAvisoBot)"
            style={{
              width: "16cqh",
              height: "16cqh",
              display: "block",
            }}
          />
        </div>
        <div
          style={{
            fontSize: "2cqh",
            color: "var(--texto)",
            fontWeight: 500,
          }}
        >
          Escanea y mira la casa de Carmen
        </div>
        <div
          style={{
            fontSize: "1.4cqh",
            color: "var(--gris)",
            marginTop: "0.5cqh",
          }}
        >
          Gracias · equipo 25
        </div>
      </div>
    </div>
  );
}
