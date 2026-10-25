#!/usr/bin/env node

/**
 * Genera el SVG del QR de Telegram y lo escribe en public/qr-telegram.svg.
 * Idempotente: si el archivo existe y el contenido es el mismo, no lo reescribe.
 *
 * Uso: node scripts/qr.mjs
 */

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const SALIDA = path.join(__dirname, "..", "public", "qr-telegram.svg");
const URL_QR = "https://t.me/CasaAvisoBot?start=demo";

let QRCode;
try {
  QRCode = await import("qrcode");
} catch {
  console.error(
    "Error: no se pudo importar el paquete 'qrcode'.\n" +
      "Ejecuta primero:  npm install"
  );
  process.exit(1);
}

const svg = await QRCode.toString(URL_QR, {
  type: "svg",
  margin: 1,
  errorCorrectionLevel: "M",
  color: {
    dark: "#1c1c1a",
    light: "#ffffff",
  },
});

// Idempotente: solo escribir si el contenido cambió.
if (fs.existsSync(SALIDA)) {
  const actual = fs.readFileSync(SALIDA, "utf8");
  if (actual === svg) {
    console.log("QR sin cambios, no se reescribe.");
    process.exit(0);
  }
}

fs.mkdirSync(path.dirname(SALIDA), { recursive: true });
fs.writeFileSync(SALIDA, svg, "utf8");
console.log(`QR generado en ${SALIDA}`);
