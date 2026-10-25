import { useCallback, useEffect, useRef, useState } from "react";
import Marco from "../componentes/Marco";

/**
 * Lámina 3 · La familia
 * Izquierda: el teléfono de la casa. Por defecto es un mockup dibujado en CSS; con la tecla
 * `V` se le enchufa la ventana de scrcpy y entonces muestra la app de verdad, en vivo.
 * Derecha: página de la familia en estado de alerta (tarjeta roja con dos botones).
 *
 * El anillo de progreso SVG usa stroke-dasharray. Para un círculo de radio R,
 * la circunferencia es 2πR. Un 20 % de progreso deja 80 % vacío.
 */
/**
 * La página real de la familia, en estado de alerta. Se muestra dentro del marco para que la
 * lámina enseñe el producto y no un dibujo. Si en la tarima no hay internet, W vuelve al mockup.
 */
const URL_PAGINA = "https://platanus-hack-26-ve-team-25.vercel.app/f/demo?escenario=alerta";

const RADIO = 44;
const CIRC = 2 * Math.PI * RADIO;
const PROGRESO = 0.2; // 20 % congelado
const DASH = CIRC * PROGRESO;

interface Props {
  /** True cuando la lámina está en pantalla: solo entonces atiende la tecla V. */
  activa?: boolean;
}

