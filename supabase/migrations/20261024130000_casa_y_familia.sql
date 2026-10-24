-- La casa y la familia hablan por aquí. Ver docs/pantallas.md (el contrato) y docs/pendientes.md.
--
-- Seguridad, en una frase: nadie toca las tablas directamente. Todas tienen RLS activado y
-- ninguna política, así que la llave pública no lee ni escribe nada. Todo pasa por funciones
-- que reciben un secreto y solo ven la casa de ese secreto:
--
--   casa_*     las llama el teléfono de la casa, con la clave de la casa
--   familia_*  las llama la web de la familia, con el token del enlace de invitación
--
-- Los dos secretos son aleatorios de 128 bits o más y se guardan como hash SHA-256: quien lea la
-- base no puede entrar a ninguna casa.

create table public.casas (
  id             uuid primary key default gen_random_uuid(),
  nombre         text not null,
  condiciones    text[] not null default '{}',
  -- [{ nombre, relacion, canal: "whatsapp" | "llamada", orden, donde, telefono }]
  contactos      jsonb not null default '[]',
  telefono       text,
  clave_hash     bytea not null unique,
  ultimo_latido  timestamptz not null default now(),
  enchufado      boolean not null default true,
  bateria        smallint not null default 100 check (bateria between 0 and 100),
  creada         timestamptz not null default now()
);

create table public.invitaciones (
  token_hash  bytea primary key,
  casa_id     uuid not null references public.casas on delete cascade,
  creada      timestamptz not null default now(),
  revocada    timestamptz
);

create type public.tipo_evento as enum (
  'alarma', 'vidrio', 'golpe', 'grito', 'rutina', 'apagon',
  'panico', 'huele_gas', 'me_siento_mal', 'estoy_bien'
);

create table public.eventos (
  id           uuid primary key default gen_random_uuid(),
  casa_id      uuid not null references public.casas on delete cascade,
  hora         timestamptz not null default now(),
  tipo         public.tipo_evento not null,
  descripcion  text not null,
  distinto     text
);
create index eventos_casa_hora on public.eventos (casa_id, hora desc);

create type public.nivel as enum ('rojo', 'amarillo', 'verde');
create type public.estado_alerta as enum ('pendiente', 'cancelada', 'escalada', 'atendida');

create table public.alertas (
  id            uuid primary key default gen_random_uuid(),
  casa_id       uuid not null references public.casas on delete cascade,
  evento_id     uuid not null references public.eventos on delete cascade,
  nivel         public.nivel not null default 'rojo',
  estado        public.estado_alerta not null default 'pendiente',
  creada        timestamptz not null default now(),
  vence_en      timestamptz not null,
  escalada_en   timestamptz,
  cerrada_en    timestamptz,
  atendida_por  text,
  check (vence_en >= creada)
);
create index alertas_casa_creada on public.alertas (casa_id, creada desc);
create index alertas_pendientes on public.alertas (vence_en) where estado = 'pendiente';

alter table public.casas        enable row level security;
alter table public.invitaciones enable row level security;
alter table public.eventos      enable row level security;
alter table public.alertas      enable row level security;

-- ─── Secretos ────────────────────────────────────────────────────────────────────────────────

create function public.hash_secreto(secreto text) returns bytea
language sql immutable set search_path = ''
as $$ select extensions.digest(secreto, 'sha256') $$;

create function public.casa_de_clave(p_clave text) returns uuid
language sql stable security definer set search_path = ''
as $$ select id from public.casas where clave_hash = public.hash_secreto(p_clave) $$;

create function public.casa_de_token(p_token text) returns uuid
language sql stable security definer set search_path = ''
as $$
  select casa_id from public.invitaciones
  where token_hash = public.hash_secreto(p_token) and revocada is null
$$;

-- ─── Escalar: la única transición que corre sola ────────────────────────────────────────────

