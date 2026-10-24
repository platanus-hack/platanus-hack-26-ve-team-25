import { notFound } from "next/navigation";
import { VistaFamilia } from "@/components/familia/vista-familia";
import { cargarCasa } from "@/lib/familia/datos";

export default async function Page(props: PageProps<"/f/[token]">) {
  const { token } = await props.params;
  const { escenario } = await props.searchParams;
  const cargada = await cargarCasa(token, escenario, new Date());
  if (!cargada) notFound();
  // La clave reinicia la pantalla al cambiar de escenario, sin arrastrar lo que se tocó antes.
  return (
    <VistaFamilia
      key={String(escenario)}
      token={token}
      inicial={cargada.datos}
      origen={cargada.origen}
      escenario={typeof escenario === "string" && cargada.origen === "simulado" ? escenario : null}
    />
  );
}
