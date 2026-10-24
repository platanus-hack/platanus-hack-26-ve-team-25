"use client";

// Las tres pantallas de la familia, como en el lienzo de mockups. No deciden nada: reciben la
// vista ya derivada (lib/familia/estado.ts) y la pintan.
import { type ReactNode, useEffect } from "react";
import { APP } from "@/lib/app";
import { duracion, fecha, haceCuanto, hora, quien, type Vista } from "@/lib/familia/estado";
import type { Casa, Contacto } from "@/lib/familia/tipos";

const CONDICION: Record<string, string> = {
  oxigeno: "usa oxígeno",
  hipertension: "hipertensión",
  diabetes: "diabetes",
  marcapasos: "marcapasos",
};

const tel = (numero?: string) => `tel:${numero ?? ""}`;
const mayuscula = (s: string) => s.charAt(0).toUpperCase() + s.slice(1);
// «TV o radio» se queda igual: una sigla no se baja a minúscula.
const minuscula = (s: string) => (/^\p{Lu}{2}/u.test(s) ? s : s.charAt(0).toLowerCase() + s.slice(1));

function segundoContacto(casa: Casa): Contacto | undefined {
  return [...casa.contactos].sort((a, b) => a.orden - b.orden)[1];
}

export function Pantalla({ children, className = "" }: { children: ReactNode; className?: string }) {
  return (
    <main
      className={`mx-auto flex min-h-dvh w-full max-w-md flex-col gap-4 px-5 pt-12 pb-6 ${className}`}
    >
      {children}
    </main>
  );
}

function Cabecera({ casa, ahora }: { casa: Casa; ahora: Date }) {
  return (
    <header className="flex items-center justify-between">
      <h1 className="text-[26px] font-bold">Casa de {casa.nombre}</h1>
      <span className="text-[15px] text-gris">{fecha(ahora)}</span>
    </header>
  );
}

export function Boton({
  href,
  onClick,
  variante,
  children,
}: {
  href?: string;
  onClick?: () => void;
  variante: "blanco" | "borde-rojo" | "verde" | "borde-verde";
  children: ReactNode;
}) {
  const estilos = {
    blanco: "h-16 bg-white text-rojo text-[21px]",
    "borde-rojo": "h-14 border-2 border-rojo-borde text-white text-[19px]",
    verde: "h-16 bg-verde text-white text-[21px]",
    "borde-verde": "h-14 border-2 border-verde text-verde text-[19px]",
  }[variante];
  const clase = `flex w-full items-center justify-center gap-2.5 rounded-[18px] font-bold active:scale-[0.98] transition-transform ${estilos}`;
  return onClick ? (
    <button type="button" onClick={onClick} className={clase}>
      {children}
    </button>
  ) : (
    <a href={href} className={clase}>
      {children}
    </a>
  );
}

function IconoTelefono() {
  return (
    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <path d="M22 16.9v3a2 2 0 0 1-2.2 2 19.8 19.8 0 0 1-8.6-3.1 19.5 19.5 0 0 1-6-6A19.8 19.8 0 0 1 2.1 4.2 2 2 0 0 1 4.1 2h3a2 2 0 0 1 2 1.7c.1.9.4 1.8.7 2.7a2 2 0 0 1-.5 2.1L8 9.8a16 16 0 0 0 6 6l1.3-1.3a2 2 0 0 1 2.1-.4c.9.3 1.8.6 2.7.7a2 2 0 0 1 1.7 2z" />
    </svg>
  );
}

export function IconoFlecha({ hacia, className = "" }: { hacia: "derecha" | "abajo" | "izquierda"; className?: string }) {
  const giro = { derecha: "", abajo: "rotate-90", izquierda: "rotate-180" }[hacia];
  return (
    <svg className={`size-5 shrink-0 ${giro} ${className}`} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.6" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <path d="m9 5 7 7-7 7" />
    </svg>
  );
}

/** El regreso a la pantalla anterior, arriba a la izquierda, con un área de toque cómoda. */
export function Volver({ href, children }: { href: string; children: ReactNode }) {
  return (
    <a href={href} className="-ml-1 flex min-h-11 items-center gap-1.5 self-start rounded-lg pr-2 text-[17px] font-bold text-verde">
      <IconoFlecha hacia="izquierda" />
      {children}
    </a>
  );
}

/** Mientras hay alerta, la barra del navegador y el título de la pestaña también la dicen. */
function useBarraDeAlerta(nombre: string) {
  useEffect(() => {
    const meta = document.querySelector<HTMLMetaElement>('meta[name="theme-color"]');
    const color = meta?.content;
    const titulo = document.title;
    if (meta) meta.content = APP.colorAlerta;
    document.title = `Urgente · Casa de ${nombre}`;
    return () => {
      if (meta && color) meta.content = color;
      document.title = titulo;
    };
  }, [nombre]);
}

