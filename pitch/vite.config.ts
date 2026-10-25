import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

// Configuración mínima. Nada de CDN, nada externo: el venue puede no tener wifi.
export default defineConfig({
  plugins: [react()],
  server: { port: 4173 },
  preview: { port: 4173 },
  build: {
    target: "es2022",
    sourcemap: false,
    // Un solo chunk, sin splitting innecesario para una presentación estática.
    rollupOptions: {
      output: {
        manualChunks: undefined,
      },
    },
  },
});
