# 📊 En Casa — Dashboard Web (TypeScript & JavaScript ESM)

Tablero analítico interactivo con arquitectura profesional desacoplada en **TypeScript**, **JavaScript (ES Modules)**, **CSS3 Moderno** y **Chart.js**.

---

## 🏗️ Arquitectura del Proyecto

```
dashboard/
├── index.html            # Estructura semántica HTML5 limpia
├── package.json          # Configuración del proyecto npm
├── tsconfig.json         # Configuración del compilador TypeScript
├── styles/
│   └── main.css          # Estilos desacoplados (Glassmorphism, Variables CSS, Grid)
├── src/                  # CÓDIGO FUENTE TYPESCRIPT (Tipado estricto)
│   ├── types.ts          # Interfaces y contratos de datos
│   ├── data.ts           # Series de datos con su fuente citada
│   ├── charts.ts         # Controladores de visualización Chart.js tipados
│   └── app.ts            # Orquestador principal de eventos y ciclo de vida
└── js/                   # BUILD / ES MODULES (compilado y versionado)
    ├── types.js
    ├── data.js           # Módulo de datos
    ├── charts.js         # Módulo de gráficas
    └── app.js            # Módulo principal cargado por index.html
```

---

## 🚀 Cómo Ejecutar

Debido a que el navegador utiliza **ES Modules** nativos (`import`/`export`), se recomienda servirlo con un servidor HTTP local para evitar restricciones locales de CORS:

### Opción 1 (Recomendada con Python):
```bash
cd dashboard
python3 -m http.server 8080
```
Luego abre tu navegador en: **`http://localhost:8080`**

### Opción 2 (Con Node/NPM si lo deseas):
```bash
cd dashboard
npm run serve
```

`js/` ya está compilado y versionado en el repositorio: para ver el dashboard no hace falta instalar nada, solo servir los archivos. Solo compila si editas `src/*.ts`.

---

## 🛠️ Desarrollo en TypeScript

Si deseas modificar el código fuente en TypeScript (`src/*.ts`):

1. **Instalar dependencias de desarrollo:**
   ```bash
   npm install
   ```
2. **Compilar los archivos TypeScript hacia `js/`:**
   ```bash
   npm run build
   ```
3. **Compilación continua (Watch mode):**
   ```bash
   npm run watch
   ```

---

## 📌 Principales Componentes

| Archivo | Responsabilidad |
|---|---|
| [`src/types.ts`](src/types.ts) | Define las interfaces TypeScript: `KPIItem`, `MigrationTimeline`, `GlobalImpactStats`, `ScalabilityMarket`, etc. |
| [`src/data.ts`](src/data.ts) | Almacena y exporta las series de datos con su fuente citada. |
| [`src/charts.ts`](src/charts.ts) | Encapsula la creación, destrucción reactiva y renderizado de gráficos con Chart.js y DataLabels. |
| [`src/app.ts`](src/app.ts) | Maneja el DOM, cambios de pestaña, filtros cronológicos y renderizado dinámico. |
| [`styles/main.css`](styles/main.css) | Sistema de diseño oscuro con variables CSS, animaciones fluidas y soporte responsivo. |

---

## 📎 Fuentes y límites

- **Verificado:** los datos que llevan fuente citada (OMS, ACNUR/R4V, Banco Mundial/WPP 2024, Convite AC, ENCOVI, CDC, literatura médica) se comprobaron en la fuente enlazada a octubre de 2026.
- **Estimación propia del equipo:** las cifras marcadas en la interfaz como *estimación propia* (mercado potencial por región, % de mayores solos por región, tiempos de auxilio e índice de vulnerabilidad por estado) las construyó el equipo y no provienen de ningún organismo.
- **Estimaciones y encuestas, no estadística oficial:** las cifras de ONG (Convite AC, ENCOVI) y de encuestas (U.S. News & World Report) son estimaciones o sondeos, no estadística oficial; conviene leerlas como tales al presentarlas.
- El detalle de cada fuente está en la sección **Fuentes y Referencias** del dashboard y en [`investigacion_sustento_problematica.md`](investigacion_sustento_problematica.md), que es un documento interno con material sin auditar.
