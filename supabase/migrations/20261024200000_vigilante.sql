-- El vigilante: cada 5 s la base llama a GET /api/vigilar, que escala las alertas vencidas y manda
-- los avisos por Telegram y WhatsApp. Corre dentro de Supabase con pg_cron y pg_net: no hace falta
-- un servidor aparte, y el aviso no depende de que alguien tenga la web abierta.
--
-- El secreto no está aquí, porque el repo es público. Vive en Vault con el nombre `cron_secret` y
-- es el mismo valor de `CRON_SECRET` en Vercel. Se carga una vez desde el SQL Editor:
--   select vault.create_secret('<el valor de CRON_SECRET>', 'cron_secret');
--
-- Se puede pegar dos veces: `cron.schedule` reemplaza el trabajo que tiene el mismo nombre.
-- Para ver si responde:
--   select status_code, content, created from net._http_response order by created desc limit 5;

create extension if not exists pg_cron;
create extension if not exists pg_net;

select cron.schedule(
  'vigilante',
  '5 seconds',
  $$
  select net.http_get(
    url := 'https://platanus-hack-26-ve-team-25.vercel.app/api/vigilar',
    headers := jsonb_build_object(
      'Authorization',
      'Bearer ' || (select decrypted_secret from vault.decrypted_secrets where name = 'cron_secret')
    ),
    timeout_milliseconds := 20000
  )
  $$
);

-- Cada pasada deja una fila en cron.job_run_details, que no se limpia sola: unas 17.000 al día.
select cron.schedule(
  'vigilante-limpieza',
  '0 * * * *',
  $$
  delete from cron.job_run_details
   where jobid = (select jobid from cron.job where jobname = 'vigilante')
     and end_time < now() - interval '1 hour'
  $$
);
