# Presente — Pitch

Presentación del equipo 25 para Platanus Hack 26 (Caracas, 23–25 de octubre de 2026), track Emergencias.

## Qué es

Un teléfono Android viejo, enchufado en la mesa de un adulto mayor que vive solo, oye lo que pasa: alarma de humo, vidrio roto, golpe, grito o una frase de ayuda dicha en voz alta. Antes de avisar, pregunta «¿Está bien?». Si nadie responde en 60 s, la alerta escala: la familia recibe un Telegram y la casa la llama por WhatsApp. El audio se procesa en el teléfono y nunca sale de él.

Este deck es la presentación de 3 minutos para el pitch: problema + demo de la web + cierre.

## Cómo correr

```bash
cd pitch
npm install
npm run dev
```

Abre http://localhost:4173 en el navegador.

### Atajos de teclado

- **→** / **Espacio** / **PageDown**: siguiente lámina
- **←** / **PageUp**: lámina anterior
- **Home**: ir a la primera lámina
- **End**: ir a la última lámina
- **f**: pantalla completa (Escape para salir)
- **Clic** en la mitad izquierda o derecha de la pantalla: navegar

También puedes ir directamente a una lámina con el hash: `#1`, `#2`, `#3`, `#4`, `#5`.

## Cómo desplegar

```bash
cd pitch
npm run build
npx vercel --prod
```

O desde la raíz del repo:

```bash
make pitch-deploy
```

El proyecto ya tiene `vercel.json` configurado con framework `vite`, buildCommand `npm run build` y outputDirectory `dist`.

## Estructura

```
pitch/
  index.html                  entry point, lang="es"
  package.json                name "presente-pitch", scripts: dev, build, preview, qr
  tsconfig.json               TypeScript estricto, incluye src y vite.config.ts
  tsconfig.node.json          configuración alternativa para vite.config.ts (no usada en build)
  vite.config.ts              Vite con plugin de React, sin CDN ni dependencias externas
  vercel.json                 framework vite, buildCommand npm run build, outputDirectory dist
  README.md                   este archivo
  scripts/
    qr.mjs                    genera public/qr-telegram.svg con el paquete qrcode
  public/
    foto-senor.jpg            foto del adulto mayor (1920×2743, vertical)
    qr-telegram.svg           QR de Telegram, generado por scripts/qr.mjs
  src/
    main.tsx                  entry point de React
    App.tsx                   estado global, navegación por teclado y hash, layout del escenario
    estilos/
      globals.css             variables del producto, sistema visual, escalado con cqw/cqh
    datos/
      cifras.ts               todas las cifras del deck tipadas y con fuente
    componentes/
      QrTelegram.tsx          QR fijo en la esquina superior derecha (todas las láminas menos Cierre)
      BarraProgreso.tsx       barra de progreso segmentada abajo
      GraficaArea.tsx         gráfica de área de la migración venezolana 2015–2024
      GraficaBarras.tsx       gráfica de barras de tiempos de aviso
      Marco.tsx               marco de navegador para emular la página de la familia
    laminas/
      Portada.tsx             lámina 1: wordmark, pregunta grande, bajada, pie
      ElQueSeQueda.tsx        lámina 2: foto a sangre + 4 KPIs
      LosNumeros.tsx          lámina 3: dos gráficas (migración + tiempos)
      LaFamilia.tsx           lámina 4: teléfono de la casa + página de la familia + flujo
      Cierre.tsx              lámina 5: frase grande, tres columnas, QR grande, gracias
```

## Stack

- **Vite + React 19 + TypeScript**, con npm (no bun).
- **Cero dependencias de runtime** más allá de react y react-dom. Nada de Chart.js, Tailwind, framer-motion, ni librerías de slides. Las gráficas se dibujan a mano en SVG inline.
- **Única devDependency extra**: `qrcode` (más `@types/qrcode`), solo para el script que genera el SVG del QR.
- **Ninguna fuente externa ni CDN**: `font-family: system-ui` y todo el CSS propio. El venue puede no tener wifi.
- **CSS plano** con variables (`src/estilos/globals.css`), sin preprocesador.

## Sistema visual

Las variables CSS son los colores oficiales del producto:

```css
--papel: #f7f7f4;        --tinta: #1c1c1a;      --texto: #3d3d37;   --gris: #57574f;
--borde: #e2e2da;        --linea: #edede6;
--verde: #14532d;        --verde-claro: #d7ebdd; --ok: #16a34a;
--rojo: #b01d16;         --rojo-tarjeta: #941710; --rojo-texto: #fde8e7; --rojo-borde: #f3b7b3;
```

Estilo: claro minimalista. Mucho aire, tipografía grande, un solo acento por lámina. Sin degradados llamativos, sin sombras dramáticas, sin emojis decorativos. Los números mandan: peso 700, `font-variant-numeric: tabular-nums`.

## Escenario y escalado

Cada lámina es un escenario 16:9 centrado, sin scroll. Usa `width: min(100vw, calc(100vh * 16 / 9))` para mantener el aspect ratio. Se escala con **container queries** (`container-type: size` en el escenario) y tamaños en `cqw`/`cqh` para que TODO escale proporcionalmente: se ve igual en una laptop, en el proyector 4:3 letterboxeado y en pantalla vertical. Nada de media queries por dispositivo.

`overflow: hidden` en el escenario; ningún texto debe cortarse.

Respeta `prefers-reduced-motion`: sin animaciones de entrada si está activo.

## El QR de Telegram

Fijo arriba a la derecha, fuera del flujo del contenido, ~`6cqh` de lado, sobre tarjeta blanca con borde `--borde` y esquinas redondeadas. Contenido: `https://t.me/CasaAvisoBot?start=demo`. Debajo, en `1.2cqh` gris mayúsculas con tracking: `@CasaAvisoBot`.

`scripts/qr.mjs` genera el SVG con el paquete `qrcode` y lo escribe en `public/qr-telegram.svg`. Idempotente: si ya existe y el contenido es el mismo, no lo reescribe. Se ejecuta automáticamente antes de `dev` y `build` (predev/prebuild).

El QR se oculta en la lámina 5 (Cierre), donde se muestra uno grande dentro del contenido.

## Crédito de la foto

`public/foto-senor.jpg`: foto de un adulto mayor mirando por la ventana. Uso educativo para el pitch del hackatón.

## Licencia

Este proyecto es parte de Platanus Hack 26, track Emergencias, equipo 25. Código y documentación bajo licencia MIT.

## Comandos desde la raíz del repo

```bash
make pitch            # cd pitch && npm install && npm run dev
make pitch-deploy     # cd pitch && npm run build && npx vercel --prod
```
