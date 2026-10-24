import {
  MIGRATION_DATA,
  COUNTRIES_DATA,
  AGES_DATA,
  GLOBAL_ELDERLY_DATA,
  ESCALABILIDAD_DATA,
  MAYORES_DATA,
  ACCIDENTS_DATA,
  RESPUESTA_DATA,
  ESTADOS_DATA
} from "./data.js";

// Declaración ambiental para librerías globales de CDN
declare const Chart: any;
declare const ChartDataLabels: any;

export interface ChartRegistry {
  [key: string]: any;
}

export const charts: ChartRegistry = {};

export const CHART_DEFAULTS = {
  color: "#94a3b8",
  grid: "rgba(45,53,97,.5)",
  bg: "transparent"
};

export function baseOpts(extra: Record<string, any> = {}): Record<string, any> {
  return {
    responsive: true,
    maintainAspectRatio: true,
    plugins: {
      legend: {
        labels: {
          color: CHART_DEFAULTS.color,
          font: { family: "Inter", size: 11 },
          boxWidth: 12
        }
      },
      tooltip: {
        backgroundColor: "rgba(13,18,32,.95)",
        borderColor: "#1e2d45",
        borderWidth: 1,
        titleColor: "#e2e8f0",
        bodyColor: "#94a3b8",
        cornerRadius: 10,
        titleFont: { family: "Inter", weight: "700" },
        bodyFont: { family: "Inter" }
      },
      datalabels: { display: false }
    },
    scales: {
      x: {
        grid: { color: CHART_DEFAULTS.grid },
        ticks: { color: CHART_DEFAULTS.color, font: { family: "Inter", size: 11 } }
      },
      y: {
        grid: { color: CHART_DEFAULTS.grid },
        ticks: { color: CHART_DEFAULTS.color, font: { family: "Inter", size: 11 } }
      }
    },
    ...extra
  };
}

export function fmt(n: number): string {
  if (n >= 1e6) return (n / 1e6).toFixed(1) + "M";
  if (n >= 1e3) return (n / 1e3).toFixed(0) + "K";
  return n.toString();
}

export function destroyChart(id: string): void {
  if (charts[id]) {
    charts[id].destroy();
    delete charts[id];
  }
}

export function drawMigracion(fromYear: number = 2015, toYear: number = 2024): void {
  destroyChart("chartMigracion");
  const canvas = document.getElementById("chartMigracion") as HTMLCanvasElement | null;
  if (!canvas) return;

  const idx = MIGRATION_DATA.labels
    .map((y, i) => (y >= fromYear && y <= toYear ? i : -1))
    .filter(i => i >= 0);

  const labels = idx.map(i => MIGRATION_DATA.labels[i]);
  const total = idx.map(i => MIGRATION_DATA.total[i]);
  const amers = idx.map(i => MIGRATION_DATA.americas[i]);

  charts["chartMigracion"] = new Chart(canvas, {
    type: "line",
    data: {
      labels,
      datasets: [
        {
          label: "Total migrantes (M)",
          data: total,
          borderColor: "#818cf8",
          backgroundColor: "rgba(129,140,248,.12)",
          borderWidth: 3,
          pointRadius: 6,
          pointBackgroundColor: "#818cf8",
          fill: true,
          tension: 0.4
        },
        {
          label: "En las Américas (M)",
          data: amers,
          borderColor: "#34d399",
          backgroundColor: "transparent",
          borderWidth: 2,
          borderDash: [6, 4],
          pointRadius: 5,
          pointBackgroundColor: "#34d399",
          fill: false,
          tension: 0.4
        }
      ]
    },
    options: baseOpts({
      plugins: {
        ...baseOpts().plugins,
        tooltip: { ...baseOpts().plugins.tooltip, mode: "index", intersect: false }
      },
      scales: {
        x: baseOpts().scales.x,
        y: { ...baseOpts().scales.y, title: { display: true, text: "Millones", color: "#64748b" } }
      }
    })
  });
}

