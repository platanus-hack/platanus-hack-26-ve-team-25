"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect } from "react";
import { Marca } from "@/components/familia/marca";
import { CLAVE_ULTIMA_CASA } from "@/components/familia/vista-familia";
import { APP } from "@/lib/app";

export function Portada() {
  const router = useRouter();

  useEffect(() => {
    try {
      const ultima = localStorage.getItem(CLAVE_ULTIMA_CASA);
      if (ultima?.startsWith("/f/")) router.replace(ultima);
    } catch {
      // Sin almacenamiento: se queda en la portada.
    }
  }, [router]);

  return (
    <main className="mx-auto flex min-h-dvh w-full max-w-md flex-col justify-center gap-5 bg-papel px-6 text-tinta">
      <h1>
        <Marca className="text-[28px]" />
      </h1>
      <p className="text-[26px] leading-[1.2] font-bold text-balance">{APP.descripcion}</p>
      <p className="text-base leading-[1.45] text-gris">
        Un teléfono viejo, enchufado en su casa, oye lo que pasa. El audio nunca sale de ahí.
      </p>
      <Link
        href="/f/demo/bienvenida"
        className="mt-2 flex h-16 items-center justify-center rounded-[18px] bg-verde text-[21px] font-bold text-white transition-transform active:scale-[0.98]"
      >
        Ver la casa de ejemplo
      </Link>
      <Link href="/privacidad" className="self-center text-[14px] text-gris underline underline-offset-2">
        Política de privacidad
      </Link>
    </main>
  );
}
