"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect } from "react";
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
      <h1 className="text-[34px] leading-[1.1] font-bold">{APP.nombreCorto}</h1>
      <p className="text-lg leading-[1.45] text-texto">{APP.descripcion}</p>
      <p className="text-base leading-[1.45] text-gris">
        Un teléfono viejo, enchufado en su casa, oye lo que pasa. El audio nunca sale de ahí.
      </p>
      <Link
        href="/f/demo/bienvenida"
        className="flex h-14 items-center justify-center rounded-2xl bg-verde text-[19px] font-bold text-white"
      >
        Ver la casa de ejemplo
      </Link>
    </main>
  );
}
