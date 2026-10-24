import {
  KPI_MAIN,
  KPI_MAYORES,
  FLOW_STEPS,
  SYSTEM_LAYERS,
  PROGRESS_ITEMS,
  REFERENCES
} from "./data.js";
import {
  drawMigracion,
  drawPaises,
  drawEdades,
  drawGlobalCharts,
  drawMayores,
  drawAccidentes,
  drawRespuesta,
  drawEstados,
  drawGauge
} from "./charts.js";
import { KPIItem } from "./types.js";

declare const Chart: any;
declare const ChartDataLabels: any;
declare const lucide: any;

export function buildKPIGrid(containerId: string, data: KPIItem[]): void {
  const el = document.getElementById(containerId);
  if (!el) return;
  el.innerHTML = data
    .map(
      k => `
    <div class="kpi" style="--accent-color:${k.color};">
      <span class="kpi-icon">${k.icon}</span>
      <div class="kpi-val counter" data-val="${k.val}">${k.val}</div>
      <div class="kpi-label">${k.label}</div>
      <div class="kpi-sub">${k.sub}</div>
    </div>`
    )
    .join("");
}

export function buildProgBars(): void {
  const c = document.getElementById("prog-container");
  if (!c) return;
  c.innerHTML = PROGRESS_ITEMS.map(
    it => `
    <div class="prog-row">
      <div class="prog-header">
        <span class="prog-label">${it.label}</span>
        <span class="prog-val" style="color:${it.color}">${it.val}%</span>
      </div>
      <div class="prog-track">
        <div class="prog-fill" style="width:0%;background:${it.color}" data-target="${it.val}"></div>
      </div>
    </div>`
  ).join("");

  setTimeout(() => {
    document.querySelectorAll<HTMLElement>(".prog-fill").forEach(el => {
      if (el.dataset.target) {
        el.style.width = el.dataset.target + "%";
      }
    });
  }, 100);
}

export function buildFallsCards(): void {
  const c = document.getElementById("grid-caidas");
  if (!c) return;
  const cards: KPIItem[] = [
    { icon: "💀", val: "842.000", label: "Muertes por caída al año", sub: "2ª causa de muerte por lesión · OMS", color: "#f87171" },
    { icon: "🧓", val: "1 de 3", label: "Adultos 65+ cae cada año", sub: "30–40% de esta población · OMS/NIH", color: "#fbbf24" },
    { icon: "⏳", val: "1 de 5", label: "Queda >1 hora solo", sub: "Riesgo de muerte se duplica · NIH", color: "#a78bfa" }
  ];
  c.innerHTML = cards
    .map(
      k => `
    <div class="kpi" style="--accent-color:${k.color};">
      <span class="kpi-icon">${k.icon}</span>
      <div class="kpi-val">${k.val}</div>
      <div class="kpi-label">${k.label}</div>
      <div class="kpi-sub">${k.sub}</div>
    </div>`
    )
    .join("");
}

export function buildFlow(): void {
  const c = document.getElementById("flow-container");
  if (!c) return;
  c.className = "flow-grid";
  c.innerHTML = FLOW_STEPS.map(
    (s, i) => `
    <div class="flow-card">
      <div class="flow-card-header">
        <span class="flow-badge">${s.badge}</span>
        <span class="flow-step-num">${i + 1}</span>
      </div>
      <div class="flow-icon">${s.icon}</div>
      <div class="flow-fase">${s.fase}</div>
      <h4 class="flow-title">${s.title}</h4>
      <p class="flow-desc">${s.desc}</p>
    </div>`
  ).join("");
}

export function buildLayers(): void {
  const c = document.getElementById("layers-container");
  if (!c) return;
  c.className = "layers-grid";
  c.innerHTML = SYSTEM_LAYERS.map(
    layer => `
    <div class="layer-card">
      <h4 class="layer-title">${layer.title}</h4>
      <ul class="layer-list">
        ${layer.items.map(item => `<li><span class="bullet">›</span> ${item}</li>`).join("")}
      </ul>
    </div>`
  ).join("");
}

export function buildReferences(): void {
  const c = document.getElementById("references-container");
  if (!c) return;
  c.innerHTML = REFERENCES.map(
    r => `
    <details class="ref-item">
      <summary>
        <div>
          <span style="margin-right:.5rem;">${r.icon}</span>
          <span class="ref-title">${r.title}</span>
        </div>
        <span class="ref-year">${r.year}</span>
      </summary>
      <div class="ref-body">
        <p class="ref-desc">${r.desc}</p>
        <a class="ref-url" href="${r.url}" target="_blank" rel="noopener">🔗 ${r.url}</a>
      </div>
    </details>`
  ).join("");
}

export const SECTION_DRAWERS: Record<string, () => void> = {
  panorama: () => {
    drawMigracion();
    drawPaises();
    drawEdades();
    drawGlobalCharts();
  },
  mayores: () => {
    drawMayores();
    drawAccidentes();
    drawRespuesta();
    drawEstados();
    buildProgBars();
    buildFallsCards();
  },
  solucion: () => {
    buildFlow();
    buildLayers();
    drawGauge();
  },
  fuentes: () => {
    buildReferences();
  }
};

export function showSection(id: string, el?: HTMLElement | null): void {
  document.querySelectorAll(".section").forEach(s => s.classList.remove("active"));
  document.querySelectorAll(".nav-item").forEach(n => n.classList.remove("active"));

  const targetSec = document.getElementById("sec-" + id);
  if (targetSec) targetSec.classList.add("active");

  if (el) {
    el.classList.add("active");
  } else {
    const defaultNav = document.querySelector<HTMLElement>(`.nav-item[data-section="${id}"]`);
    if (defaultNav) defaultNav.classList.add("active");
  }

  if (SECTION_DRAWERS[id]) {
    setTimeout(SECTION_DRAWERS[id], 50);
  }
}

export function redrawCharts(): void {
  const fromEl = document.getElementById("yearFrom") as HTMLSelectElement | null;
  const toEl = document.getElementById("yearTo") as HTMLSelectElement | null;
  const from = parseInt((fromEl && fromEl.value) || "2015");
  const to = parseInt((toEl && toEl.value) || "2024");
  drawMigracion(from, to);
}

// Inicialización de la aplicación
export function init(): void {
  if (typeof lucide !== "undefined") {
    lucide.createIcons();
  }

  if (typeof Chart !== "undefined" && typeof ChartDataLabels !== "undefined") {
    Chart.register(ChartDataLabels);
  }

  buildKPIGrid("kpi-grid", KPI_MAIN);
  buildKPIGrid("kpi-mayores-grid", KPI_MAYORES);

  // Vincular eventos de navegación
  document.querySelectorAll<HTMLElement>(".nav-item").forEach(item => {
    item.addEventListener("click", () => {
      const sec = item.dataset.section;
      if (sec) showSection(sec, item);
    });
  });

  // Vincular selectores de filtros de fecha
  const yearFrom = document.getElementById("yearFrom");
  const yearTo = document.getElementById("yearTo");
  if (yearFrom) yearFrom.addEventListener("change", redrawCharts);
  if (yearTo) yearTo.addEventListener("change", redrawCharts);

  // Cargar sección inicial
  SECTION_DRAWERS["panorama"]();
}

window.addEventListener("DOMContentLoaded", init);
