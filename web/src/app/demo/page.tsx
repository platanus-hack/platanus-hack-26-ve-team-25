import type { Metadata } from "next";
import { headers } from "next/headers";
import Link from "next/link";
import QRCode from "qrcode";
import { APP } from "@/lib/app";
import { TOKEN_DEMO } from "@/lib/familia/datos";
import { atkinson } from "@/lib/fuentes";
import { ESCENARIOS } from "@/lib/familia/simulado";

export const metadata: Metadata = { title: `Demo · ${APP.nombreCorto}` };

// El QR gigante del pitch: el público lo escanea desde las sillas y entra como familia de la casa
// de demo. Se arma con el dominio desde el que se abrió, así sirve igual en local y en Vercel.
export default async function Page() {
  const h = await headers();
  const host = h.get("x-forwarded-host") ?? h.get("host") ?? "localhost:3000";
  const proto = h.get("x-forwarded-proto") ?? (host.startsWith("localhost") ? "http" : "https");
  const destino = `${proto}://${host}/f/${TOKEN_DEMO}/bienvenida`;
  const qr = await QRCode.toString(destino, {
    type: "svg",
    margin: 1,
    errorCorrectionLevel: "M",
    color: { dark: "#14532d", light: "#ffffff" },
  });

  return (
    <main
      className={`${atkinson.className} flex min-h-dvh flex-col items-center justify-center gap-8 bg-papel px-6 py-10 text-tinta`}
    >
      <h1 className="text-center text-4xl font-bold md:text-6xl">Cuida la casa de Carmen</h1>
      <div
        className="w-full max-w-[min(80vh,640px)] rounded-3xl bg-white p-4 shadow-sm [&>svg]:h-auto [&>svg]:w-full"
        // El SVG lo genera la librería a partir de nuestra URL: no hay texto del usuario adentro.
        dangerouslySetInnerHTML={{ __html: qr }}
      />
      <p className="text-center text-xl text-texto md:text-2xl">
        Escanéalo con la cámara. Sin instalar nada ni crear cuenta.
      </p>
      <nav className="flex flex-wrap justify-center gap-3 text-base text-gris" aria-label="Escenarios">
        {ESCENARIOS.map((e) => (
          <Link key={e} href={`/f/${TOKEN_DEMO}?escenario=${e}`} className="underline underline-offset-4">
            {e}
          </Link>
        ))}
      </nav>
    </main>
  );
}