export function AlertaUrgente({
  casa,
  vista,
  onAtendida,
}: {
  casa: Casa;
  vista: Extract<Vista, { tipo: "alerta" }>;
  onAtendida: () => void;
}) {
  const vecino = segundoContacto(casa);
  const condiciones = mayuscula(casa.condiciones.map((c) => CONDICION[c] ?? c).join(" · "));
  useBarraDeAlerta(casa.nombre);
  return (
    <div className="flex flex-1 flex-col bg-rojo text-white [--anillo:white]" role="alert">
      <Pantalla>
        <span className="flex items-center gap-2 self-start rounded-full bg-white py-1.5 pr-3 pl-2.5 text-[15px] font-bold text-rojo">
          <span className="relative flex size-2.5" aria-hidden="true">
            <span className="absolute inset-0 rounded-full bg-rojo opacity-60 motion-safe:animate-ping" />
            <span className="relative size-2.5 rounded-full bg-rojo" />
          </span>
          URGENTE · {hora(vista.alerta.escaladaEn ?? vista.alerta.creada)}
        </span>
        <h1 className="text-[36px] leading-[1.1] font-bold">{vista.titular}</h1>
        <p className="text-[19px] leading-[1.4] text-rojo-texto">{vista.explicacion}</p>
        <div className="flex flex-col gap-2 rounded-2xl bg-rojo-tarjeta px-4 py-3.5 text-base leading-[1.35]">
          <span className="font-bold">Lo que ya hicimos</span>
          {vista.hecho.map((h) => (
            <span key={h}>{h}</span>
          ))}
        </div>
        {condiciones && <div className="text-[15px] text-rojo-texto">{condiciones}</div>}
        <div className="mt-auto flex flex-col gap-2.5">
          <Boton href={tel(casa.telefono)} variante="blanco">
            Llamar a {casa.nombre}
          </Boton>
          {vecino && (
            <Boton href={tel(vecino.telefono)} variante="blanco">
              Llamar a {quien(vecino, "el")}
            </Boton>
          )}
          <Boton onClick={onAtendida} variante="borde-rojo">
            Ya hablé con {casa.nombre}, está bien
          </Boton>
        </div>
      </Pantalla>
    </div>
  );
}

export function SinSenal({
  casa,
  vista,
  ahora,
}: {
  casa: Casa;
  vista: Extract<Vista, { tipo: "sin_senal" }>;
  ahora: Date;
}) {
  const vecino = segundoContacto(casa);
  return (
    <Pantalla>
      <Cabecera casa={casa} ahora={ahora} />
      <section className="flex flex-col gap-2.5 rounded-[22px] bg-texto px-5 py-[22px] text-white">
        <div className="flex items-center gap-3">
          <svg width="34" height="34" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
            <path d="M2 2l20 20" /><path d="M8.5 16.5a5 5 0 0 1 7 0" /><path d="M2 8.8a15 15 0 0 1 4.2-2.6" /><path d="M10.7 5.1A15 15 0 0 1 22 8.8" /><path d="M5 12.9a10 10 0 0 1 5.2-2.7" /><path d="M14 10.4a10 10 0 0 1 5 2.5" /><path d="M12 20h.01" />
          </svg>
          <span className="text-[28px] leading-tight font-bold">Sin señal desde las {hora(vista.desde)}</span>
        </div>
        <span className="text-[17px] leading-[1.4] text-pizarra-texto">
          El teléfono de la casa dejó de reportar hace {duracion(vista.minutos)}. Mientras no
          vuelva, no podemos oír lo que pasa.
        </span>
      </section>
      <section className="flex flex-col gap-2 rounded-[18px] border-[1.5px] border-borde bg-white px-[18px] py-4">
        <span className="text-base font-bold">Lo último que supimos</span>
        <span className="text-base text-texto">
          {hora(vista.desde)} · {casa.enchufado ? "enchufado" : "desenchufado"}, batería {casa.bateria}%
        </span>
        {vista.ultimos.map((e) => (
          <span key={e.id} className="text-base text-texto">
            {hora(e.hora)} · {minuscula(e.descripcion)}
          </span>
        ))}
        <span className="text-[15px] leading-[1.4] text-gris">
          Suele pasar por un apagón largo, porque se fue el internet o porque desenchufaron el
          teléfono.
        </span>
      </section>
      <div className="mt-auto flex flex-col gap-2.5">
        <Boton href={tel(casa.telefono)} variante="verde">
          Llamar a {casa.nombre}
        </Boton>
        {vecino && (
          <Boton href={tel(vecino.telefono)} variante="borde-verde">
            Llamar a {quien(vecino, "el")}
          </Boton>
        )}
      </div>
    </Pantalla>
  );
}

