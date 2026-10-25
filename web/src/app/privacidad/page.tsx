import type { Metadata } from "next";
import Link from "next/link";
import { APP } from "@/lib/app";

// La política de privacidad, a partir del borrador de Abrahan (domingo 25). Cada fila de DATOS
// tiene que coincidir con lo que guarda el esquema (supabase/migrations/) y con lo que hace la app
// de la casa: si cambia lo que sale del teléfono, se cambia aquí.

export const metadata: Metadata = {
  title: `Política de privacidad · ${APP.nombreCorto}`,
  description: `Qué datos usa ${APP.nombreCorto}, para qué, con quién se comparten y cómo pedir que se borren.`,
};

const CONTACTO = "https://github.com/platanus-hack/platanus-hack-26-ve-team-25/issues";

const DATOS: { dato: string; para: string; sale: string }[] = [
  {
    dato: "Audio del micrófono",
    para: "Reconocer sonidos de emergencia (alarma de humo, vidrio roto, golpe, grito) y frases de ayuda u órdenes dichas en voz alta, como «Lucero, llama a mi hijo».",
    sale: "No. Vive 5 segundos en la memoria del teléfono y se reemplaza sin parar. El reconocimiento corre en el aparato, sin internet.",
  },
  {
    dato: "Qué se oyó y cuándo",
    para: "Avisar a la familia, por ejemplo «golpe a las 15:42», sin el sonido.",
    sale: "Sí, como una etiqueta de texto.",
  },
  {
    dato: "Alertas y respuestas",
    para: "Saber si la persona respondió «¿Está bien?» y, si no, avisar a la familia aunque el teléfono se apague.",
    sale: "Sí.",
  },
  {
    dato: "Batería, si está enchufado y la hora de la última conexión",
    para: "Que la familia sepa que el teléfono de la casa sigue funcionando.",
    sale: "Sí.",
  },
  {
    dato: "Pastillas",
    para: "Recordar la pastilla y llevar la cuenta de cuántas quedan.",
    sale: "Sí: el nombre de la pastilla, cuántas hay y la hora en que se tomó.",
  },
  {
    dato: "Una foto de la sala, solo en una emergencia",
    para: "Que la familia vea qué pasa cuando la casa va a llamar porque nadie respondió o se pidió emergencias. Claude la describe en una frase para el aviso.",
    sale: "Sí: va a un almacenamiento privado de la casa y, por Telegram, a los familiares suscritos. La web la muestra durante 24 horas, y la borramos cuando el teléfono sube la siguiente o cuando pides borrar los datos. La copia de Telegram queda en el chat de cada familiar.",
  },
  {
    dato: "Nombre de la persona y las condiciones de salud que anote la familia (por ejemplo, hipertensión o marcapasos)",
    para: "Que quien recibe una alerta sepa a quién va a ayudar y qué tener en cuenta.",
    sale: "Sí: se guardan con la casa.",
  },
  {
    dato: "Números de teléfono de la familia",
    para: "Llamar cuando la persona lo pide o cuando nadie responde a una alerta.",
    sale: "Sí: se guardan con la casa para que la familia los vea en su web. Las llamadas salen del teléfono por la red telefónica o por WhatsApp.",
  },
  {
    dato: "Contactos del teléfono",
    para: "Encontrar el contacto de WhatsApp del familiar para llamarlo.",
    sale: "No. Se leen en el teléfono y no se envían.",
  },
  {
    dato: "Tu cuenta de Telegram, si te suscribes",
    para: "Mandarte el aviso cuando hay una alerta.",
    sale: "Sí: solo el número de chat que Telegram nos da.",
  },
];

const PERMISOS: [string, string][] = [
  [
    "Micrófono",
    ", también con la pantalla apagada, con un servicio en primer plano que muestra una notificación permanente: para oír la casa.",
  ],
  ["Cámara", ": para la foto de la sala justo antes de llamar por una emergencia. Se prende, toma una foto y se apaga."],
  ["Llamadas telefónicas", ": para llamar al familiar o al número de emergencias."],
  ["Contactos", ": para hacer la llamada por WhatsApp."],
  ["Mostrar sobre otras apps", ": para que «¿Está bien?» aparezca aunque haya otra app abierta."],
  [
    "Notificaciones, vibración e ignorar la optimización de batería",
    ": para que la alarma suene y la app no se cierre sola.",
  ],
];

const SERVICIOS: [string, string][] = [
  [
    "Supabase",
    ": la base de datos donde se guardan las etiquetas, las alertas, la batería y las pastillas, y el almacenamiento privado de las fotos de emergencia.",
  ],
  [
    "Vercel",
    ": aloja la web de la familia. Como todo servidor web, registra datos técnicos de las visitas, como la dirección IP.",
  ],
  ["Telegram", ": entrega el aviso, y la foto de emergencia, a los familiares que se suscribieron."],
  ["WhatsApp y la compañía telefónica", ": cursan las llamadas que hace el teléfono."],
  [
    "Anthropic (Claude)",
    ": describe en una frase la foto de emergencia, y lee la foto de la factura de la farmacia si la familia la toma en su web. La foto de la factura no se guarda; se guarda solo lo que la familia confirma.",
  ],
];

function Seccion({ titulo, children }: { titulo: string; children: React.ReactNode }) {
  return (
    <section className="flex flex-col gap-3">
      <h2 className="mt-6 text-[22px] leading-[1.2] font-bold">{titulo}</h2>
      {children}
    </section>
  );
}

