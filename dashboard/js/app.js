import { KPI_MAIN, KPI_MAYORES, FLOW_STEPS, SYSTEM_LAYERS, PROGRESS_ITEMS, REFERENCES } from "./data.js";
import { drawMigracion, drawPaises, drawGlobalCharts, drawMayores, drawRespuesta, drawEstados, drawGauge } from "./charts.js";
export function buildKPIGrid(containerId, data) {
    const el = document.getElementById(containerId);
    if (!el)
        return;
    el.innerHTML = data
        .map(k => `
    <div class="kpi" style="--accent-color:${k.color};">
      <span class="kpi-icon">${k.icon}</span>
      <div class="kpi-val counter" data-val="${k.val}">${k.val}</div>
      <div class="kpi-label">${k.label}</div>
      <div class="kpi-sub">${k.sub}</div>
    </div>`)
        .join("");
}
export function buildProgBars() {
    const c = document.getElementById("prog-container");
    if (!c)
        return;
    c.innerHTML = PROGRESS_ITEMS.map(it => `
    <div class="prog-row">
      <div class="prog-header">
        <span class="prog-label">${it.label}</span>
        <span class="prog-val" style="color:${it.color}">${it.val}%</span>
      </div>
      <div class="prog-track">
        <div class="prog-fill" style="width:0%;background:${it.color}" data-target="${it.val}"></div>
      </div>
    </div>`).join("");
    setTimeout(() => {
        document.querySelectorAll(".prog-fill").forEach(el => {
            if (el.dataset.target) {
                el.style.width = el.dataset.target + "%";
            }
        });
    }, 100);
}
export function buildFallsCards() {
    const c = document.getElementById("grid-caidas");
    if (!c)
        return;
    const cards = [
        { icon: "💀", val: "842.000", label: "Muertes por caída al año", sub: "2ª causa de muerte por lesión · OMS · Global Health Estimates 2023", color: "#f87171" },
        { icon: "🧓", val: "28-35 %", label: "Caen cada año (65+)", sub: "OMS · Global Report on Falls 2007", color: "#fbbf24" },
        { icon: "⏳", val: "30 %", label: "Mayores de 90 que caen: >1 h en el suelo", sub: "Fleming & Brayne · BMJ 2008", color: "#a78bfa" }
    ];
    c.innerHTML = cards
        .map(k => `
    <div class="kpi" style="--accent-color:${k.color};">
      <span class="kpi-icon">${k.icon}</span>
      <div class="kpi-val">${k.val}</div>
      <div class="kpi-label">${k.label}</div>
      <div class="kpi-sub">${k.sub}</div>
    </div>`)
        .join("");
}
export function buildFlow() {
    const c = document.getElementById("flow-container");
    if (!c)
        return;
    c.className = "flow-grid";
    c.innerHTML = FLOW_STEPS.map((s, i) => `
    <div class="flow-card">
      <div class="flow-card-header">
        <span class="flow-badge">${s.badge}</span>
        <span class="flow-step-num">${i + 1}</span>
      </div>
      <div class="flow-icon">${s.icon}</div>
      <div class="flow-fase">${s.fase}</div>
      <h4 class="flow-title">${s.title}</h4>
      <p class="flow-desc">${s.desc}</p>
    </div>`).join("");
}
export function buildLayers() {
    const c = document.getElementById("layers-container");
    if (!c)
        return;
    c.className = "layers-grid";
    c.innerHTML = SYSTEM_LAYERS.map(layer => `
    <div class="layer-card">
      <h4 class="layer-title">${layer.title}</h4>
      <ul class="layer-list">
        ${layer.items.map(item => `<li><span class="bullet">›</span> ${item}</li>`).join("")}
      </ul>
    </div>`).join("");
}
export function buildReferences() {
    const c = document.getElementById("references-container");
    if (!c)
        return;
    c.innerHTML = REFERENCES.map(r => `
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
    </details>`).join("");
}
export const SECTION_DRAWERS = {
    panorama: () => {
        drawMigracion();
        drawPaises();
        drawGlobalCharts();
    },
    mayores: () => {
        drawMayores();
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
export function showSection(id, el) {
    document.querySelectorAll(".section").forEach(s => s.classList.remove("active"));
    document.querySelectorAll(".nav-item").forEach(n => n.classList.remove("active"));
    const targetSec = document.getElementById("sec-" + id);
    if (targetSec)
        targetSec.classList.add("active");
    if (el) {
        el.classList.add("active");
    }
    else {
        const defaultNav = document.querySelector(`.nav-item[data-section="${id}"]`);
        if (defaultNav)
            defaultNav.classList.add("active");
    }
    if (SECTION_DRAWERS[id]) {
        setTimeout(SECTION_DRAWERS[id], 50);
    }
}
export function redrawCharts() {
    const fromEl = document.getElementById("yearFrom");
    const toEl = document.getElementById("yearTo");
    const from = parseInt((fromEl && fromEl.value) || "2015");
    const to = parseInt((toEl && toEl.value) || "2024");
    drawMigracion(from, to);
}
// Inicialización de la aplicación
export function init() {
    if (typeof lucide !== "undefined") {
        lucide.createIcons();
    }
    if (typeof Chart !== "undefined" && typeof ChartDataLabels !== "undefined") {
        Chart.register(ChartDataLabels);
    }
    buildKPIGrid("kpi-grid", KPI_MAIN);
    buildKPIGrid("kpi-mayores-grid", KPI_MAYORES);
    // Vincular eventos de navegación
    document.querySelectorAll(".nav-item").forEach(item => {
        item.addEventListener("click", () => {
            const sec = item.dataset.section;
            if (sec)
                showSection(sec, item);
        });
    });
    // Vincular selectores de filtros de fecha
    const yearFrom = document.getElementById("yearFrom");
    const yearTo = document.getElementById("yearTo");
    if (yearFrom)
        yearFrom.addEventListener("change", redrawCharts);
    if (yearTo)
        yearTo.addEventListener("change", redrawCharts);
    // Cargar sección inicial
    SECTION_DRAWERS["panorama"]();
}
window.addEventListener("DOMContentLoaded", init);
