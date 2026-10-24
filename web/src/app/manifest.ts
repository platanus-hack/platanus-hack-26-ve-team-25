import type { MetadataRoute } from "next";
import { APP } from "@/lib/app";

// Lo que necesita el navegador para ofrecer «Agregar a la pantalla de inicio» y abrir la web
// de la familia como una app, sin barra del navegador. Sin tienda y sin instalar nada.
export default function manifest(): MetadataRoute.Manifest {
  return {
    name: APP.nombre,
    short_name: APP.nombreCorto,
    description: APP.descripcion,
    lang: "es",
    start_url: "/",
    scope: "/",
    display: "standalone",
    orientation: "portrait",
    background_color: APP.colorFondo,
    theme_color: APP.colorTema,
    icons: [
      { src: "/icono-192.png", sizes: "192x192", type: "image/png", purpose: "any" },
      { src: "/icono-512.png", sizes: "512x512", type: "image/png", purpose: "any" },
      // Con margen extra: Android recorta estos íconos en círculo o en gota
      { src: "/icono-maskable-512.png", sizes: "512x512", type: "image/png", purpose: "maskable" },
    ],
  };
}
