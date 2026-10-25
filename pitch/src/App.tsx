import { useCallback, useEffect, useState } from "react";
import Portada from "./laminas/Portada";
import ElQueSeQueda from "./laminas/ElQueSeQueda";
import LaFamilia from "./laminas/LaFamilia";
import Cierre from "./laminas/Cierre";
import QrTelegram from "./componentes/QrTelegram";
import BarraProgreso from "./componentes/BarraProgreso";

/** Número total de láminas */
const TOTAL_LAMINAS = 4;

/**
 * Lee el hash de la URL y devuelve el índice de la lámina (1-based).
 * Si el hash no es válido, devuelve 1.
 */
function leerHash(): number {
  const hash = window.location.hash.replace("#", "");
  const num = parseInt(hash, 10);
  if (Number.isInteger(num) && num >= 1 && num <= TOTAL_LAMINAS) {
    return num;
  }
  return 1;
}

export default function App() {
  const [actual, setActual] = useState<number>(leerHash);

  /** Cambia la lámina y actualiza el hash de la URL */
  const irA = useCallback((n: number) => {
    const siguiente = Math.max(1, Math.min(TOTAL_LAMINAS, n));
    setActual(siguiente);
    window.location.hash = `#${siguiente}`;
  }, []);

  const siguiente = useCallback(() => irA(actual + 1), [actual, irA]);
  const anterior = useCallback(() => irA(actual - 1), [actual, irA]);

  /** Sincroniza el hash cuando el usuario cambia la URL manualmente */
  useEffect(() => {
    const onHashChange = () => {
      setActual(leerHash());
    };
    window.addEventListener("hashchange", onHashChange);
    return () => window.removeEventListener("hashchange", onHashChange);
  }, []);

  /** Navegación por teclado y clic */
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      // Ignorar si el foco está en un input/textarea (no debería haber, pero por seguridad)
      const tag = (e.target as HTMLElement)?.tagName;
      if (tag === "INPUT" || tag === "TEXTAREA") return;

      switch (e.key) {
        case "ArrowRight":
        case " ":
        case "PageDown":
          e.preventDefault();
          siguiente();
          break;
        case "ArrowLeft":
        case "PageUp":
          e.preventDefault();
          anterior();
          break;
        case "Home":
          e.preventDefault();
          irA(1);
          break;
        case "End":
          e.preventDefault();
          irA(TOTAL_LAMINAS);
          break;
        case "f":
        case "F":
          e.preventDefault();
          toggleFullscreen();
          break;
        case "Escape":
          if (document.fullscreenElement) {
            document.exitFullscreen();
          }
          break;
      }
    };

    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [siguiente, anterior, irA]);

  /** Clic en la mitad izquierda o derecha de la pantalla */
  const handleClick = useCallback(
    (e: React.MouseEvent<HTMLDivElement>) => {
      const { left, width } = e.currentTarget.getBoundingClientRect();
      const x = e.clientX - left;
      if (x < width / 2) {
        anterior();
      } else {
        siguiente();
      }
    },
    [siguiente, anterior]
  );

  // Las láminas se renderizan todas, pero solo la activa es visible.
  // aria-hidden controla la accesibilidad.
  const laminas = [
    <Portada key="1" />,
    <ElQueSeQueda key="2" />,
    <LaFamilia key="3" />,
    <Cierre key="4" />,
  ];

  // En la lámina 4 (Cierre), el QR chico se oculta (se muestra uno grande dentro de la lámina)
  const mostrarQrFijo = actual !== 4;

  return (
    <div
      className="escenario"
      onClick={handleClick}
      role="region"
      aria-label="Presentación Presente"
    >
      {laminas.map((lamina, i) => (
        <section
          key={i + 1}
          className="lamina"
          aria-hidden={i + 1 !== actual}
          aria-label={`Lámina ${i + 1} de ${TOTAL_LAMINAS}`}
        >
          {lamina}
        </section>
      ))}

      {mostrarQrFijo && <QrTelegram />}

      <BarraProgreso actual={actual} total={TOTAL_LAMINAS} />
      <div className="contador">
        {actual} / {TOTAL_LAMINAS}
      </div>
    </div>
  );
}

/** Alterna pantalla completa (con fallback para navegadores antiguos) */
function toggleFullscreen() {
  if (document.fullscreenElement) {
    document.exitFullscreen();
  } else {
    const el = document.documentElement;
    if (el.requestFullscreen) {
      el.requestFullscreen();
    }
  }
}
