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

/** Todo lo que la web necesita de una casa para pintar la pantalla. */
export type DatosCasa = {
  casa: Casa;
  eventos: Evento[];
  alertas: Alerta[];
};
