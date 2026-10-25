import Link from "next/link";
import { notFound } from "next/navigation";
import { cargarCasa } from "@/lib/familia/datos";

// Lo que ve quien escanea el QR. El botón de Telegram abre el bot con el token como payload
// (/start <token>); el botón de WhatsApp abre wa.me con un mensaje listo para el número de
// Kapso: ese mensaje registra el teléfono con la casa y abre la ventana de 24 h de Meta, en la
// que se le puede escribir sin plantillas aprobadas (docs/plan.md, créditos). Sin número no se
// muestra: WhatsApp salió del demo el sábado 18:00 y Telegram es el canal.
const NUMERO_WHATSAPP = process.env.NEXT_PUBLIC_WHATSAPP_NUMERO?.replace(/\D/g, "");
const BOT_TELEGRAM = process.env.NEXT_PUBLIC_TELEGRAM_BOT;

export default async function Page(props: PageProps<"/f/[token]/bienvenida">) {
  const { token } = await props.params;
  const cargada = await cargarCasa(token, null, new Date());
  if (!cargada) notFound();
  const { nombre } = cargada.datos.casa;
  const mensaje = `Quiero cuidar a ${nombre} (casa ${token})`;
  const whatsapp = NUMERO_WHATSAPP
    ? `https://wa.me/${NUMERO_WHATSAPP}?text=${encodeURIComponent(mensaje)}`
    : null;
  const telegram = BOT_TELEGRAM ? `https://t.me/${BOT_TELEGRAM}?start=${token}` : null;

  return (
    <main className="mx-auto flex min-h-dvh w-full max-w-md flex-col gap-[18px] px-[22px] pt-14 pb-6">
      <h1 className="text-[34px] leading-[1.1] font-bold text-balance">La casa de {nombre}</h1>
      <p className="text-lg leading-[1.45] text-texto">
        Te invitaron a cuidarla. Su teléfono oye la casa y, si algo pasa y no responde en 60
        segundos, te avisamos.
      </p>
      <div className="flex flex-col gap-2.5 rounded-[18px] border-[1.5px] border-borde bg-white px-[18px] py-4 text-base leading-[1.4] text-texto">
        <span>
          <strong className="text-tinta">No la grabamos.</strong> El sonido se analiza en su teléfono
          y nunca sale de ahí.
        </span>
        <span>
          <strong className="text-tinta">No te llenamos de avisos.</strong> Solo suena lo urgente. Lo
          demás, un resumen al día.
        </span>
      </div>
      <div className="mt-auto flex flex-col gap-3">
        {telegram && (
          <a
            href={telegram}
            className="flex h-[72px] items-center justify-center gap-3 rounded-[18px] bg-telegram text-[21px] font-bold text-white transition-transform active:scale-[0.98]"
          >
            <svg
              width="28"
              height="28"
              viewBox="0 0 24 24"
              fill="currentColor"
              aria-hidden="true"
            >
              <path d="M2.01 21L23 12 2.01 3 2 10l15 2-15 2z" />
            </svg>
            Recibir avisos por Telegram
          </a>
        )}
        {telegram && (
          <span className="text-center text-[14px] leading-[1.3] text-gris">
            Un toque. Llega como notificación al teléfono.
          </span>
        )}
        {whatsapp && (
          <>
            <a
              href={whatsapp}
              className="flex h-[72px] items-center justify-center gap-3 rounded-[18px] bg-whatsapp text-[21px] font-bold text-white transition-transform active:scale-[0.98]"
            >
              <svg width="28" height="28" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
                <path d="M12 2a10 10 0 0 0-8.6 15.1L2 22l5-1.3A10 10 0 1 0 12 2Zm0 18.2a8.2 8.2 0 0 1-4.2-1.1l-.3-.2-3 .8.8-2.9-.2-.3A8.2 8.2 0 1 1 12 20.2Zm4.5-6.1c-.2-.1-1.5-.7-1.7-.8-.2-.1-.4-.1-.6.1l-.8 1c-.1.2-.3.2-.5.1a6.7 6.7 0 0 1-3.3-2.9c-.3-.4.3-.4.7-1.3.1-.2 0-.3 0-.4l-.8-1.8c-.2-.5-.4-.4-.6-.4h-.5a1 1 0 0 0-.7.3 3 3 0 0 0-.9 2.2 5.2 5.2 0 0 0 1.1 2.7 11.8 11.8 0 0 0 4.5 4c1.7.7 2.3.8 3.2.6.5-.1 1.5-.6 1.7-1.2.2-.6.2-1.1.2-1.2-.1-.1-.3-.2-.5-.3Z" />
              </svg>
              Recibir avisos por WhatsApp
            </a>
            <span className="text-center text-[15px] leading-[1.4] text-gris">
              Se abre WhatsApp con un mensaje listo: solo toca «Enviar». Así los avisos urgentes te
              llegan aunque no tengas esta página abierta.
            </span>
          </>
        )}
        <Link
          href={`/f/${token}`}
          className="flex h-[60px] items-center justify-center rounded-[18px] border-2 border-verde text-[19px] font-bold text-verde transition-transform active:scale-[0.98]"
        >
          Ver cómo está ahora
        </Link>
      </div>
      <Link
        href="/privacidad"
        className="mt-auto self-center pt-4 text-[14px] text-gris underline underline-offset-2"
      >
        Política de privacidad
      </Link>
    </main>
  );
}
