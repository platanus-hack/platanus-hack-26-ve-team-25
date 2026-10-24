"use client";

import { useEffect, useRef, useState } from "react";
import { Anillo } from "@/lib/escucha/anillo";
import { ES_ALERTA, ETIQUETA, eventoDe, unirCategorias, type Categoria, type TipoEvento } from "@/lib/escucha/eventos";
import { Compuerta, LineaBase, rmsDb } from "@/lib/escucha/nivel";

const WASM = "https://cdn.jsdelivr.net/npm/@mediapipe/tasks-audio@1.1.1/wasm";
const MODELO = "https://storage.googleapis.com/mediapipe-models/audio_classifier/yamnet/float32/1/yamnet.tflite";
const SEGUNDOS_ANILLO = 5;
const VENTANA_S = 1; // YAMNet mira ventanas de ~0,975 s
const CADA_MS = 500;
const REPETIR_MS = 3000; // el mismo tipo de evento no se anota más de una vez cada 3 s

type Estado = "inactivo" | "cargando" | "escuchando" | "error";

interface Registro {
  id: number;
  hora: string;
  tipo: TipoEvento;
  clase: string;
  score: number;
  compuerta: boolean;
}

export function Escucha() {
  const [estado, setEstado] = useState<Estado>("inactivo");
  const [error, setError] = useState("");
  const [db, setDb] = useState(-100);
  const [fondo, setFondo] = useState(-100);
  const [disparo, setDisparo] = useState(false);
  const [top, setTop] = useState<Categoria[]>([]);
  const [registro, setRegistro] = useState<Registro[]>([]);
  const detener = useRef<() => void>(() => {});

  useEffect(() => () => detener.current(), []);

  async function empezar() {
    setEstado("cargando");
    setError("");
    try {
      const { AudioClassifier, FilesetResolver } = await import("@mediapipe/tasks-audio");
      const fileset = await FilesetResolver.forAudioTasks(WASM);
      const clasificador = await AudioClassifier.createFromOptions(fileset, {
        baseOptions: { modelAssetPath: MODELO },
        maxResults: 10,
      });

      // Sin cancelación de eco ni supresión de ruido: esos filtros se comen justo los golpes.
      const stream = await navigator.mediaDevices.getUserMedia({
        audio: { echoCancellation: false, noiseSuppression: false, autoGainControl: false },
      });
      const ctx = new AudioContext();
      await ctx.resume();
      const fuente = ctx.createMediaStreamSource(stream);
      const proc = ctx.createScriptProcessor(4096, 1, 1);
      const mudo = ctx.createGain();
      mudo.gain.value = 0;
      fuente.connect(proc);
      proc.connect(mudo);
      mudo.connect(ctx.destination);

      const anillo = new Anillo(ctx.sampleRate * SEGUNDOS_ANILLO);
      const lineaBase = new LineaBase();
      const compuerta = new Compuerta();
      let nivel = -100;
      let abierta = false;

      // Lo barato corre con cada bloque de audio; el modelo, dos veces por segundo.
      proc.onaudioprocess = (e) => {
        const bloque = e.inputBuffer.getChannelData(0);
        anillo.escribir(bloque);
        nivel = rmsDb(bloque);
        abierta = compuerta.evaluar(nivel, lineaBase.actualizar(nivel), performance.now());
      };

      const ultimaVez = new Map<TipoEvento, number>();
      let siguienteId = 0;
      const intervalo = window.setInterval(() => {
        setDb(nivel);
        setFondo(lineaBase.actual);
        setDisparo(abierta);
        const ventana = anillo.ultimas(ctx.sampleRate * VENTANA_S);
        if (ventana.length < ctx.sampleRate * 0.5) return;
        const trozos = clasificador
          .classify(ventana, ctx.sampleRate)
          .map((r) => r.classifications[0]?.categories ?? []);
        const categorias = unirCategorias(trozos);
        setTop(categorias.slice(0, 5));
        const ev = eventoDe(categorias);
        const ahora = performance.now();
        if (!ev || ahora - (ultimaVez.get(ev.tipo) ?? -Infinity) < REPETIR_MS) return;
        ultimaVez.set(ev.tipo, ahora);
        const fila = { id: siguienteId++, hora: new Date().toLocaleTimeString("es-VE"), ...ev, compuerta: abierta };
        setRegistro((r) => [fila, ...r].slice(0, 50));
      }, CADA_MS);

      let wakeLock: WakeLockSentinel | undefined;
      try {
        wakeLock = await navigator.wakeLock?.request("screen");
      } catch {
        // Sin wake lock la pantalla se apaga, pero la prueba sigue sirviendo.
      }

      detener.current = () => {
        window.clearInterval(intervalo);
        proc.onaudioprocess = null;
        fuente.disconnect();
        proc.disconnect();
        stream.getTracks().forEach((t) => t.stop());
        void ctx.close();
        clasificador.close();
        void wakeLock?.release();
        detener.current = () => {};
      };
      setEstado("escuchando");
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e));
      setEstado("error");
    }
  }

  function parar() {
    detener.current();
    setEstado("inactivo");
    setDisparo(false);
  }

  const sobreFondo = Math.max(0, db - fondo);

  return (
    <main className="mx-auto flex w-full max-w-md flex-col gap-6 px-4 py-8 font-sans">
      <header className="flex flex-col gap-1">
        <h1 className="text-2xl font-semibold">Escucha</h1>
        <p className="text-sm text-zinc-600 dark:text-zinc-400">
          Prueba de viabilidad. El audio se analiza en este teléfono y no sale de aquí.
        </p>
      </header>

      {estado === "escuchando" ? (
        <button onClick={parar} className="rounded-lg bg-zinc-200 px-4 py-3 font-medium dark:bg-zinc-800">
          Detener
        </button>
      ) : (
        <button
          onClick={empezar}
          disabled={estado === "cargando"}
          className="rounded-lg bg-black px-4 py-3 font-medium text-white disabled:opacity-50 dark:bg-white dark:text-black"
        >
          {estado === "cargando" ? "Cargando el modelo…" : "Empezar a escuchar"}
        </button>
      )}
      {estado === "error" && <p className="text-sm text-red-600">No se pudo empezar: {error}</p>}

      <section className="flex flex-col gap-2">
        <div className="flex items-baseline justify-between">
          <span className="text-4xl font-semibold tabular-nums">{db.toFixed(0)} dB</span>
          <span className="text-sm tabular-nums text-zinc-500">fondo {fondo.toFixed(0)} dB</span>
        </div>
        <div className="h-3 overflow-hidden rounded bg-zinc-200 dark:bg-zinc-800">
          <div
            className={`h-full ${disparo ? "bg-red-500" : "bg-zinc-500"}`}
            style={{ width: `${Math.min(100, (sobreFondo / 40) * 100)}%` }}
          />
        </div>
        <p className={`text-sm font-medium ${disparo ? "text-red-600" : "text-zinc-500"}`}>
          {disparo ? "Disparo: salto de más de 15 dB sobre el fondo" : "Sin disparo"}
        </p>
      </section>

      <section className="flex flex-col gap-2">
        <h2 className="text-sm font-medium text-zinc-500">Lo que oye ahora (YAMNet)</h2>
        {top.length === 0 && <p className="text-sm text-zinc-500">—</p>}
        {top.map((c) => (
          <div key={c.categoryName} className="flex items-center gap-2 text-sm">
            <span className="w-40 truncate">{c.categoryName}</span>
            <div className="h-2 flex-1 overflow-hidden rounded bg-zinc-200 dark:bg-zinc-800">
              <div className="h-full bg-zinc-500" style={{ width: `${c.score * 100}%` }} />
            </div>
            <span className="w-10 text-right tabular-nums">{(c.score * 100).toFixed(0)}%</span>
          </div>
        ))}
      </section>

      <section className="flex flex-col gap-2">
        <h2 className="text-sm font-medium text-zinc-500">Eventos</h2>
        {registro.length === 0 && (
          <p className="text-sm text-zinc-500">
            Prueba: reproduce una alarma de humo o un vidrio que se rompe, golpea la mesa, grita, prende la TV.
          </p>
        )}
        <ul className="flex flex-col gap-1">
          {registro.map((r) => (
            <li key={r.id} className="flex items-center gap-2 text-sm">
              <span className="w-20 tabular-nums text-zinc-500">{r.hora}</span>
              <span className={`font-medium ${ES_ALERTA[r.tipo] ? "text-red-600" : ""}`}>{ETIQUETA[r.tipo]}</span>
              <span className="flex-1 truncate text-zinc-500">
                {r.clase} {(r.score * 100).toFixed(0)}%
              </span>
              <span className="text-xs text-zinc-500">{r.compuerta ? "con disparo" : "sin disparo"}</span>
            </li>
          ))}
        </ul>
      </section>
    </main>
  );
}
