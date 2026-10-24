import type { Metadata, Viewport } from "next";
import { Geist_Mono } from "next/font/google";
import { APP } from "@/lib/app";
import { atkinson } from "@/lib/fuentes";
import "./globals.css";

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: APP.nombre,
  description: APP.descripcion,
  // iPhone no lee el manifiesto para esto: hay que decirle aparte que se abra sin barra
  appleWebApp: { capable: true, title: APP.nombreCorto, statusBarStyle: "default" },
};

export const viewport: Viewport = {
  themeColor: APP.colorTema,
};

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html
      lang="es"
      className={`${atkinson.variable} ${geistMono.variable} h-full antialiased`}
    >
      <body className="min-h-full flex flex-col">{children}</body>
    </html>
  );
}
