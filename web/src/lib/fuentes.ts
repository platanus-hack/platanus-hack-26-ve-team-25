import { Atkinson_Hyperlegible } from "next/font/google";

// Hecha para baja visión: la familia la lee con prisa, y a veces con los lentes en otro cuarto.
// Es la letra de toda la web: globals.css la toma de la variable como `font-sans`.
export const atkinson = Atkinson_Hyperlegible({
  subsets: ["latin"],
  weight: ["400", "700"],
  variable: "--font-atkinson",
});
