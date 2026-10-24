-- Las pastillas de la casa: el récipe, lo que se compró y cuántas quedan. Ver docs/pendientes.md.
--
-- La seguridad es la misma de 20261024130000_casa_y_familia.sql: RLS activado sin políticas y todo
-- por funciones que piden la clave de la casa (casa_*) o el token de la familia (familia_*).
--
-- El inventario es un libro de movimientos: cada factura suma, cada «Ya me la tomé» resta y un
-- conteo a mano ajusta. Lo que queda es la suma. Nadie guarda «quedan 12» en una columna, así la
-- casa y la web nunca se pisan el número. La cuenta de cuántos días alcanzan y cuándo comprar no
-- vive aquí: la hace web/src/lib/familia/inventario.ts, que es una función pura con pruebas.
--
-- Se aplica pegándola en el SQL Editor de Supabase. Se puede pegar dos veces sin romper nada.

-- Un medicamento del récipe. El nombre es el genérico; los comerciales sirven para reconocerlo en la
-- factura (Losartán / Cozaar). Solo lo que está aquí entra al inventario.
create table if not exists public.medicamentos (
  id             uuid primary key default gen_random_uuid(),
  casa_id        uuid not null references public.casas on delete cascade,
  nombre         text not null check (length(nombre) between 1 and 80),
  comerciales    text[] not null default '{}',
  concentracion  text not null default '' check (length(concentracion) <= 40),
  creado         timestamptz not null default now()
);
create unique index if not exists medicamentos_unicos
  on public.medicamentos (casa_id, lower(nombre), lower(concentracion));

-- Las tomas del récipe. `clave` es el id de la pastilla en la app de la casa ("losartan-manana"):
-- es lo que manda casa_tomar. `cantidad` admite media pastilla.
create table if not exists public.tomas (
  id              uuid primary key default gen_random_uuid(),
  casa_id         uuid not null references public.casas on delete cascade,
  medicamento_id  uuid not null references public.medicamentos on delete cascade,
  clave           text not null check (length(clave) between 1 and 60),
  hora            time not null,
  cantidad        numeric(4, 2) not null default 1 check (cantidad > 0 and cantidad <= 10),
  unique (casa_id, clave)
);

-- Una factura de farmacia. El número, si se leyó, evita cargar la misma factura dos veces.
create table if not exists public.compras (
  id           uuid primary key default gen_random_uuid(),
  casa_id      uuid not null references public.casas on delete cascade,
  farmacia     text check (length(farmacia) <= 80),
  numero       text check (length(numero) <= 40),
  fecha        date,
  cargada_por  text check (length(cargada_por) <= 60),
  creada       timestamptz not null default now()
);
create unique index if not exists compras_sin_repetir
  on public.compras (casa_id, lower(coalesce(farmacia, '')), numero) where numero is not null;

-- Solo los renglones que están en el récipe: lo demás de la factura no se guarda.
create table if not exists public.compra_renglones (
  id              uuid primary key default gen_random_uuid(),
  compra_id       uuid not null references public.compras on delete cascade,
  medicamento_id  uuid not null references public.medicamentos on delete cascade,
  texto           text not null check (length(texto) <= 120), -- como venía: "COZAAR 50MG X30 TAB"
  cajas           int not null check (cajas between 1 and 50),
  por_caja        int not null check (por_caja between 1 and 500)
);

do $$ begin
  create type public.motivo_movimiento as enum ('compra', 'toma', 'ajuste');
exception when duplicate_object then null;
end $$;

create table if not exists public.movimientos (
  id              uuid primary key default gen_random_uuid(),
  casa_id         uuid not null references public.casas on delete cascade,
  medicamento_id  uuid not null references public.medicamentos on delete cascade,
  hora            timestamptz not null default now(),
  motivo          public.motivo_movimiento not null,
  cantidad        numeric(8, 2) not null, -- positivo entra, negativo sale
  renglon_id      uuid references public.compra_renglones on delete cascade,
  toma_id         uuid references public.tomas on delete set null,
  -- El día de Caracas de la toma. Una toma descuenta una sola vez por día, aunque la cola de la
  -- casa reintente el envío.
  dia             date
);
create index if not exists movimientos_medicamento on public.movimientos (medicamento_id, hora);
create unique index if not exists movimientos_una_toma_al_dia
  on public.movimientos (toma_id, dia) where motivo = 'toma';

alter table public.medicamentos     enable row level security;
alter table public.tomas            enable row level security;
alter table public.compras          enable row level security;
alter table public.compra_renglones enable row level security;
alter table public.movimientos      enable row level security;

-- ─── Cuántas quedan ──────────────────────────────────────────────────────────────────────────

-- La suma de los movimientos desde la primera vez que entraron pastillas (factura o conteo). Las
-- tomas de antes no cuentan: salieron de pastillas que nunca se anotaron. null si nunca entró nada:
-- «no sabemos», que no es lo mismo que «se acabaron». Puede dar negativo si había pastillas sin
-- anotar; quien lo muestra lo deja en 0, que es el lado seguro (avisa antes, no después).
create or replace function public.pastillas_crudas(p_medicamento uuid) returns numeric
language sql stable security definer set search_path = ''
as $$
  select case when d.desde is null then null else coalesce(sum(m.cantidad), 0) end
  from (select min(hora) as desde from public.movimientos
        where medicamento_id = p_medicamento and motivo <> 'toma') d
  left join public.movimientos m on m.medicamento_id = p_medicamento and m.hora >= d.desde
  group by d.desde
