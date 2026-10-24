// El contrato compartido con la app de la casa (app/lib/dominio/tipos.dart y alerta.dart).
// Si cambia aquí, cambia allá en el mismo commit. Ver docs/pantallas.md.
// Las fechas viajan como texto ISO 8601, que es lo que devuelve Supabase.

export type Canal = "whatsapp" | "llamada";

export type Contacto = {
  nombre: string;
  relacion: string; // "hijo", "vecino"
  canal: Canal;
  orden: number;
  donde?: string;
  telefono?: string;
};

export type Casa = {
  id: string;
  nombre: string; // "Carmen"
  condiciones: string[]; // ["oxigeno", "hipertension"]
  contactos: Contacto[];
  /** El teléfono de la casa, para «Llamar a Carmen». */
  telefono?: string;
  ultimoLatido: string;
  enchufado: boolean;
  bateria: number; // 0–100
};

export type TipoEvento =
  | "alarma"
  | "vidrio"
  | "golpe"
  | "grito"
  | "rutina"
  | "apagon"
  | "panico"
  | "huele_gas"
  | "me_siento_mal"
  | "estoy_bien";

/** Lo que oyó o sintió el teléfono, o lo que tocó la persona. */
export type Evento = {
  id: string;
  casaId: string;
  hora: string;
  tipo: TipoEvento;
  descripcion: string; // "Oímos agua corriendo"
  /** Solo los de rutina: si salió de lo de siempre, por qué. Lo vuelve un aviso «para saber». */
  distinto?: string;
};

export type Nivel = "rojo" | "amarillo" | "verde";

//     pendiente ──► cancelada              la persona tocó «Estoy bien»
//     pendiente ──► escalada ──► atendida  nadie respondió, o pidió ayuda
export type EstadoAlerta = "pendiente" | "cancelada" | "escalada" | "atendida";

/** Un evento que pidió confirmación. */
export type Alerta = {
  id: string;
  casaId: string;
  eventoId: string;
  nivel: Nivel;
  estado: EstadoAlerta;
  creada: string;
  venceEn: string; // creada + 60 s; igual a creada si fue pánico
  escaladaEn?: string | null;
  cerradaEn?: string | null;
  atendidaPor?: string | null;
};

/** Una toma del récipe. `clave` es el id de la pastilla en la app de la casa ("losartan-manana"). */
export type Toma = {
  clave: string;
  hora: string; // "08:00", hora de Caracas
  cantidad: number; // pastillas por toma; 0.5 es media
};

/** Un medicamento del récipe con lo que queda. Solo la web lo usa: la casa no lee el inventario. */
export type Medicamento = {
  id: string;
  nombre: string; // el genérico: "Losartán"
  comerciales: string[]; // ["Cozaar"]
  concentracion: string; // "50 mg"
  /** null si nunca se cargó una factura ni se contaron: no se sabe, que no es «se acabaron». */
  quedan: number | null;
  tomas: Toma[];
  ultimaCompra?: { fecha: string; porCaja: number } | null;
};

/** Todo lo que la web necesita de una casa para pintar la pantalla. */
export type DatosCasa = {
  casa: Casa;
  eventos: Evento[];
  alertas: Alerta[];
  /** El récipe y lo que queda (supabase/migrations/20261024160000_pastillas_e_inventario.sql). */
  inventario?: Medicamento[];
};