export function TodoBien({
  casa,
  vista,
  ahora,
  pastillas,
}: {
  casa: Casa;
  vista: Extract<Vista, { tipo: "bien" }>;
  ahora: Date;
  /** La línea de pastillas y a dónde lleva, si la casa tiene récipe. */
  pastillas?: { texto: string; href: string } | null;
}) {
  const hayAvisos = vista.paraSaber.length > 0;
  const dia = (
    <ol className="flex flex-col rounded-[18px] border-[1.5px] border-borde bg-white px-4 py-1">
      {vista.dia.map((e, i) => (
        <li
          key={e.id}
          className={`flex gap-3.5 py-3 text-[17px] ${i < vista.dia.length - 1 ? "border-b border-linea" : ""}`}
        >
          <span className="w-12 shrink-0 text-gris tabular-nums">{hora(e.hora)}</span>
          <span className={e.tipo === "estoy_bien" ? "font-bold text-verde" : ""}>{e.descripcion}</span>
        </li>
      ))}
      {vista.dia.length === 0 && <li className="py-3 text-[17px] text-gris">Todavía no hay sonidos hoy</li>}
    </ol>
  );

  return (
    <Pantalla>
      <Cabecera casa={casa} ahora={ahora} />
      <section className="flex flex-col gap-2.5 rounded-[22px] bg-verde px-5 py-[22px] text-white">
        <div className="flex items-center gap-3">
          <svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
            <circle cx="12" cy="12" r="10" /><path d="m8 12 3 3 5-6" />
          </svg>
          <span className="text-[30px] font-bold">{casa.nombre} está bien</span>
        </div>
        {vista.ultimo && (
          <span className="text-[17px] text-verde-claro">
            Último sonido {hora(vista.ultimo.hora)} ·{" "}
            {minuscula(vista.ultimo.descripcion)}
          </span>
        )}
        <span className="text-[17px] text-verde-claro">
          {hayAvisos
            ? `Hoy hubo ${vista.paraSaber.length === 1 ? "un aviso" : `${vista.paraSaber.length} avisos`} para saber`
            : "Hoy no hubo avisos"}
        </span>
      </section>
      <div className="flex items-center gap-2.5 rounded-[14px] border-[1.5px] border-borde bg-white px-3.5 py-3 text-[15px] text-texto">
        <span className="size-2.5 shrink-0 rounded-full bg-ok" />
        <span>
          Teléfono de la casa conectado{casa.enchufado ? " y enchufado" : `, batería ${casa.bateria}%`} ·{" "}
          {haceCuanto(casa.ultimoLatido, ahora)}
        </span>
      </div>
      {pastillas && (
        <a
          href={pastillas.href}
          className="flex items-center justify-between gap-2.5 rounded-[14px] border-[1.5px] border-borde bg-white px-3.5 py-3 text-[15px] text-texto transition-colors active:bg-linea"
        >
          <span>{pastillas.texto}</span>
          <IconoFlecha hacia="derecha" className="text-verde" />
        </a>
      )}

      {hayAvisos && (
        <>
          <h2 className="mt-1.5 text-[19px] font-bold">Para saber</h2>
          {vista.paraSaber.map((a) => (
            <article key={a.hora + a.etiqueta + a.titulo} className="flex flex-col gap-2 rounded-[18px] bg-amarillo-fondo px-[18px] py-4 text-amarillo-tinta">
              <span className="text-sm font-bold">
                {a.hora && `${a.hora} · `}
                {a.etiqueta}
              </span>
              <span className="text-[19px] font-bold text-tinta">{a.titulo}</span>
              <span className="text-base leading-[1.35] text-texto">{a.detalle}</span>
              {a.enlace === "pastillas" && pastillas && (
                <a href={pastillas.href} className="text-base font-bold underline underline-offset-4">
                  Ver sus pastillas
                </a>
              )}
            </article>
          ))}
          <p className="text-[15px] leading-[1.4] text-gris">
            Estos avisos no suenan. Te llegan como máximo dos al día, juntos.
          </p>
        </>
      )}

      {hayAvisos ? (
        <details className="group">
          <summary className="flex min-h-12 cursor-pointer list-none items-center justify-between rounded-[14px] border-[1.5px] border-borde bg-white px-3.5 py-3 text-[17px] font-bold text-verde transition-colors group-open:mb-2.5 active:bg-linea [&::-webkit-details-marker]:hidden">
            <span className="group-open:hidden">Ver todo su día</span>
            <span className="hidden group-open:inline">Su día</span>
            <IconoFlecha hacia="abajo" className="transition-transform group-open:-rotate-90" />
          </summary>
          {dia}
        </details>
      ) : (
        <>
          <h2 className="mt-1.5 text-[19px] font-bold">Su día</h2>
          {dia}
        </>
      )}

      <div className="mt-auto pt-2">
        <Boton href={tel(casa.telefono)} variante="borde-verde">
          <IconoTelefono />
          Llamar a {casa.nombre}
        </Boton>
      </div>
    </Pantalla>
  );
}
