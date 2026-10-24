import type { Metadata } from "next";
import { Escucha } from "./escucha";

export const metadata: Metadata = {
  title: "Escucha · prueba de viabilidad",
};

export default function Page() {
  return <Escucha />;
}