export function drawPaises(): void {
  destroyChart("chartPaises");
  const canvas = document.getElementById("chartPaises") as HTMLCanvasElement | null;
  if (!canvas) return;

  const colors = [
    "#6366f1",
    "#818cf8",
    "#a5b4fc",
    "#34d399",
    "#22c55e",
    "#4ade80",
    "#f87171",
    "#fb923c",
    "#fbbf24",
    "#94a3b8"
  ];

  charts["chartPaises"] = new Chart(canvas, {
    type: "bar",
    data: {
      labels: COUNTRIES_DATA.labels,
      datasets: [
        {
          label: "Venezolanos",
          data: COUNTRIES_DATA.values,
          backgroundColor: colors,
          borderRadius: 6,
          borderSkipped: false
        }
      ]
    },
    options: {
      indexAxis: "y",
      ...baseOpts(),
      plugins: {
        ...baseOpts().plugins,
        legend: { display: false },
        datalabels: {
          display: true,
          color: "#94a3b8",
          font: { size: 10, family: "Inter" },
          anchor: "end",
          align: "end",
          formatter: (v: number) => fmt(v)
        }
      },
      scales: {
        x: {
          ...baseOpts().scales.x,
          ticks: { ...baseOpts().scales.x.ticks, callback: (v: number) => fmt(v) }
        },
        y: baseOpts().scales.y
      },
      layout: { padding: { right: 40 } }
    }
  });
}

export function drawEdades(): void {
  destroyChart("chartEdades");
  const canvas = document.getElementById("chartEdades") as HTMLCanvasElement | null;
  if (!canvas) return;

  charts["chartEdades"] = new Chart(canvas, {
    type: "doughnut",
    data: {
      labels: AGES_DATA.labels,
      datasets: [
        {
          data: AGES_DATA.values,
          backgroundColor: AGES_DATA.colors,
          borderColor: "#080c14",
          borderWidth: 3,
          hoverOffset: 8
        }
      ]
    },
    options: {
      cutout: "60%",
      plugins: {
        legend: {
          position: "bottom",
          labels: { color: "#94a3b8", font: { family: "Inter", size: 11 }, boxWidth: 12 }
        },
        tooltip: baseOpts().plugins.tooltip,
        datalabels: {
          display: true,
          color: "#fff",
          font: { size: 10, weight: "700", family: "Inter" },
          formatter: (v: number) => v + "%"
        }
      }
    },
    plugins: [ChartDataLabels]
  });
}

export function drawGlobalCharts(): void {
  destroyChart("chartGlobalPaises");
  destroyChart("chartEscalabilidad");

  const canvasGlobal = document.getElementById("chartGlobalPaises") as HTMLCanvasElement | null;
  if (canvasGlobal) {
    charts["chartGlobalPaises"] = new Chart(canvasGlobal, {
      type: "bar",
      data: {
        labels: GLOBAL_ELDERLY_DATA.labels,
        datasets: [
          {
            label: "% Mayores en soledad / sin apoyo filial",
            data: GLOBAL_ELDERLY_DATA.pctSolos,
            backgroundColor: GLOBAL_ELDERLY_DATA.colors,
            borderRadius: 6,
            borderSkipped: false
          }
        ]
      },
      options: {
        indexAxis: "y",
        ...baseOpts(),
        plugins: {
          ...baseOpts().plugins,
          legend: { display: false },
          datalabels: {
            display: true,
            color: "#fff",
            font: { size: 10, weight: "700", family: "Inter" },
            anchor: "end",
            align: "end",
            formatter: (v: number) => v + "%"
          }
        },
        scales: {
          x: {
            ...baseOpts().scales.x,
            max: 45,
            ticks: { ...baseOpts().scales.x.ticks, callback: (v: number) => v + "%" }
          },
          y: {
            ...baseOpts().scales.y,
            ticks: { ...baseOpts().scales.y.ticks, font: { size: 10.5, family: "Inter" } }
          }
        },
        layout: { padding: { right: 35 } }
      },
      plugins: [ChartDataLabels]
    });
  }

  const canvasEscala = document.getElementById("chartEscalabilidad") as HTMLCanvasElement | null;
  if (canvasEscala) {
    charts["chartEscalabilidad"] = new Chart(canvasEscala, {
      type: "bar",
      data: {
        labels: ESCALABILIDAD_DATA.labels,
        datasets: [
          {
            label: "Millones de mayores en riesgo",
            data: ESCALABILIDAD_DATA.millones,
            backgroundColor: ESCALABILIDAD_DATA.colors,
            borderRadius: 8,
            borderSkipped: false
          }
        ]
      },
      options: {
        ...baseOpts(),
        plugins: {
          ...baseOpts().plugins,
          legend: { display: false },
          datalabels: {
            display: true,
            color: "#fff",
            font: { size: 11, weight: "700", family: "Inter" },
            anchor: "end",
            align: "top",
            formatter: (v: number) => v + " M"
          }
        },
        scales: {
          x: { ...baseOpts().scales.x, ticks: { ...baseOpts().scales.x.ticks, font: { size: 10 } } },
          y: {
            ...baseOpts().scales.y,
            max: 15,
            title: { display: true, text: "Millones de personas", color: "#64748b" }
          }
        },
        layout: { padding: { top: 25 } }
      },
      plugins: [ChartDataLabels]
    });
  }
}

