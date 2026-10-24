import { notFound } from "next/navigation";
import { VistaFamilia } from "@/components/familia/vista-familia";
import { cargarCasa } from "@/lib/familia/datos";

export default async function Page(props: PageProps<"/f/[token]">) {
  const { token } = await props.params;
  const { escenario } = await props.searchParams;
  const datos = cargarCasa(token, escenario, new Date());
  if (!datos) notFound();
  // La clave reinicia la pantalla al cambiar de escenario, sin arrastrar lo que se tocó antes.
  return <VistaFamilia key={String(escenario)} token={token} inicial={datos} />;
}
