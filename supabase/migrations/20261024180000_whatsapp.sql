-- Suscripciones de WhatsApp por casa y la cola de avisos pendientes.
--
-- Intercambio consciente: el token de invitación se guarda EN CLARO en `suscripciones.token`.
-- Las invitaciones originales solo guardan hash (ver 20261024130000), pero para armar el enlace
-- del aviso de WhatsApp necesitamos el token en claro. Rompe la promesa de "solo hash" a cambio
-- de poder mandar el enlace directo: quien lea esta tabla puede abrir el panel de esa casa. Si
-- más adelante se aprueban plantillas de Meta, el enlace puede venir de otra parte y la columna
-- vuelve a ser solo hash.
--
-- Las funciones de abajo las llama el vigilante del servidor con la llave secreta
-- (`service_role`); la llave pública no puede ejecutarlas.

-- ─── Suscripciones ─────────────────────────────────────────────────────────────────────────

create table public.suscripciones (
  casa_id   uuid not null references public.casas on delete cascade,
  telefono  text not null,                 -- solo dígitos, con código de país (ej. 584141234567)
  token     text not null,                 -- token de invitación en claro (ver comentario de arriba)
  creada    timestamptz not null default now(),
  primary key (casa_id, telefono)
);

alter table public.suscripciones enable row level security;

-- Qué avisos ya salieron, por alerta Y por teléfono. El sello va aquí y no en `alertas` porque
-- una alerta puede tener varios familiares suscritos: si el vigilante se cae después de mandar
-- el primero, en la siguiente corrida solo se manda a los que faltan. Nunca se pierde un aviso
-- ni se repite al mismo teléfono.
create table public.avisos_enviados (
  alerta_id   uuid not null references public.alertas on delete cascade,
  telefono    text not null,
  enviada_en  timestamptz not null default now(),
  primary key (alerta_id, telefono)
);

alter table public.avisos_enviados enable row level security;

-- ─── Funciones ─────────────────────────────────────────────────────────────────────────────

-- Suscribe un teléfono a una casa a partir del token del enlace. Si el token no vale, devuelve
-- false sin tocar nada. Si el teléfono ya estaba suscrito, actualiza el token (por si se emitió
-- uno nuevo) y devuelve true. Normaliza el teléfono dejando solo dígitos.
create function public.familia_suscribir(p_token text, p_telefono text) returns boolean
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_casa uuid := public.casa_de_token(p_token);
  v_tel text := regexp_replace(coalesce(p_telefono, ''), '\D', '', 'g');
begin
  if v_casa is null or v_tel = '' then return false; end if;
  insert into public.suscripciones (casa_id, telefono, token)
  values (v_casa, v_tel, p_token)
  on conflict (casa_id, telefono) do update set token = excluded.token;
  return true;
end $$;

-- Cola de avisos por mandar: una fila por (alerta, teléfono suscrito) que todavía no recibió
-- ese aviso. Se une con `eventos` (descripción) y `casas` (nombre) para armar el mensaje sin
-- más llamadas.
create function public.avisos_pendientes(p_limite int default 20)
returns table (
  alerta_id    uuid,
  casa_id      uuid,
  nombre       text,
  telefono     text,
  token        text,
  nivel        public.nivel,
  descripcion  text,
  escalada_en  timestamptz
)
language sql stable security definer set search_path = ''
as $$
  select a.id, a.casa_id, c.nombre, s.telefono, s.token, a.nivel, e.descripcion, a.escalada_en
    from public.alertas a
    join public.eventos e on e.id = a.evento_id
    join public.casas c on c.id = a.casa_id
    join public.suscripciones s on s.casa_id = a.casa_id
   where a.estado = 'escalada'
     and not exists (
       select 1 from public.avisos_enviados v
        where v.alerta_id = a.id and v.telefono = s.telefono
     )
   order by a.escalada_en
   limit p_limite
$$;

-- Sella que este teléfono ya recibió el aviso de esta alerta. Idempotente: dos llamadas
-- concurrentes insertan una sola fila y devuelven true una sola vez.
create function public.marcar_avisada(p_alerta uuid, p_telefono text) returns boolean
language plpgsql volatile security definer set search_path = ''
as $$
declare v_tel text := regexp_replace(coalesce(p_telefono, ''), '\D', '', 'g');
begin
  insert into public.avisos_enviados (alerta_id, telefono)
  values (p_alerta, v_tel)
  on conflict (alerta_id, telefono) do nothing;
  return found;
end $$;

-- ─── Permisos ─────────────────────────────────────────────────────────────────────────────
-- Solo la llave secreta del servidor puede ejecutarlas. La llave pública no las ve.

revoke all on function public.familia_suscribir(text, text) from public, anon, authenticated;
revoke all on function public.avisos_pendientes(int) from public, anon, authenticated;
revoke all on function public.marcar_avisada(uuid, text) from public, anon, authenticated;

grant execute on function
  public.familia_suscribir(text, text),
  public.avisos_pendientes(int),
  public.marcar_avisada(uuid, text)
to service_role;
