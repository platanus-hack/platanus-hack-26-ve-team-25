# 📊 En Casa — Dashboard Web (TypeScript & JavaScript ESM)

Tablero analítico interactivo con arquitectura profesional desacoplada en **TypeScript**, **JavaScript (ES Modules)**, **CSS3 Moderno** y **Chart.js**.

---

## 🏗️ Arquitectura del Proyecto

```
dashboard2/
├── index.html            # Estructura semántica HTML5 limpia
├── package.json          # Configuración del proyecto npm
├── tsconfig.json         # Configuración del compilador TypeScript
├── styles/
│   └── main.css          # Estilos desacoplados (Glassmorphism, Variables CSS, Grid)
├── src/                  # CÓDIGO FUENTE TYPESCRIPT (Tipado estricto)
│   ├── types.ts          # Interfaces y contratos de datos
│   ├── data.ts           # Datasets verificados (ACNUR, OIM, HelpAge, OMS)
│   ├── charts.ts         # Controladores de visualización Chart.js tipados
│   └── app.ts            # Orquestador principal de eventos y ciclo de vida
└── js/                   # BUILD / ES MODULES (Ejecución directa en navegador)
    ├── data.js           # Módulo de datos
    ├── charts.js         # Módulo de gráficas
    └── app.js            # Módulo principal cargado por index.html
```

---

## 🚀 Cómo Ejecutar

Debido a que el navegador utiliza **ES Modules** nativos (`import`/`export`), se recomienda servirlo con un servidor HTTP local para evitar restricciones locales de CORS:

### Opción 1 (Recomendada con Python):
```bash
cd ~/Escritorio/hackaton/dashboard
python3 -m http.server 8080
```
Luego abre tu navegador en: **`http://localhost:8080`**

### Opción 2 (Con Node/NPM si lo deseas):
```bash
cd ~/Escritorio/hackaton/dashboard
npm run serve
```

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
| [`src/types.ts`](file:///home/rodelo/Escritorio/hackaton/dashboard2/src/types.ts) | Define las interfaces TypeScript: `KPIItem`, `MigrationTimeline`, `GlobalImpactStats`, `ScalabilityMarket`, etc. |
| [`src/data.ts`](file:///home/rodelo/Escritorio/hackaton/dashboard2/src/data.ts) | Almacena y exporta las series de datos verificadas con fuentes de organismos oficiales. |
| [`src/charts.ts`](file:///home/rodelo/Escritorio/hackaton/dashboard2/src/charts.ts) | Encapsula la creación, destrucción reactiva y renderizado de gráficos con Chart.js y DataLabels. |
| [`src/app.ts`](file:///home/rodelo/Escritorio/hackaton/dashboard2/src/app.ts) | Maneja el DOM, cambios de pestaña, filtros cronológicos y renderizado dinámico. |
| [`styles/main.css`](file:///home/rodelo/Escritorio/hackaton/dashboard2/styles/main.css) | Sistema de diseño oscuro con variables CSS, animaciones fluidas y soporte responsivo. |