-- Pasa de «pendiente» a «escalada» las alertas vencidas. Es un solo UPDATE condicionado al estado:
-- si dos procesos lo corren a la vez (la web, el teléfono, el vigilante), Postgres revisa de nuevo
-- la condición tras el primer commit y solo uno recibe la fila. Así nadie avisa dos veces.
-- Devuelve las que escaló esta llamada, para que quien la llamó mande el WhatsApp.
create function public.escalar_vencidas(p_casa uuid default null)
returns setof public.alertas
language sql volatile security definer set search_path = ''
as $$
  update public.alertas
     set estado = 'escalada', escalada_en = now()
   where estado = 'pendiente'
     and vence_en <= now()
     and (p_casa is null or casa_id = p_casa)
  returning *
$$;

-- ─── Lo que llama el teléfono de la casa ─────────────────────────────────────────────────────

create function public.casa_latido(p_clave text, p_enchufado boolean, p_bateria int)
returns boolean
language plpgsql volatile security definer set search_path = ''
as $$
declare v_casa uuid := public.casa_de_clave(p_clave);
begin
  if v_casa is null then return false; end if;
  update public.casas
     set ultimo_latido = now(), enchufado = p_enchufado, bateria = greatest(0, least(100, p_bateria))
   where id = v_casa;
  perform public.escalar_vencidas(v_casa);
  return true;
end $$;

