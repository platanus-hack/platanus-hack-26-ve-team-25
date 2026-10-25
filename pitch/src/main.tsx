import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import App from "./App";
import "./estilos/globals.css";

const raiz = document.getElementById("raiz");
if (!raiz) {
  throw new Error("No se encontró el elemento #raiz en el DOM");
}

createRoot(raiz).render(
  <StrictMode>
    <App />
  </StrictMode>
);
