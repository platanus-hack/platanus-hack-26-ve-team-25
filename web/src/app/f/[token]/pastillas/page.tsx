import { notFound } from "next/navigation";
import { Pastillas } from "@/components/familia/pastillas";
import { cargarCasa } from "@/lib/familia/datos";

export default async function Page(props: PageProps<"/f/[token]/pastillas">) {
  const { token } = await props.params;
  const { escenario } = await props.searchParams;
  const cargada = await cargarCasa(token, escenario, new Date());
  if (!cargada) notFound();
  return (
    <Pastillas
      token={token}
      nombre={cargada.datos.casa.nombre}
      inicial={cargada.datos.inventario ?? []}
      origen={cargada.origen}
      escenario={typeof escenario === "string" && cargada.origen === "simulado" ? escenario : null}
    />
  );
}