export function drawMayores(): void {
  destroyChart("chartMayores");
  const canvas = document.getElementById("chartMayores") as HTMLCanvasElement | null;
  if (!canvas) return;

  charts["chartMayores"] = new Chart(canvas, {
    type: "bar",
    data: {
      labels: MAYORES_DATA.labels,
      datasets: [
        {
          label: "% de adultos mayores",
          data: MAYORES_DATA.values,
          backgroundColor: MAYORES_DATA.colors,
          borderRadius: 6,
          borderSkipped: false
        }
      ]
    },
    options: {
      indexAxis: "y",
      ...baseOpts(),
      plugins: {
        ...baseOpts().plugins,
        legend: { display: false },
        datalabels: {
          display: true,
          color: "#fff",
          font: { size: 10, weight: "700", family: "Inter" },
          anchor: "end",
          align: "end",
          formatter: (v: number) => v + "%"
        }
      },
      scales: {
        x: {
          ...baseOpts().scales.x,
          max: 100,
          ticks: { ...baseOpts().scales.x.ticks, callback: (v: number) => v + "%" }
        },
        y: {
          ...baseOpts().scales.y,
          ticks: { ...baseOpts().scales.y.ticks, font: { size: 10, family: "Inter" } }
        }
      },
      layout: { padding: { right: 35 } }
    },
    plugins: [ChartDataLabels]
  });
}

export function drawAccidentes(): void {
  destroyChart("chartAccidentes");
  const canvas = document.getElementById("chartAccidentes") as HTMLCanvasElement | null;
  if (!canvas) return;

  charts["chartAccidentes"] = new Chart(canvas, {
    type: "polarArea",
    data: {
      labels: ACCIDENTS_DATA.labels,
      datasets: [
        {
          data: ACCIDENTS_DATA.values,
          backgroundColor: ACCIDENTS_DATA.colors.map(c => c + "cc"),
          borderColor: ACCIDENTS_DATA.colors,
          borderWidth: 2
        }
      ]
    },
    options: {
      plugins: {
        legend: {
          position: "right",
          labels: { color: "#94a3b8", font: { family: "Inter", size: 10 }, boxWidth: 12 }
        },
        tooltip: baseOpts().plugins.tooltip,
        datalabels: {
          display: true,
          color: "#fff",
          font: { size: 11, weight: "700", family: "Inter" },
          formatter: (v: number) => v + "%"
        }
      },
      scales: {
        r: {
          grid: { color: "rgba(45,53,97,.4)" },
          ticks: { color: "#64748b", backdropColor: "transparent", font: { size: 9 } }
        }
      }
    },
    plugins: [ChartDataLabels]
  });
}

