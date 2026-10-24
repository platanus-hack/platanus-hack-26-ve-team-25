// La factura de la farmacia: lo que Claude lee de la foto y cómo se cruza con el récipe. Claude lee,
// el código cruza y la familia confirma. Cruzar no se le deja al modelo: así se prueba sin red y la
// regla «lo que no está en el récipe no se guarda» es una función que se puede leer.
import { z } from "zod";
import type { Medicamento } from "./tipos";

export const RenglonLeido = z.object({
  texto: z.string().describe("El renglón tal como está escrito en la factura"),
  nombre: z.string().describe("El nombre del producto, el comercial si lo tiene"),
  principioActivo: z
    .string()
    .nullable()
    .describe("El genérico en español, sin la sal: «losartán», «metformina». null si no es un medicamento"),
  concentracion: z.string().nullable().describe("«50 mg», «500 mg». null si no aparece"),
  porCaja: z.number().int().nullable().describe("Unidades por caja o blíster («X30 TAB» es 30). null si no aparece"),
  cajas: z.number().int().describe("Cuántas cajas o unidades de venta se compraron en ese renglón"),
});
export type RenglonLeido = z.infer<typeof RenglonLeido>;

export const Lectura = z.object({
  esFactura: z.boolean().describe("false si la foto no es una factura o recibo de farmacia, o no se lee"),
  farmacia: z.string().nullable(),
  numero: z.string().nullable().describe("El número de factura o de control"),
  fecha: z.string().nullable().describe("La fecha de la factura como AAAA-MM-DD"),
  renglones: z.array(RenglonLeido),
});
export type Lectura = z.infer<typeof Lectura>;

/** Lo que devuelve /f/[token]/pastillas/factura/leer. */
export type RespuestaLectura = { lectura: Lectura } | { error: "sin_llave" | "no_se_leyo" | "muy_grande" | "token" };

/** Sin acentos, en minúsculas y solo letras, números y espacios: «Losartán Potásico» → «losartan potasico». */
export function normalizar(s: string): string {
  return s
    .normalize("NFD")
    .replace(/\p{Diacritic}/gu, "")
    .toLowerCase()
    .replace(/(\d),(\d)/g, "$1.$2")
    .replace(/[^a-z0-9.]+/g, " ")
    .replace(/(?<!\d)\.|\.(?!\d)/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

/** «50 mg», «50MG», «0,5 g», «1 G» → miligramos. null si no hay. */
export function miligramos(s: string | null | undefined): number | null {
  if (!s) return null;
  const m = normalizar(s).match(/(\d+(?:\.\d+)?)\s*(mg|g|mcg|ug)\b/);
  if (!m) return null;
  const n = Number(m[1]);
  return { mg: n, g: n * 1000, mcg: n / 1000, ug: n / 1000 }[m[2] as "mg" | "g" | "mcg" | "ug"];
}

/** ¿Aparece `aguja` como palabras enteras dentro de `pajar`? Los dos ya normalizados. */
function contiene(pajar: string, aguja: string): boolean {
  return aguja.length > 0 && ` ${pajar} `.includes(` ${aguja} `);
}

/**
 * El medicamento del récipe que es este renglón, o null. Vale el genérico o cualquier nombre
 * comercial. Si la concentración se leyó y no es la del récipe, no es el mismo: otra concentración
 * cambia cuánto dura cada pastilla. Si hay dos del mismo nombre y la factura no dice cuál, null:
 * que la familia elija.
 */
export function cruzar(renglon: RenglonLeido, recipe: Medicamento[]): Medicamento | null {
  const pajar = normalizar([renglon.principioActivo, renglon.nombre, renglon.texto].filter(Boolean).join(" "));
  const mgLeidos = miligramos(renglon.concentracion) ?? miligramos(renglon.texto);

  const porNombre = recipe.filter((m) => [m.nombre, ...m.comerciales].some((n) => contiene(pajar, normalizar(n))));
  const candidatos = porNombre.filter((m) => {
    const mg = miligramos(m.concentracion);
    return mgLeidos === null || mg === null || mg === mgLeidos;
  });
  return candidatos.length === 1 ? candidatos[0] : null;
}

/** Una factura inventada, para probar el recorrido sin foto ni llave de Claude. No es de nadie. */
export const FACTURA_DE_EJEMPLO: Lectura = {
  esFactura: true,
  farmacia: "Farmacia de Ejemplo",
  numero: "EJ-0001",
  fecha: null,
  renglones: [
    {
      texto: "COZAAR 50MG X30 TAB",
      nombre: "Cozaar",
      principioActivo: "losartán",
      concentracion: "50 mg",
      porCaja: 30,
      cajas: 2,
    },
    {
      texto: "METFORMINA 500MG X30 TAB GENVEN",
      nombre: "Metformina",
      principioActivo: "metformina",
      concentracion: "500 mg",
      porCaja: 30,
      cajas: 1,
    },
    {
      texto: "ACETAMINOFEN 500MG X10",
      nombre: "Acetaminofén",
      principioActivo: "paracetamol",
      concentracion: "500 mg",
      porCaja: 10,
      cajas: 1,
    },
    {
      texto: "CREMA DENTAL 100ML",
      nombre: "Crema dental",
      principioActivo: null,
      concentracion: null,
      porCaja: null,
      cajas: 1,
    },
  ],
};
