import type { ReactNode } from "react";

/**
 * Marco de navegador para emular la página de la familia (lámina 4).
 * Barra superior con tres puntos (estilo macOS) y la URL.
 */
interface Props {
  url: string;
  children: ReactNode;
}

export default function Marco({ url, children }: Props) {
  return (
    <div className="marco">
      <div className="marco-barra">
        <div className="marco-puntos" aria-hidden="true">
          <span className="marco-punto" />
          <span className="marco-punto" />
          <span className="marco-punto" />
        </div>
        <div className="marco-url">{url}</div>
      </div>
      <div className="marco-contenido">{children}</div>
    </div>
  );
}