$$;

create or replace function public.pastillas_quedan(p_medicamento uuid) returns numeric
language sql stable security definer set search_path = ''
as $$
  select case when c is null then null else greatest(0, c) end
  from public.pastillas_crudas(p_medicamento) c
$$;

-- ─── Lo que llama el teléfono de la casa ─────────────────────────────────────────────────────

-- «Ya me la tomé». El descuento vive aquí y no en la app: la app no sabe cuántas hay, y si lo
-- calculara ella, la web y la casa tendrían dos números. `p_hora` es la de la toma, para la cola
-- sin internet; una toma repetida el mismo día no descuenta otra vez. Devuelve qué medicamento era
-- y cuántas quedan (quedan es null si todavía no se ha cargado ninguna factura), o null si la clave
-- o la pastilla no existen.
create or replace function public.casa_tomar(p_clave text, p_pastilla text, p_hora timestamptz default now())
returns jsonb
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_casa uuid := public.casa_de_clave(p_clave);
  v_hora timestamptz := least(coalesce(p_hora, now()), now());
  v_toma public.tomas;
begin
  if v_casa is null then return null; end if;
  select * into v_toma from public.tomas where casa_id = v_casa and clave = p_pastilla;
  if not found then return null; end if;
  insert into public.movimientos (casa_id, medicamento_id, hora, motivo, cantidad, toma_id, dia)
  values (v_casa, v_toma.medicamento_id, v_hora, 'toma', -v_toma.cantidad, v_toma.id,
          (v_hora at time zone 'America/Caracas')::date)
  on conflict (toma_id, dia) where motivo = 'toma' do nothing;
  return jsonb_build_object(
    'medicamento', (select nombre from public.medicamentos where id = v_toma.medicamento_id),
    'quedan', public.pastillas_quedan(v_toma.medicamento_id));
end $$;

-- ─── Lo que llama la web de la familia ───────────────────────────────────────────────────────

