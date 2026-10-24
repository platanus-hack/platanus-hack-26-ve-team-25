// Texto compartido de los avisos de alerta.
//
// Va en su propio módulo para que lo puedan importar tanto el cliente de WhatsApp (Kapso) como
// el de Telegram, sin que ninguno dependa del otro. El formato es el mismo para ambos canales:
// un emoji al inicio para que destaque en la notificación, nombre de la casa, descripción del
// evento y enlace al panel de la familia.

/**
 * Arma el texto del aviso en español. Corto, con un solo emoji al inicio para que destaque
 * en la notificación sin saturar. Incluye el enlace al panel de la familia para que toquen
 * y vean el contexto.
 */
export function textoDeAlerta(datos: {
  nombre: string;
  descripcion: string;
  enlace: string;
}): string {
  return `🔴 ${datos.nombre}: ${datos.descripcion}\n${datos.enlace}`;
}