export function drawRespuesta(): void {
  destroyChart("chartRespuesta");
  const canvas = document.getElementById("chartRespuesta") as HTMLCanvasElement | null;
  if (!canvas) return;

  charts["chartRespuesta"] = new Chart(canvas, {
    type: "bar",
    data: {
      labels: RESPUESTA_DATA.labels,
      datasets: [
        {
          data: RESPUESTA_DATA.values,
          backgroundColor: RESPUESTA_DATA.colors,
          borderRadius: 10,
          borderSkipped: false
        }
      ]
    },
    options: {
      ...baseOpts(),
      plugins: {
        ...baseOpts().plugins,
        legend: { display: false },
        datalabels: {
          display: true,
          color: "#fff",
          font: { size: 13, weight: "800", family: "Inter" },
          anchor: "center",
          align: "center",
          formatter: (v: number) => v + " min"
        }
      },
      scales: {
        x: {
          ...baseOpts().scales.x,
          ticks: { ...baseOpts().scales.x.ticks, maxRotation: 0, font: { size: 10 } }
        },
        y: {
          ...baseOpts().scales.y,
          title: { display: true, text: "Minutos", color: "#64748b" }
        }
      }
    },
    plugins: [ChartDataLabels]
  });
}

export function drawEstados(): void {
  destroyChart("chartEstados");
  const canvas = document.getElementById("chartEstados") as HTMLCanvasElement | null;
  if (!canvas) return;

  charts["chartEstados"] = new Chart(canvas, {
    type: "bar",
    data: {
      labels: ESTADOS_DATA.labels,
      datasets: [
        {
          type: "bar",
          label: "Índice de vulnerabilidad",
          data: ESTADOS_DATA.vulnIdx,
          backgroundColor: "rgba(129,140,248,.7)",
          borderColor: "#818cf8",
          borderWidth: 2,
          borderRadius: 6,
          yAxisID: "y"
        },
        {
          type: "line",
          label: "% hijos en exterior",
          data: ESTADOS_DATA.hijosExt,
          borderColor: "#f87171",
          backgroundColor: "transparent",
          borderWidth: 2,
          pointRadius: 6,
          pointBackgroundColor: "#f87171",
          tension: 0.35,
          yAxisID: "y2"
        }
      ]
    },
    options: {
      ...baseOpts(),
      plugins: {
        ...baseOpts().plugins,
        legend: {
          display: true,
          labels: { color: "#94a3b8", font: { family: "Inter", size: 11 }, boxWidth: 12 }
        }
      },
      scales: {
        x: baseOpts().scales.x,
        y: {
          ...baseOpts().scales.y,
          position: "left",
          title: { display: true, text: "Índice (0–100)", color: "#64748b" }
        },
        y2: {
          ...baseOpts().scales.y,
          position: "right",
          title: { display: true, text: "% hijos en exterior", color: "#64748b" },
          grid: { display: false }
        }
      }
    }
  });
}

export function drawGauge(): void {
  destroyChart("chartGauge");
  const canvas = document.getElementById("chartGauge") as HTMLCanvasElement | null;
  if (!canvas) return;

  charts["chartGauge"] = new Chart(canvas, {
    type: "bar",
    data: {
      labels: [
        "Con En Casa 🟢",
        "Con llamada manual 🟡",
        "Sin sistema de auxilio 🔴"
      ],
      datasets: [
        {
          label: "Minutos hasta auxilio",
          data: [2, 22, 47],
          backgroundColor: [
            "#22c55e",
            "#fbbf24",
            "#ef4444"
          ],
          borderRadius: 8,
          borderSkipped: false
        }
      ]
    },
    options: {
      indexAxis: "y",
      ...baseOpts(),
      plugins: {
        ...baseOpts().plugins,
        legend: { display: false },
        datalabels: {
          display: true,
          color: "#fff",
          font: { size: 11, weight: "800", family: "Inter" },
          anchor: "end",
          align: "end",
          formatter: (v: number) => v + " min"
        }
      },
      scales: {
        x: {
          ...baseOpts().scales.x,
          max: 55,
          ticks: {
            ...baseOpts().scales.x.ticks,
            callback: (v: number) => v + " min"
          },
          title: {
            display: true,
            text: "Minutos promedio transcurridos",
            color: "#64748b",
            font: { family: "Inter", size: 10 }
          }
        },
        y: {
          ...baseOpts().scales.y,
          ticks: {
            ...baseOpts().scales.y.ticks,
            font: { size: 11, family: "Inter", weight: "600" }
          }
        }
      },
      layout: { padding: { right: 55 } }
    },
    plugins: [ChartDataLabels]
  });
}