export default function LaFamilia({ activa = false }: Props) {
  const videoRef = useRef<HTMLVideoElement>(null);
  const flujoRef = useRef<MediaStream | null>(null);
  const [vivo, setVivo] = useState(false);
  const [aviso, setAviso] = useState<string | null>(null);

  // Modo adb: un proceso local (npm run vivo) sirve la pantalla del teléfono por HTTP.
  const [porAdb, setPorAdb] = useState(false);
  const [tick, setTick] = useState(0);

  // La página de la familia, de verdad, dentro del marco. Se puede apagar con W.
  const [paginaReal, setPaginaReal] = useState(true);

  /** Suelta la ventana capturada y vuelve al mockup. */
  const soltar = useCallback(() => {
    flujoRef.current?.getTracks().forEach((pista) => pista.stop());
    flujoRef.current = null;
    if (videoRef.current) videoRef.current.srcObject = null;
    setVivo(false);
  }, []);

  /** Pide al navegador que capture una ventana (la de scrcpy). */
  const tomar = useCallback(async () => {
    setAviso(null);
    if (!navigator.mediaDevices?.getDisplayMedia) {
      setAviso("Este navegador no deja capturar ventanas.");
      return;
    }
    try {
      const flujo = await navigator.mediaDevices.getDisplayMedia({
        video: { frameRate: 30 },
        audio: false,
      });
      flujo.getVideoTracks()[0]?.addEventListener("ended", soltar);
      flujoRef.current = flujo;
      setVivo(true);
    } catch {
      // Cancelar el selector también entra aquí: no es un error que haya que gritar.
      setAviso("No se eligió ninguna ventana.");
    }
  }, [soltar]);

  // Refresco de la imagen de adb: cambia el ?t= para que el navegador no use la caché.
  useEffect(() => {
    if (!porAdb) return;
    const id = setInterval(() => setTick((t) => t + 1), 800);
    return () => clearInterval(id);
  }, [porAdb]);

  // El <video> no existe hasta que `vivo` es true: el flujo se enchufa justo después.
  useEffect(() => {
    if (!vivo || !videoRef.current || !flujoRef.current) return;
    videoRef.current.srcObject = flujoRef.current;
    videoRef.current.play().catch(() => setAviso("El navegador no dejó reproducir la ventana."));
  }, [vivo]);

  // Si la lámina se desmonta, no queda una captura de pantalla viva por ahí.
  useEffect(() => () => soltar(), [soltar]);

  useEffect(() => {
    if (!activa) return;
    const alPulsar = (e: KeyboardEvent) => {
      const tecla = e.key.toLowerCase();
      if (tecla === "v") {
        e.preventDefault();
        setPorAdb(false);
        if (vivo) {
          soltar();
        } else {
          void tomar();
        }
      } else if (tecla === "w") {
        e.preventDefault();
        setPaginaReal((antes) => !antes);
      } else if (tecla === "a") {
        e.preventDefault();
        // Los dos modos son excluyentes: si había ventana capturada, se suelta.
        if (vivo) soltar();
        setAviso(null);
        setPorAdb((antes) => !antes);
      }
    };
    window.addEventListener("keydown", alPulsar);
    return () => window.removeEventListener("keydown", alPulsar);
  }, [activa, vivo, soltar, tomar]);

  return (
    <div style={{ display: "flex", flexDirection: "column", height: "100%", position: "relative" }}>
      <img
        src="/presente-logo.svg"
        alt="Presente"
        className="portada-logo"
        width={918}
        height={180}
        style={{ position: "absolute", top: 0, left: 0, height: "6.5cqh", zIndex: 2 }}
      />

      {/* Los dos paneles: teléfono (izq) y navegador (der), alineados al mismo centro vertical */}
      <div
        style={{
          display: "grid",
          gridTemplateColumns: "1.12fr 0.88fr",
          gap: "3cqw",
          flex: 1,
          minHeight: 0,
          alignItems: "stretch",
        }}
      >
        {/* Teléfono de la casa: proporción 9:19, vertical, centrado en su celda */}
        <div style={{ display: "grid", justifyItems: "center", alignContent: "center", gap: "1.4cqh" }}>
          <div
            className="telefono"
            style={{
              // El teléfono va de lado, como en la mesa: el ancho manda y el alto sale solo.
              width: "100%",
              aspectRatio: "19 / 9",
              borderRadius: "2.6cqh",
              border: "1px solid var(--borde)",
              background: "var(--superficie)",
              // En vivo manda el video a sangre; si no, el mockup con su respiración.
              padding: vivo || porAdb ? "0" : "2.8cqh 2cqw",
              justifyContent: vivo || porAdb ? "center" : "space-between",
              gap: "0",
              overflow: "hidden",
              position: "relative",
            }}
          >
            {porAdb ? (
              <>
                <img
                  src={`http://localhost:8765/telefono.png?t=${tick}`}
                  alt="Pantalla del teléfono de la casa, en vivo"
                  className="telefono-vivo"
                  onError={() => setAviso("No responde localhost:8765. ¿Está corriendo `npm run vivo`?")}
                />
                <span className="telefono-en-vivo">EN VIVO</span>
              </>
            ) : vivo ? (
              <>
                <video ref={videoRef} muted playsInline autoPlay className="telefono-vivo" />
                <span className="telefono-en-vivo">EN VIVO</span>
              </>
            ) : (
              <>
                <div className="telefono-fila">
                  <div className="telefono-dicho">
                    <div className="telefono-reloj">16:24</div>
                    <div className="telefono-pregunta" style={{ whiteSpace: "nowrap" }}>
                      ¿Está bien?
                    </div>
                  </div>
                  <svg
                    viewBox="0 0 100 100"
                    aria-hidden="true"
                    style={{ width: "14cqh", height: "14cqh", flex: "0 0 auto" }}
                  >
                    <circle cx={50} cy={50} r={RADIO} fill="none" stroke="var(--borde)" strokeWidth={4} />
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
                </div>
                <div className="telefono-boton" style={{ paddingLeft: "calc(4.4cqw + 1.2cqw)" }}>
                  <div className="telefono-riel" aria-hidden="true" />
                  <span
                    className="telefono-desliza"
                    style={{
                      position: "relative",
                      zIndex: 1,
                      fontSize: "1.7cqh",
                      whiteSpace: "nowrap",
                      overflow: "hidden",
                    }}
                  >
                    Desliza si estás bien
                  </span>
                </div>
              </>
            )}
          </div>

          {/* Pista solo para quien presenta: no aparece si la lámina no está en pantalla */}
          {activa && (
            <div className="pista-vivo">
              {aviso ??
                (porAdb
                  ? "A para soltar el teléfono"
                  : vivo
                    ? "V para soltar la ventana"
                    : "V ventana · A teléfono · W página")}
            </div>
          )}
        </div>

        {/* Marco del navegador centrado verticalmente en el mismo eje */}
        <div style={{ height: "100%", display: "flex" }}>
          <Marco
            url={
              paginaReal
                ? "platanus-hack-26-ve-team-25.vercel.app/f/demo?escenario=alerta"
                : "platanus-hack-26-ve-team-25.vercel.app/f/carmen"
            }
          >
            {paginaReal ? (
              <iframe
                src={URL_PAGINA}
                title="Página de la familia de la casa de Carmen, en estado de alerta"
                className="marco-pagina"
                referrerPolicy="no-referrer"
              />
            ) : (
            <div
              style={{
                padding: "2cqh 2cqw",
                display: "flex",
                flexDirection: "column",
                gap: "1.5cqh",
                height: "100%",
              }}
            >
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
            )}
          </Marco>
        </div>
      </div>
    </div>
  );
}