create function public.casa_evento(
  p_clave text, p_tipo public.tipo_evento, p_descripcion text,
  p_hora timestamptz default now(), p_distinto text default null
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_casa uuid := public.casa_de_clave(p_clave);
  v_id uuid;
begin
  if v_casa is null then return null; end if;
  insert into public.eventos (casa_id, hora, tipo, descripcion, distinto)
  values (v_casa, coalesce(p_hora, now()), p_tipo, left(p_descripcion, 200), left(p_distinto, 300))
  returning id into v_id;
  return v_id;
end $$;

-- Una alerta nace pendiente con su plazo (60 s, o 15 en el demo), o ya escalada si la persona la
-- pidió (pánico, huele a gas, me siento mal): igual que Alerta.preguntar y Alerta.urgente en Dart.
create function public.casa_alerta(
  p_clave text, p_evento uuid, p_espera_s int default 60, p_urgente boolean default false
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_casa uuid := public.casa_de_clave(p_clave);
  v_id uuid;
begin
  if v_casa is null then return null; end if;
  if not exists (select 1 from public.eventos where id = p_evento and casa_id = v_casa) then
    return null;
  end if;
  insert into public.alertas (casa_id, evento_id, estado, vence_en, escalada_en)
  values (
    v_casa, p_evento,
    case when p_urgente then 'escalada'::public.estado_alerta else 'pendiente' end,
    now() + make_interval(secs => case when p_urgente then 0 else greatest(5, least(300, p_espera_s)) end),
    case when p_urgente then now() end
  )
  returning id into v_id;
  return v_id;
end $$;

-- «Estoy bien» (cancelar), «Necesito ayuda» (escalar) o «Fue sin querer» (atender), desde la
-- casa. Una transición que no vale desde el estado actual no cambia nada, como en Dart.
create function public.casa_responder(p_clave text, p_alerta uuid, p_respuesta text)
returns public.estado_alerta
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_casa uuid := public.casa_de_clave(p_clave);
  v_estado public.estado_alerta;
begin
  if v_casa is null then return null; end if;
  update public.alertas a set
    estado = case p_respuesta
      when 'cancelar' then 'cancelada'::public.estado_alerta
      when 'escalar'  then 'escalada'::public.estado_alerta
      when 'atender'  then 'atendida'::public.estado_alerta end,
    escalada_en  = case when p_respuesta = 'escalar' then now() else a.escalada_en end,
    cerrada_en   = case when p_respuesta in ('cancelar', 'atender') then now() else a.cerrada_en end,
    atendida_por = case when p_respuesta = 'atender' then 'la casa' else a.atendida_por end
  where a.id = p_alerta and a.casa_id = v_casa
    and (   (p_respuesta in ('cancelar', 'escalar') and a.estado = 'pendiente')
         or (p_respuesta = 'atender' and a.estado = 'escalada'));
  select estado into v_estado from public.alertas where id = p_alerta and casa_id = v_casa;
  return v_estado;
end $$;

-- ─── Lo que llama la web de la familia ───────────────────────────────────────────────────────

-- Todo lo que pinta la pantalla, con la forma de DatosCasa (web/src/lib/familia/tipos.ts):
-- la casa sin sus secretos, los eventos de las últimas 24 h y las alertas de las últimas 24 h.
-- Antes de leer, escala lo vencido: la familia nunca ve «todo bien» con una alerta ya vencida,
-- aunque el vigilante esté caído.
create function public.familia_casa(p_token text) returns jsonb
language plpgsql volatile security definer set search_path = ''
as $$
declare v_casa uuid := public.casa_de_token(p_token);
begin
  if v_casa is null then return null; end if;
  perform public.escalar_vencidas(v_casa);
  return (
    select jsonb_build_object(
      'casa', jsonb_build_object(
        'id', c.id, 'nombre', c.nombre, 'condiciones', to_jsonb(c.condiciones),
        'contactos', c.contactos, 'telefono', c.telefono, 'ultimoLatido', c.ultimo_latido,
        'enchufado', c.enchufado, 'bateria', c.bateria),
      'eventos', coalesce((
        select jsonb_agg(jsonb_build_object(
          'id', e.id, 'casaId', e.casa_id, 'hora', e.hora, 'tipo', e.tipo,
          'descripcion', e.descripcion, 'distinto', e.distinto) order by e.hora desc)
        from public.eventos e
        where e.casa_id = c.id and e.hora > now() - interval '24 hours'), '[]'),
      'alertas', coalesce((
        select jsonb_agg(jsonb_build_object(
          'id', a.id, 'casaId', a.casa_id, 'eventoId', a.evento_id, 'nivel', a.nivel,
          'estado', a.estado, 'creada', a.creada, 'venceEn', a.vence_en,
          'escaladaEn', a.escalada_en, 'cerradaEn', a.cerrada_en,
          'atendidaPor', a.atendida_por) order by a.creada desc)
        from public.alertas a
        where a.casa_id = c.id and a.creada > now() - interval '24 hours'), '[]'))
    from public.casas c where c.id = v_casa
  );
end $$;

-- «Ya hablé con Carmen, está bien».
create function public.familia_atender(p_token text, p_alerta uuid, p_quien text default 'la familia')
returns public.estado_alerta
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_casa uuid := public.casa_de_token(p_token);
  v_estado public.estado_alerta;
begin
  if v_casa is null then return null; end if;
  update public.alertas
     set estado = 'atendida', cerrada_en = now(), atendida_por = left(coalesce(p_quien, 'la familia'), 60)
   where id = p_alerta and casa_id = v_casa and estado = 'escalada';
  select estado into v_estado from public.alertas where id = p_alerta and casa_id = v_casa;
  return v_estado;
end $$;

-- ─── Alta de una casa: solo con la llave secreta del servidor ───────────────────────────────

-- Crea la casa y su primera invitación, y devuelve los dos secretos en claro una sola vez.
-- Si no se pasan, se generan con 128 bits de azar.
create function public.crear_casa(
  p_nombre text, p_condiciones text[] default '{}', p_contactos jsonb default '[]',
  p_clave text default null, p_token text default null
) returns jsonb
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_clave text := coalesce(p_clave, encode(extensions.gen_random_bytes(16), 'hex'));
  v_token text := coalesce(p_token, encode(extensions.gen_random_bytes(16), 'hex'));
  v_casa uuid;
begin
  insert into public.casas (nombre, condiciones, contactos, clave_hash)
  values (p_nombre, p_condiciones, p_contactos, public.hash_secreto(v_clave))
  returning id into v_casa;
  insert into public.invitaciones (token_hash, casa_id) values (public.hash_secreto(v_token), v_casa);
  return jsonb_build_object('casaId', v_casa, 'clave', v_clave, 'token', v_token);
end $$;

-- ─── Quién puede llamar qué ──────────────────────────────────────────────────────────────────

revoke all on all functions in schema public from public, anon, authenticated;

grant execute on function
  public.casa_latido(text, boolean, int),
  public.casa_evento(text, public.tipo_evento, text, timestamptz, text),
  public.casa_alerta(text, uuid, int, boolean),
  public.casa_responder(text, uuid, text),
  public.familia_casa(text),
  public.familia_atender(text, uuid, text)
to anon, authenticated;

grant execute on function
  public.crear_casa(text, text[], jsonb, text, text),
  public.escalar_vencidas(uuid)
to service_role;
