/**
 * El teléfono de la casa, casi en vivo, para la lámina 3 del deck.
 *
 * Captura la pantalla del teléfono con `adb exec-out screencap -p` en bucle y sirve el último
 * cuadro en http://localhost:8765/telefono.png. El deck lo pide cada 800 ms y lo pinta dentro del
 * marco del teléfono.
 *
 * Por qué no se usa getDisplayMedia (la captura de ventanas del navegador): en Linux sin el portal
 * de PipeWire, Chrome solo ofrece pestañas, y la ventana de scrcpy queda fuera. Por acá se llega a
 * la pantalla del teléfono sin pasar por el navegador.
 *
 * Uso:
 *   npm run vivo            (o directamente: node scripts/vivo.mjs)
 *   npm run vivo -- --cada 500     más refresco, más CPU
 *
 * No graba nada ni guarda cuadros en disco: el último cuadro vive en memoria y se tira.
 */
import { createServer } from "node:http";
import { execFile } from "node:child_process";

const PUERTO = 8765;
const argumentos = process.argv.slice(2);
const iCada = argumentos.indexOf("--cada");
const CADA_MS = iCada >= 0 ? Math.max(200, Number(argumentos[iCada + 1]) || 800) : 800;

/** @type {Buffer | null} */
let ultimoCuadro = null;
let cuadros = 0;
let tomando = false;
let ultimoError = "";

/** Pide un cuadro a adb. Si el anterior no terminó, se salta: preferimos uno viejo a una cola. */
function capturar() {
  if (tomando) return;
  tomando = true;
  execFile(
    "adb",
    ["exec-out", "screencap", "-p"],
    { encoding: "buffer", maxBuffer: 64 * 1024 * 1024, timeout: 5000 },
    (error, salida) => {
      tomando = false;
      if (error || !salida || salida.length === 0) {
        ultimoError = error?.message ?? "adb devolvió una imagen vacía";
        return;
      }
      // Un PNG empieza con estos ocho bytes; si no están, adb escupió un error de texto.
      const esPng = salida.length > 8 && salida[1] === 0x50 && salida[2] === 0x4e && salida[3] === 0x47;
      if (!esPng) {
        ultimoError = "lo que llegó no es un PNG (¿el teléfono está autorizado?)";
        return;
      }
      ultimoCuadro = salida;
      cuadros += 1;
      ultimoError = "";
    }
  );
}

capturar();
setInterval(capturar, CADA_MS);

const servidor = createServer((peticion, respuesta) => {
  const ruta = (peticion.url ?? "/").split("?")[0];

  // El deck puede estar servido desde otro origen (Vercel o localhost:4173).
  respuesta.setHeader("Access-Control-Allow-Origin", "*");
  respuesta.setHeader("Cache-Control", "no-store, max-age=0");

  if (ruta === "/estado") {
    respuesta.writeHead(200, { "content-type": "application/json; charset=utf-8" });
    respuesta.end(JSON.stringify({ cuadros, cadaMs: CADA_MS, error: ultimoError || null }));
    return;
  }

  if (ruta === "/telefono.png") {
    if (!ultimoCuadro) {
      respuesta.writeHead(503, { "content-type": "text/plain; charset=utf-8" });
      respuesta.end(ultimoError || "todavía no hay cuadro");
      return;
    }
    respuesta.writeHead(200, { "content-type": "image/png", "content-length": ultimoCuadro.length });
    respuesta.end(ultimoCuadro);
    return;
  }

  respuesta.writeHead(404, { "content-type": "text/plain; charset=utf-8" });
  respuesta.end("Usa /telefono.png para la imagen o /estado para saber cómo va.");
});

servidor.listen(PUERTO, "127.0.0.1", () => {
  console.log(`Teléfono en vivo en http://localhost:${PUERTO}/telefono.png (cada ${CADA_MS} ms)`);
  console.log("Pulsa A en la lámina 3 del deck. Ctrl+C para parar.");
});
