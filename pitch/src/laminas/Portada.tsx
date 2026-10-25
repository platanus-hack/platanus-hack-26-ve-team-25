/**
 * Lámina 1 · Portada
 * Wordmark "Presente" arriba a la izquierda, la pregunta como único titular
 * y pie con el equipo abajo. Sin bajada: la pregunta se explica sola.
 */
export default function Portada() {
  return (
    <div className="portada">
      <div className="portada-arriba">
        <img
          src="/presente-logo.svg"
          alt="Presente"
          className="portada-logo"
          width={918}
          height={180}
        />
      </div>
      <div className="portada-medio">
        <h1 className="titular" style={{ fontSize: "10cqh", textAlign: "center" }}>
          ¿Por qué esperar a que ocurra una emergencia?
        </h1>
      </div>
      <div className="portada-abajo">
        <div className="portada-pie">Equipo 25 · Platanus Hack 26 · Caracas</div>
      </div>
    </div>
  );
}
