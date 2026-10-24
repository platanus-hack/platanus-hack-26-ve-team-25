import type { Metadata } from "next";
import { headers } from "next/headers";
import Link from "next/link";
import QRCode from "qrcode";
import { Marca } from "@/components/familia/marca";
import { APP } from "@/lib/app";
import { TOKEN_DEMO } from "@/lib/familia/datos";
import { ESCENARIOS, type Escenario } from "@/lib/familia/simulado";

export const metadata: Metadata = { title: `Demo · ${APP.nombreCorto}` };

// Dos QR para la tarima:
//   1. El grande, el de Telegram: el público lo escanea, pulsa «Iniciar» y queda suscrito a los
//      avisos de verdad. El token de la casa viaja dentro del enlace (`?start=demo`).
//   2. El chico, el del panel: para quien quiera mirar cómo está Carmen sin suscribirse.
// Si `NEXT_PUBLIC_TELEGRAM_BOT` no está definido, queda solo el del panel, como antes.
// En el proyector (horizontal) el QR grande va al lado del texto, para que ocupe todo el alto.
const ESTILO = {
  type: "svg" as const,
  margin: 1,
  errorCorrectionLevel: "M" as const,
  color: { dark: "#14532d", light: "#ffffff" },
};

const NOMBRE_ESCENARIO: Record<Escenario, string> = {
  "todo-bien": "Todo bien",
  alerta: "Alerta",
  "para-saber": "Para saber",
  "sin-senal": "Sin señal",
};

/** El enlace como se dicta o se escribe: sin «https://». */
const sinProtocolo = (url: string) => url.replace(/^https?:\/\//, "");

function Qr({ svg, className = "" }: { svg: string; className?: string }) {
  return (
    <div
      className={`bg-white [&>svg]:h-auto [&>svg]:w-full ${className}`}
      // El SVG lo genera la librería a partir de nuestra URL: no hay texto del usuario adentro.
      dangerouslySetInnerHTML={{ __html: svg }}
    />
  );
}

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
    <main className="flex min-h-dvh flex-col bg-papel px-6 py-8 text-tinta md:px-12">
      <div className="m-auto grid w-full max-w-7xl items-center gap-8 md:grid-cols-[minmax(0,1fr)_min(74vh,44vw)] md:gap-16">
        <div className="flex flex-col gap-5 text-center md:gap-6 md:text-left">
          <Marca className="justify-center text-xl md:justify-start md:text-2xl" />
          <h1 className="text-[42px] leading-[1.05] font-bold text-balance md:text-6xl xl:text-7xl">
            Cuida la casa de Carmen
          </h1>
          {telegram ? (
            <div className="flex flex-col gap-2">
              <p className="text-xl leading-snug text-texto text-balance md:text-3xl">
                Escanéalo y pulsa <strong className="text-tinta">Iniciar</strong>. Los avisos te llegan
                a Telegram.
              </p>
              <p className="font-mono text-sm break-all text-gris md:text-base">{sinProtocolo(telegram)}</p>
            </div>
          ) : (
            <p className="text-xl leading-snug text-texto text-balance md:text-3xl">
              Escanéalo con la cámara. Sin instalar nada ni crear cuenta.
            </p>
          )}
          {qrTelegram && (
            <section className="mt-2 flex items-center gap-4 self-center rounded-2xl border-[1.5px] border-borde bg-white p-3 pr-5 text-left md:self-start">
              <Qr svg={qrPanel} className="w-24 shrink-0 md:w-32" />
              <div className="flex min-w-0 flex-col gap-1">
                <h2 className="text-lg leading-tight font-bold md:text-xl">O mira cómo está, sin suscribirte</h2>
                <p className="font-mono text-xs break-all text-gris md:text-sm">{sinProtocolo(panel)}</p>
              </div>
            </section>
          )}
          {qrTelegram && (
            <p className="text-base leading-snug text-gris md:text-lg">
              Sin instalar nada ni crear cuenta. El audio se analiza en el teléfono de la casa y nunca
              sale de ahí.
            </p>
          )}
        </div>
        <Qr
          svg={qrTelegram ?? qrPanel}
          className="w-full rounded-3xl p-4 shadow-[0_8px_30px_-12px_rgb(20_83_45/0.25)] md:p-6"
        />
      </div>
      {/* Atajos para quien presenta: abren la casa con datos simulados. */}
      <nav
        className="mx-auto mt-6 flex flex-wrap items-center justify-center gap-x-1 gap-y-2 text-[15px] text-gris"
        aria-label="Escenarios de prueba"
      >
        <span className="mr-2">Ver un escenario:</span>
        {ESCENARIOS.map((e) => (
          <Link
            key={e}
            href={`/f/${TOKEN_DEMO}?escenario=${e}`}
            className="rounded-full px-3 py-1.5 underline-offset-4 hover:bg-linea hover:text-tinta hover:underline"
          >
            {NOMBRE_ESCENARIO[e]}
          </Link>
        ))}
      </nav>
    </main>
  );
}
