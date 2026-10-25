// Las fotos de la casa en Supabase Storage, en el bucket privado `fotos` (<casa>/<ms>.jpg y
// .json). No hay tabla: la casa se reconoce con casa_de_clave y la familia con casa_de_token, que
// ya existen. Todo con la llave de servicio, que solo vive en el servidor. La familia nunca ve el
// bucket: recibe un enlace firmado que vence en minutos.

const BUCKET = "fotos";

function credenciales() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const key = process.env.SUPABASE_SECRET_KEY;
  if (!url || !key) throw new Error("faltan NEXT_PUBLIC_SUPABASE_URL o SUPABASE_SECRET_KEY");
  return { url, key, headers: { apikey: key, Authorization: `Bearer ${key}` } };
}

async function ok(res: Response, que: string): Promise<Response> {
  if (!res.ok) throw new Error(`${que}: ${res.status} ${(await res.text()).slice(0, 200)}`);
  return res;
}

async function rpc<T>(funcion: string, args: Record<string, unknown>): Promise<T> {
  const { url, headers } = credenciales();
  const res = await fetch(`${url}/rest/v1/rpc/${funcion}`, {
    method: "POST",
    headers: { ...headers, "Content-Type": "application/json" },
    body: JSON.stringify(args),
    cache: "no-store",
  });
  return (await (await ok(res, funcion)).json()) as T;
}

/** El id de la casa de esa clave, o null. */
export const casaDeClave = (clave: string) => rpc<string | null>("casa_de_clave", { p_clave: clave });

/** El id de la casa de ese enlace de familia, o null. */
export const casaDeToken = (token: string) => rpc<string | null>("casa_de_token", { p_token: token });

/** El nombre de la casa («Carmen») y los chat de Telegram suscritos a ella. */
export async function casaYSuscritos(casa: string): Promise<{ nombre: string; telegram: string[] }> {
  const { url, headers } = credenciales();
  const [c, s] = await Promise.all([
    fetch(`${url}/rest/v1/casas?id=eq.${casa}&select=nombre`, { headers, cache: "no-store" }),
    fetch(`${url}/rest/v1/suscripciones?casa_id=eq.${casa}&canal=eq.telegram&select=identificador`, {
      headers,
      cache: "no-store",
    }),
  ]);
  const casas = (await (await ok(c, "casas")).json()) as { nombre: string }[];
  const subs = (await (await ok(s, "suscripciones")).json()) as { identificador: string }[];
  return { nombre: casas[0]?.nombre ?? "la casa", telegram: subs.map((x) => x.identificador) };
}

export async function subir(nombre: string, cuerpo: BodyInit, tipo: "image/jpeg" | "application/json") {
  const { url, headers } = credenciales();
  const res = await fetch(`${url}/storage/v1/object/${BUCKET}/${nombre}`, {
    method: "POST",
    headers: { ...headers, "Content-Type": tipo, "x-upsert": "true" },
    body: cuerpo,
  });
  await ok(res, `subir ${nombre}`);
}

export async function bajarJson<T>(nombre: string): Promise<T> {
  const { url, headers } = credenciales();
  const res = await fetch(`${url}/storage/v1/object/${BUCKET}/${nombre}`, { headers, cache: "no-store" });
  return (await (await ok(res, `bajar ${nombre}`)).json()) as T;
}

/** Los nombres completos (<casa>/<archivo>) de las fotos de una casa. */
export async function listar(casa: string): Promise<string[]> {
  const { url, headers } = credenciales();
  const res = await fetch(`${url}/storage/v1/object/list/${BUCKET}`, {
    method: "POST",
    headers: { ...headers, "Content-Type": "application/json" },
    body: JSON.stringify({ prefix: `${casa}/`, limit: 1000, sortBy: { column: "name", order: "desc" } }),
    cache: "no-store",
  });
  const objetos = (await (await ok(res, "listar")).json()) as { name: string }[];
  return objetos.map((o) => `${casa}/${o.name}`);
}

export async function borrar(nombres: string[]) {
  if (!nombres.length) return;
  const { url, headers } = credenciales();
  const res = await fetch(`${url}/storage/v1/object/${BUCKET}`, {
    method: "DELETE",
    headers: { ...headers, "Content-Type": "application/json" },
    body: JSON.stringify({ prefixes: nombres }),
  });
  await ok(res, "borrar");
}

/** Un enlace a la foto que vence en `segundos`. */
export async function enlaceFirmado(nombre: string, segundos = 600): Promise<string> {
  const { url, headers } = credenciales();
  const res = await fetch(`${url}/storage/v1/object/sign/${BUCKET}/${nombre}`, {
    method: "POST",
    headers: { ...headers, "Content-Type": "application/json" },
    body: JSON.stringify({ expiresIn: segundos }),
    cache: "no-store",
  });
  const { signedURL } = (await (await ok(res, "firmar")).json()) as { signedURL: string };
  return `${url}/storage/v1${signedURL}`;
}
