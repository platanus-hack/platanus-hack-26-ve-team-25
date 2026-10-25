// Genera, a partir de los SVG de esta carpeta, los íconos de la app de la casa
// (Android y web) y las imágenes de la ficha de Google Play.
//
//   node marca/generar.mjs
//
// Usa sharp, que ya viene instalado en web/node_modules (cd web && bun install).
import { createRequire } from "node:module";
import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const marca = dirname(fileURLToPath(import.meta.url));
const raiz = join(marca, "..");
const sharp = createRequire(join(raiz, "web", "package.json"))("sharp");

const res = join(raiz, "app/android/app/src/main/res");
const web = join(raiz, "app/web");
const play = join(marca, "play");

const FONDO = "#141B2E";
const CLARO = "#F4F4F0";
const AMBAR = "#FDB022";

const leer = (nombre) =>
  readFileSync(join(marca, nombre), "utf8").replace(/<metadata>.*?<\/metadata>/s, "");

// El símbolo (casa y destello), en coordenadas de 0 a 100 con el centro en (50, 52).
const simbolo = (casa, destello) => `
  <path d="M18 47 L50 20 L82 47 V79 Q82 84 77 84 H23 Q18 84 18 79 Z" fill="none"
        stroke="${casa}" stroke-width="6" stroke-linejoin="round"/>
  <path d="M50 42 Q52.5 57.5 66 60 Q52.5 62.5 50 78 Q47.5 62.5 34 60 Q47.5 57.5 50 42 Z"
        fill="${destello}"/>`;

// Capa de primer plano del ícono adaptable (108 dp). Android recorta con una máscara
// y solo garantiza el círculo central de 66 dp: el símbolo mide 46 unidades del centro
// a la esquina de abajo, así que con escala 0,62 queda dentro del radio de 33 dp.
const primerPlano = (casa, destello) => `
  <svg xmlns="http://www.w3.org/2000/svg" width="108" height="108" viewBox="0 0 108 108">
    <g transform="translate(54 54) scale(0.62) translate(-50 -52)">${simbolo(casa, destello)}</g>
  </svg>`;

async function png(svg, lado, destino, { alto = lado, fondo } = {}) {
  mkdirSync(dirname(destino), { recursive: true });
  let img = sharp(Buffer.from(svg), { density: 600 }).resize(lado, alto);
  if (fondo) img = img.flatten({ background: fondo });
  await img.png({ compressionLevel: 9 }).toFile(destino);
  console.log(destino.replace(raiz + "/", ""));
}

async function jpg(svg, ancho, alto, destino) {
  mkdirSync(dirname(destino), { recursive: true });
  await sharp(Buffer.from(svg), { density: 600 })
    .resize(ancho, alto)
    .flatten({ background: FONDO })
    .jpeg({ quality: 92, mozjpeg: true })
    .toFile(destino);
  console.log(destino.replace(raiz + "/", ""));
}

const icono = leer("presente-icono.svg");
const pequeno = leer("presente-icono-pequeno.svg"); // trazo más grueso para tamaños chicos
const cuadrado = leer("presente-icono-cuadrado.svg");

// Android: ícono clásico (antes de Android 8) y capas del adaptable.
const densidades = { mdpi: 1, hdpi: 1.5, xhdpi: 2, xxhdpi: 3, xxxhdpi: 4 };
for (const [d, k] of Object.entries(densidades)) {
  const carpeta = join(res, `mipmap-${d}`);
  await png(k <= 2 ? pequeno : icono, 48 * k, join(carpeta, "ic_launcher.png"));
  await png(primerPlano(CLARO, AMBAR), 108 * k, join(carpeta, "ic_launcher_foreground.png"));
  await png(primerPlano("#FFFFFF", "#FFFFFF"), 108 * k, join(carpeta, "ic_launcher_monochrome.png"));
}
// Lo que se ve mientras arranca Flutter: el símbolo sobre el fondo de la marca.
await png(primerPlano(CLARO, AMBAR), 288, join(res, "drawable-nodpi", "splash.png"));

const adaptable = `<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
    <monochrome android:drawable="@mipmap/ic_launcher_monochrome"/>
</adaptive-icon>
`;
mkdirSync(join(res, "mipmap-anydpi-v26"), { recursive: true });
writeFileSync(join(res, "mipmap-anydpi-v26", "ic_launcher.xml"), adaptable);
writeFileSync(
  join(res, "values", "colores.xml"),
  `<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">${FONDO}</color>
</resources>
`,
);

// Web (la vista previa en Vercel). El maskable va a sangre: el símbolo ya cabe en el
// 80% central que piden los navegadores.
await png(pequeno, 32, join(web, "favicon.png"));
await png(icono, 192, join(web, "icons/Icon-192.png"));
await png(icono, 512, join(web, "icons/Icon-512.png"));
await png(cuadrado, 192, join(web, "icons/Icon-maskable-192.png"));
await png(cuadrado, 512, join(web, "icons/Icon-maskable-512.png"));

// Google Play. El ícono va cuadrado y sin transparencia: Play le pone las esquinas.
await png(cuadrado, 512, join(play, "icono-512.png"), { fondo: FONDO });

// Gráfico destacado, 1024 × 500: el logo horizontal centrado sobre el fondo oscuro.
const logo = leer("presente-logo-horizontal-fondo-oscuro.svg")
  .replace(/^<svg[^>]*>/, "")
  .replace(/<\/svg>\s*$/, "")
  .replace(/<title>.*?<\/title>/, "");
const ancho = 720;
const escala = ancho / 918;
const destacado = `
  <svg xmlns="http://www.w3.org/2000/svg" width="1024" height="500" viewBox="0 0 1024 500">
    <rect width="1024" height="500" fill="${FONDO}"/>
    <g transform="translate(${(1024 - ancho) / 2} ${(500 - 180 * escala) / 2}) scale(${escala})">${logo}</g>
  </svg>`;
await jpg(destacado, 1024, 500, join(play, "grafico-destacado-1024x500.jpg"));