function Lista({ filas }: { filas: [string, string][] }) {
  return (
    <ul className="flex list-disc flex-col gap-2 pl-5">
      {filas.map(([fuerte, resto]) => (
        <li key={fuerte}>
          <strong>{fuerte}</strong>
          {resto}
        </li>
      ))}
    </ul>
  );
}

function Contacto({ children }: { children: React.ReactNode }) {
  return (
    <a href={CONTACTO} className="font-bold text-verde underline underline-offset-2">
      {children}
    </a>
  );
}

export default function Page() {
  return (
    <main className="mx-auto flex min-h-dvh w-full max-w-xl flex-col gap-3 bg-papel px-5 pt-12 pb-10 text-[17px] leading-[1.55] text-texto">
      <h1 className="text-[30px] leading-[1.15] font-bold text-tinta text-balance">
        Política de privacidad de {APP.nombreCorto}
      </h1>
      <p className="text-gris">Vigente desde el 25 de octubre de 2026</p>

      <div className="mt-3 flex flex-col gap-3 rounded-[18px] border border-borde border-l-4 border-l-verde bg-white px-5 py-4">
        <p>
          <strong className="text-tinta">En pocas palabras:</strong> {APP.nombreCorto} convierte un
          teléfono Android en un acompañante para una persona mayor que vive sola. Oye lo que pasa en
          la casa para poder preguntar «¿Está bien?» y avisar a su familia si nadie responde.
        </p>
        <p>
          <strong className="text-tinta">El audio nunca sale del teléfono.</strong> Se procesa en el
          aparato y no se graba ni se envía a ningún servidor. Lo único que sale además de etiquetas
          de texto es una foto de la sala, y solo justo antes de llamar por una emergencia. No hay
          anuncios, no vendemos datos y no usamos herramientas de analítica ni de publicidad.
        </p>
      </div>

      <Seccion titulo="Quién es responsable">
        <p>
          {APP.nombreCorto} es un proyecto del equipo 25 de Platanus Hack 26 (Caracas, Venezuela). Para
          cualquier pregunta sobre esta política o sobre tus datos, <Contacto>escríbenos aquí</Contacto>.
        </p>
      </Seccion>

      <Seccion titulo="Qué datos usa y para qué">
        <dl className="flex flex-col gap-2">
          {DATOS.map(({ dato, para, sale }) => (
            <div key={dato} className="rounded-[14px] border border-borde bg-white px-4 py-3">
              <dt className="font-bold text-tinta">{dato}</dt>
              <dd>{para}</dd>
              <dd className="mt-1 text-[15px] text-gris">
                <span className="font-bold">¿Sale del teléfono?</span> {sale}
              </dd>
            </div>
          ))}
        </dl>
        <p>
          No recogemos la ubicación, mensajes, el historial de navegación ni identificadores de
          publicidad, y la cámara solo se usa en una emergencia. La web de la familia recuerda en tu navegador cuál fue la
          última casa que abriste, para llevarte directo a ella, y no usa cookies de seguimiento.
        </p>
      </Seccion>

      <Seccion titulo="Permisos que pide la app de la casa">
        <Lista filas={PERMISOS} />
      </Seccion>

      <Seccion titulo="Con quién se comparten los datos">
        <p>No vendemos ni alquilamos datos. Solo los usan estos servicios, para que la app funcione:</p>
        <Lista filas={SERVICIOS} />
      </Seccion>

      <Seccion titulo="Quién puede ver los datos">
        <p>
          Solo las personas que tienen el enlace de invitación de esa casa, que la familia decide con
          quién compartir. La clave del teléfono de la casa y la de cada enlace se guardan como huella
          SHA-256, nunca tal cual: quien leyera la base no podría usarlas. Todas las conexiones van
          cifradas (HTTPS).
        </p>
      </Seccion>

      <Seccion titulo="Cuánto tiempo se guardan y cómo borrarlos">
        <p>
          Los datos se guardan mientras la casa esté activa. Puedes pedir que borremos todos los datos
          de una casa <Contacto>escribiéndonos aquí</Contacto>, sin poner datos de la casa en el
          mensaje: te respondemos para confirmar que es tuya. Lo hacemos en un plazo de 30 días, y se
          borran también las alertas, los eventos, las fotos, las pastillas y las suscripciones de esa
          casa. Al
          desinstalar la app, el teléfono deja de enviar datos.
        </p>
      </Seccion>

      <Seccion titulo="Menores de edad">
        <p>
          {APP.nombreCorto} está pensada para personas mayores y sus familias. No está dirigida a
          menores de 13 años ni recoge sus datos a sabiendas.
        </p>
      </Seccion>

      <Seccion titulo="Cambios a esta política">
        <p>
          Si cambiamos esta política, publicaremos la nueva versión en esta página con su fecha. Si el
          cambio afecta lo que sale del teléfono, lo avisaremos en la app antes de que aplique.
        </p>
      </Seccion>

      <footer className="mt-10 flex flex-wrap items-center justify-between gap-3 text-[15px] text-gris">
        <span>{APP.nombreCorto} · Equipo 25 · Platanus Hack 26 · Caracas</span>
        <Link href="/" className="font-bold text-verde underline underline-offset-2">
          Volver
        </Link>
      </footer>
    </main>
  );
}
