import { notFound } from "next/navigation";
import { SubirFactura } from "@/components/familia/factura";
import { cargarCasa } from "@/lib/familia/datos";

export default async function Page(props: PageProps<"/f/[token]/pastillas/factura">) {
  const { token } = await props.params;
  const { escenario } = await props.searchParams;
  const cargada = await cargarCasa(token, escenario, new Date());
  if (!cargada) notFound();
  return (
    <SubirFactura
      token={token}
      nombre={cargada.datos.casa.nombre}
      recipe={cargada.datos.inventario ?? []}
      origen={cargada.origen}
      escenario={typeof escenario === "string" && cargada.origen === "simulado" ? escenario : null}
    />
  );
}
