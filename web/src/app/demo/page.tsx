import type { Metadata } from "next";
import { headers } from "next/headers";
import Link from "next/link";
import QRCode from "qrcode";
import { APP } from "@/lib/app";
import { TOKEN_DEMO } from "@/lib/familia/datos";
import { atkinson } from "@/lib/fuentes";
import { ESCENARIOS } from "@/lib/familia/simulado";

export const metadata: Metadata = { title: `Demo · ${APP.nombreCorto}` };

// Dos QR para la tarima:
//   1. El grande, el de Telegram: el público lo escanea, pulsa «Iniciar» y queda suscrito a los
//      avisos de verdad. El token de la casa viaja dentro del enlace (`?start=demo`).
//   2. El chico, el del panel: para quien quiera mirar cómo está Carmen sin suscribirse.
// Si `NEXT_PUBLIC_TELEGRAM_BOT` no está definido, queda solo el del panel, como antes.
const ESTILO = {
  type: "svg" as const,
  margin: 1,
  errorCorrectionLevel: "M" as const,
  color: { dark: "#14532d", light: "#ffffff" },
};

export default async function Page() {
  const h = await headers();
  const host = h.get("x-forwarded-host") ?? h.get("host") ?? "localhost:3000";
  const proto = h.get("x-forwarded-proto") ?? (host.startsWith("localhost") ? "http" : "https");

  const panel = `${proto}://${host}/f/${TOKEN_DEMO}/bienvenida`;
  const bot = process.env.NEXT_PUBLIC_TELEGRAM_BOT;
  const telegram = bot ? `https://t.me/${bot}?start=${TOKEN_DEMO}` : null;

  const qrTelegram = telegram ? await QRCode.toString(telegram, ESTILO) : null;
  const qrPanel = await QRCode.toString(panel, { ...ESTILO, errorCorrectionLevel: "L" as const });

  return (
    <main
      className={`${atkinson.className} flex min-h-dvh flex-col items-center justify-center gap-10 bg-papel px-6 py-10 text-tinta`}
    >
      <h1 className="text-center text-4xl font-bold md:text-6xl">Cuida la casa de Carmen</h1>

      {qrTelegram && telegram ? (
        <section className="flex w-full max-w-[min(70vh,560px)] flex-col items-center gap-4">
          <h2 className="text-center text-2xl font-bold md:text-3xl">Recibe los avisos</h2>
          <div
            className="w-full rounded-3xl bg-white p-4 shadow-sm [&>svg]:h-auto [&>svg]:w-full"
            // El SVG lo genera la librería a partir de nuestra URL: no hay texto del usuario adentro.
            dangerouslySetInnerHTML={{ __html: qrTelegram }}
          />
          <p className="text-center text-xl text-texto md:text-2xl">
            Escanéalo y pulsa <strong>Iniciar</strong>. Los avisos te llegan a Telegram.
          </p>
          <p className="text-center font-mono text-sm break-all text-gris md:text-base">{telegram}</p>
        </section>
      ) : null}

      <section className="flex w-full max-w-[min(40vh,300px)] flex-col items-center gap-3">
        <h2 className="text-center text-lg font-bold text-gris">
          {qrTelegram ? 'O mira cómo está, sin suscribirte' : 'Cuida la casa de Carmen'}
        </h2>
        <div
          className="w-full rounded-2xl bg-white p-3 shadow-sm [&>svg]:h-auto [&>svg]:w-full"
          dangerouslySetInnerHTML={{ __html: qrPanel }}
        />
        <p className="text-center text-base text-gris break-all font-mono">{panel}</p>
      </section>

      <p className="max-w-2xl text-center text-lg text-texto md:text-xl">
        Sin instalar nada ni crear cuenta. El audio se analiza en el teléfono de la casa y nunca
        sale de ahí.
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