-- Agrega o actualiza un medicamento del récipe con sus tomas, y borra las tomas que ya no están.
-- p_tomas: [{ "clave": "losartan-manana", "hora": "08:00", "cantidad": 1 }]. Es lo que llamará la
-- lectura del récipe por foto, después de que la familia confirme.
create or replace function public.familia_recetar(
  p_token text, p_nombre text, p_concentracion text default '',
  p_comerciales text[] default '{}', p_tomas jsonb default '[]'
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_casa uuid := public.casa_de_token(p_token);
  v_id uuid;
begin
  if v_casa is null then return null; end if;
  select id into v_id from public.medicamentos
   where casa_id = v_casa and lower(nombre) = lower(trim(p_nombre))
     and lower(concentracion) = lower(trim(coalesce(p_concentracion, '')));
  if v_id is null then
    insert into public.medicamentos (casa_id, nombre, concentracion, comerciales)
    values (v_casa, trim(p_nombre), trim(coalesce(p_concentracion, '')), coalesce(p_comerciales, '{}'))
    returning id into v_id;
  else
    update public.medicamentos set comerciales = coalesce(p_comerciales, '{}') where id = v_id;
  end if;

  delete from public.tomas
   where medicamento_id = v_id
     and clave not in (select t->>'clave' from jsonb_array_elements(coalesce(p_tomas, '[]')) t);
  insert into public.tomas (casa_id, medicamento_id, clave, hora, cantidad)
  select v_casa, v_id, t->>'clave', (t->>'hora')::time, coalesce((t->>'cantidad')::numeric, 1)
    from jsonb_array_elements(coalesce(p_tomas, '[]')) t
  on conflict (casa_id, clave) do update
    set medicamento_id = excluded.medicamento_id, hora = excluded.hora, cantidad = excluded.cantidad;
  return v_id;
end $$;

-- Guarda una factura que la familia ya confirmó. p_renglones:
-- [{ "medicamentoId": uuid, "texto": "COZAAR 50MG X30", "cajas": 2, "porCaja": 30 }].
-- Un renglón cuyo medicamento no es del récipe de esta casa se descarta aquí también, no solo en
-- la pantalla. Si la factura ya se había cargado (misma farmacia y número), no suma de nuevo.
-- Devuelve { compra, repetida, guardados } o null si el token no existe o no quedó ningún renglón.
create or replace function public.familia_comprar(
  p_token text, p_renglones jsonb, p_farmacia text default null, p_numero text default null,
  p_fecha date default null, p_quien text default 'la familia'
) returns jsonb
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_casa uuid := public.casa_de_token(p_token);
  v_farmacia text := nullif(left(trim(p_farmacia), 80), '');
  v_numero text := nullif(left(trim(p_numero), 40), '');
  v_compra uuid;
  v_guardados int;
begin
  if v_casa is null then return null; end if;

  if v_numero is not null then
    select id into v_compra from public.compras
     where casa_id = v_casa and numero = v_numero
       and lower(coalesce(farmacia, '')) = lower(coalesce(v_farmacia, ''));
    if v_compra is not null then
      return jsonb_build_object('compra', v_compra, 'repetida', true, 'guardados', 0);
    end if;
  end if;

  select count(*) into v_guardados
    from jsonb_to_recordset(coalesce(p_renglones, '[]'))
         as r("medicamentoId" uuid, texto text, cajas int, "porCaja" int)
    join public.medicamentos m on m.id = r."medicamentoId" and m.casa_id = v_casa
   where r.cajas between 1 and 50 and r."porCaja" between 1 and 500;
  if v_guardados = 0 then return null; end if;

  insert into public.compras (casa_id, farmacia, numero, fecha, cargada_por)
  values (v_casa, v_farmacia, v_numero, p_fecha, left(coalesce(p_quien, 'la familia'), 60))
  returning id into v_compra;

  with renglones as (
    insert into public.compra_renglones (compra_id, medicamento_id, texto, cajas, por_caja)
    select v_compra, r."medicamentoId", left(coalesce(r.texto, ''), 120), r.cajas, r."porCaja"
      from jsonb_to_recordset(p_renglones)
           as r("medicamentoId" uuid, texto text, cajas int, "porCaja" int)
      join public.medicamentos m on m.id = r."medicamentoId" and m.casa_id = v_casa
     where r.cajas between 1 and 50 and r."porCaja" between 1 and 500
    returning id, medicamento_id, cajas, por_caja
  )
  insert into public.movimientos (casa_id, medicamento_id, motivo, cantidad, renglon_id)
  select v_casa, medicamento_id, 'compra', cajas * por_caja, id from renglones;

  return jsonb_build_object('compra', v_compra, 'repetida', false, 'guardados', v_guardados);
end $$;

-- «Conté y quedan 12». Anota la diferencia, así el libro sigue sumando bien. Sirve también para
-- empezar: las pastillas que ya había en la casa antes de la primera factura.
create or replace function public.familia_ajustar(p_token text, p_medicamento uuid, p_quedan numeric)
returns numeric
language plpgsql volatile security definer set search_path = ''
as $$
declare v_casa uuid := public.casa_de_token(p_token);
begin
  if v_casa is null or p_quedan is null or p_quedan < 0 or p_quedan > 5000 then return null; end if;
  if not exists (select 1 from public.medicamentos where id = p_medicamento and casa_id = v_casa) then
    return null;
  end if;
  insert into public.movimientos (casa_id, medicamento_id, motivo, cantidad)
  values (v_casa, p_medicamento, 'ajuste', p_quedan - coalesce(public.pastillas_crudas(p_medicamento), 0));
  return public.pastillas_quedan(p_medicamento);
end $$;

-- La misma familia_casa de antes, ahora con el inventario: el récipe, sus tomas, cuántas quedan y
-- de cuántas venía la última caja (para sugerir cuántas comprar). Una sola lectura cada 5 s.
create or replace function public.familia_casa(p_token text) returns jsonb
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
        where a.casa_id = c.id and a.creada > now() - interval '24 hours'), '[]'),
      'inventario', coalesce((
        select jsonb_agg(jsonb_build_object(
          'id', m.id, 'nombre', m.nombre, 'comerciales', to_jsonb(m.comerciales),
          'concentracion', m.concentracion,
          'quedan', public.pastillas_quedan(m.id),
          'tomas', coalesce((
            select jsonb_agg(jsonb_build_object(
              'clave', t.clave, 'hora', to_char(t.hora, 'HH24:MI'), 'cantidad', t.cantidad)
              order by t.hora)
            from public.tomas t where t.medicamento_id = m.id), '[]'),
          'ultimaCompra', (
            select jsonb_build_object('fecha', coalesce(co.fecha, (co.creada at time zone 'America/Caracas')::date),
                                      'porCaja', r.por_caja)
            from public.compra_renglones r join public.compras co on co.id = r.compra_id
            where r.medicamento_id = m.id order by co.creada desc limit 1)
          ) order by m.nombre)
        from public.medicamentos m where m.casa_id = c.id), '[]'))
    from public.casas c where c.id = v_casa
  );
end $$;

-- ─── Quién puede llamar qué ──────────────────────────────────────────────────────────────────

-- Supabase da EXECUTE a anon y authenticated en toda función nueva: se quita y se da solo lo justo.
revoke all on function
  public.pastillas_crudas(uuid),
  public.pastillas_quedan(uuid),
  public.casa_tomar(text, text, timestamptz),
  public.familia_recetar(text, text, text, text[], jsonb),
  public.familia_comprar(text, jsonb, text, text, date, text),
  public.familia_ajustar(text, uuid, numeric)
from public, anon, authenticated;

grant execute on function
  public.casa_tomar(text, text, timestamptz),
  public.familia_recetar(text, text, text, text[], jsonb),
  public.familia_comprar(text, jsonb, text, text, date, text),
  public.familia_ajustar(text, uuid, numeric)
to anon, authenticated;
