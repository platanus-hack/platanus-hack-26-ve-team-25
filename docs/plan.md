# Plan: un teléfono viejo que cuida a los que se quedaron solos

> Decidido el sábado 24-oct a las 00:30 y validado con el mentor. Si cambia, se reescribe aquí.
> **El sábado a las 14:30 se recortó el alcance:** [lo que se presenta](#alcance-congelado-lo-que-se-presenta)
> y [la venta](#la-venta-para-el-pitch). Lo que se cortó va como proyección en [futuro.md](futuro.md#hacia-dónde-va).
> El porqué, lo que ya existe y las decisiones de diseño están en [contexto.md](contexto.md).
> Lo que puede fallar: [riesgos.md](riesgos.md). Las preguntas de cada uno: [investigacion.md](investigacion.md).
> Lo que no hacemos ahora pero sí en el producto: [futuro.md](futuro.md).

## Decisiones del equipo (sábado 24-oct)

- **Para el hackatón, una app y una web.** El teléfono de la casa usa una app **Flutter en
  Android**. La familia entra por **web**, con un enlace o un QR, para que el público la pruebe en
  el pitch sin instalar nada.
- **La versión final es una sola app para todos**, con dos roles: la casa y la familia
  ([futuro.md](futuro.md)).
- **Supabase** para la base de datos, por ahora.
- **Lo que se pueda, en el teléfono** y en caché. A la base solo va lo relevante: eventos,
  alertas, latidos y el perfil de la casa.
- **Un filtro muy bueno antes de avisar.** La meta es despreocupar al que cuida desde lejos, no
  llenarlo de alertas. Tres niveles: 🔴 urgente, 🟡 para saber, 🟢 todo bien
  ([riesgos.md](riesgos.md#la-regla-de-oro-despreocupar-no-angustiar)).
- **El perfil de salud cambia las reglas.** Un apagón no es igual para una persona hipertensa que
  para una que usa oxígeno. Reglas generales por condición más calibración por casa
  ([investigacion.md](investigacion.md#el-perfil-de-salud)). *(Sábado 14:30: va como proyección,
  no entra en el demo.)*
- **El cliente es el que cuida**, el hijo o el familiar que está lejos. El adulto mayor confía
  porque su familia confía.
- **El aviso real sale por dos vías.** La casa llama por WhatsApp al primer contacto, con
  respaldo por llamada normal. **Telegram es el canal de avisos:** cualquiera se suscribe con un
  toque desde el QR y recibe el aviso (Josuep, sábado 15:25). Los mensajes por WhatsApp con Kapso
  se sacaron el sábado 18:00: Meta restringió la cuenta.
- **Se vende como un acompañante del día a día, y el oído sigue siendo el centro.** El pitch abre
  con lo de todos los días (la pastilla, la llamada con un toque) y llega a la alarma. No es un
  asistente médico: ya hubo proyectos así en Platanus (Tata y Memo, PH25), el track es Emergencias
  y lo original es el oído. No se construye nada nuevo hasta que P0 esté desplegado.
- **Poco y sólido antes que todo a medias.** Se presenta lo que ya está escrito en código, probado
  en el teléfono. Lo demás no se construye: se cuenta como hacia dónde va el producto.

## Reloj (hora de Caracas)

| Cuándo | Qué |
|---|---|
| Sáb 17:00 | La app en el teléfono de la tarima, la alarma suena y el ciclo casa → web probado |
| Sáb 20:00 | Kapso y pastillas conectados. Taller «Cómo hacer un buen demo» (va todo el equipo) |
| Sáb 21:00–24:00 | Nombre, README, ensayo y video de respaldo |
| Sáb 24:00 | Alcance congelado: desde aquí solo arreglos y ensayo |
| **Dom 08:30** | **Fin del hacking. Lo que no esté pusheado no existe.** |
| Dom 10:00 | Presentaciones |

## El flujo del MVP

1. El teléfono de la casa oye un posible evento: alarma de humo, vidrio roto, golpe, grito, o una
   frase de ayuda dicha en voz alta.
2. Suena una alarma fuerte en la casa: «¿Está bien?». La pantalla destella y vibra.
3. Si nadie responde en 60 s, la alerta escala: la web de la familia se pone roja, la casa llama
   por WhatsApp al primer contacto, y el vigilante manda el Telegram a todos los suscritos.
4. Cada «Estoy bien» queda anotado en la base. Que ajuste los umbrales de esa casa es proyección.

## Alcance congelado: lo que se presenta

> Recortado el sábado 24-oct a las 14:30. Lo que no está aquí no se construye: se cuenta como
> proyección ([futuro.md](futuro.md#hacia-dónde-va)). Desde las 24:00 del sábado solo entran
> arreglos y ensayo. El detalle de cada punto, con dónde está el código, sigue en
> [pendientes.md](pendientes.md).

Todo esto ya está escrito. Falta probarlo en el teléfono y conectarlo:

| # | Qué falta | Quién | Para | Por qué |
|---|---|---|---|---|
| 1 | Instalar la app en el teléfono de la tarima y pasar la lista de prueba ([pendientes.md](pendientes.md), punto 1) | Abrahan | 17:00 | Nada se ha probado en un teléfono real. Sin esto no hay demo |
| 2 | Que «¿Está bien?» suene (520 Hz) y vibre | Abrahan | 17:00 | Hoy solo se ve. Una alarma muda no convence en la tarima |
| 3 | El ciclo casa → Supabase → `/f/demo` abierta en 5 a 10 teléfonos a la vez | Rogelio | 17:00 | Es lo que vive el público |
| 4 | Avisos: ~~el vigilante cada 5 s~~ (16:21, en pg_cron), ~~el `setWebhook` de Telegram~~, y el webhook de Kapso apuntando a `/api/kapso/webhook` | Josuep | 17:00 | Es la integración real que ven los jueces. Falta probarla de punta a punta con el teléfono |
| 5 | Pastillas: migración, `ANTHROPIC_API_KEY` en Vercel y `casa_tomar` desde la app | Abrahan y Rogelio | 20:00 | La web está hecha, falta conectarla |
| 6 | Nombre del producto, README con arquitectura, ensayo y video de respaldo | Todos | 24:00 | Es lo que leen el agente y el jurado |

**Se cortó y va como proyección:** la vibración del piso, el apagón con el perfil de
salud, la ficha de emergencia, el teléfono personal de la persona con la pregunta del ánimo, el
pedido de las pastillas a domicilio, la cámara, el modo kiosco, la rutina y la lectura del récipe
por foto.

## Demo

1. Un teléfono en la tarima es la casa de «la señora Carmen» (inventada). El público escanea el QR,
   su teléfono pasa a ser la familia y se suscribe por Telegram con un toque.
2. **El día a día.** Suena el recordatorio de la pastilla y «Carmen» toca «Ya me la tomé». En la
   web de la familia se ve cuántos días de losartán le quedan.
3. **La falsa alarma.** Un golpe fuerte junto al teléfono. Sale «¿Está bien?», «Carmen» dice que
   está bien y no escala. Es el filtro: despreocupar, no angustiar.
4. **La alerta.** Otro golpe y nadie responde. Mientras corren los 60 s se cuenta el problema, con
   las cifras. Al vencer, se pone roja la web de todos los que escanearon, a cada uno le llega el
   Telegram y la casa llama por WhatsApp al hijo. Los tiempos son los del producto:
   nada se acelera.

Si algo falla en vivo, `/f/demo?escenario=alerta` muestra lo mismo con datos simulados, y queda el
video de respaldo.

## La venta (para el pitch)

Lo básico, sin profundizar. Es la propuesta del sábado 14:30; el precio lo cierra el equipo.

- **Quién paga:** el que cuida desde afuera. La diáspora ya paga por la salud de sus padres con
  parte de las remesas: en 2022, asistensi tenía afiliados en al menos 40 países
  ([Bloomberg Línea](https://www.bloomberglinea.com/2022/08/18/una-plataforma-de-seguros-se-extiende-desde-venezuela-con-la-mirada-puesta-en-las-remesas/)).
- **Precio: USD 5 al mes por casa**, con varios familiares. No hay equipo que comprar: el teléfono
  viejo ya está en una gaveta.
- **Contra qué se compara:** un sistema de alerta médica en EE. UU. cuesta unos USD 40 al mes en
  promedio ([NCOA](https://www.ncoa.org/product-resources/medical-alert-systems/medical-alert-systems-cost/)),
  más USD 50 a 200 de equipo ([The Senior List](https://www.theseniorlist.com/medical-alert-system-buyers-guide/)).
- **Por qué el margen aguanta:** el oído corre en el teléfono, así que no hay un servidor de audio
  que pagar por minuto. Lo que cuesta por casa son los mensajes de WhatsApp y alguna lectura de
  Claude, de 2 a 4 centavos cada una.
- **Segundo canal:** las aseguradoras y los servicios de emergencia (asistensi, Venemergencia) lo
  suman a su plan y pagan por afiliado. Ellos venden la respuesta; nosotros, el aviso a tiempo que
  la dispara.

## Roles

| Rol | Qué | Quién |
|---|---|---|
| Detección e IA | Modelo local o nube, YAMNet en Flutter, vibración, fusión, umbrales por casa, la persona como sensor | Abrahan |
| Alertas y conexión | Pánico, «¿Está bien?», filtro de falsos positivos, niveles, escalamiento, aviso sin señal o sin luz | Josuep |
| Datos y usuarios | Cifras con fuente, diáspora, usuarios potenciales, testimonios, competencia | Anttony |
| Orquestación, UX/UI y riesgos | Organización, huecos y muros, viabilidad, deploy, pitch. Programa la UI con el equipo | Rogelio |

**Quién construye qué:**

| Pieza | Quién |
|---|---|
| App Flutter de la casa | Abrahan |
| Web de la familia y UI/UX de las dos pantallas | Rogelio. Las pastillas, Abrahan |
| Supabase | Rogelio y Abrahan |
| WhatsApp (Kapso) y el vigilante | Josuep |
| Cifras y la venta | Anttony |

## Infra y créditos de los patrocinantes

> Créditos desbloqueados el sábado 24-oct a las 06:00. Lo que dice «propuesta» falta decidirlo con
> el equipo. La regla: **Claude redacta y lee; las reglas deciden quién recibe un 🔴.** El camino
> de la alarma (oír, preguntar, escalar, avisar) nunca depende de un modelo de lenguaje.

| Patrocinante | Por hacker | Equipo (4) | Para qué |
|---|---|---|---|
| Anthropic | $50 | $200 | Claude: el resumen de la mañana, las preguntas por WhatsApp y las pastillas desde la foto del récipe |
| Render | $50 | $200 | El vigilante: un proceso siempre encendido que escala alertas, vigila latidos y recibe webhooks |
| Kapso | $22 | $88 | El aviso a la familia por WhatsApp, con botones |
| ElevenLabs | por confirmar | — | La voz de la casa, pregrabada |

Lo que ya hay, sin costo:

- **Web de la familia:** Next.js en Vercel, plan gratis. Producción:
  https://platanus-hack-26-ve-team-25.vercel.app. Se despliega sola con cada push a `main`, desde
  la cuenta de Rogelio conectada al repo.
- **App de la casa:** Flutter, APK para Android instalado a mano. La misma app en el navegador,
  sin oído: https://platanus-hack-26-ve-team-25-casa.vercel.app (`make casa-deploy`).
- **Estado y tiempo real:** Supabase, plan gratis.
- **Detección:** corre en el teléfono, sin costo por uso. El audio nunca sale del teléfono.
- **Aviso de respaldo:** si no contestan el WhatsApp, la casa llama por teléfono normal.

> **Cómo quedó el sábado en la tarde:** Meta restringió la cuenta de WhatsApp y solo funciona el
> sandbox de Kapso, con cada teléfono activado a mano, y Telegram pasó a ser el canal general. El
> vigilante quedó como `/api/vigilar` en la web, y desde las 16:21 lo llama la base cada 5 s con
> pg_cron: Render no hizo falta. De Claude se usa la lectura de la factura de la farmacia; el
> resumen de la mañana y las preguntas por WhatsApp van como proyección.

### Propuesta: qué hace cada crédito

1. **WhatsApp por Kapso (P0, reemplaza a Telegram si pasa la prueba).** La familia venezolana vive
   en WhatsApp; Telegram le pide instalar algo y unirse a un bot. En el demo, el QR abre WhatsApp
   con un mensaje listo («Quiero cuidar a Carmen»). Ese mensaje registra el teléfono y abre la
   ventana de 24 h de Meta, en la que se puede escribir sin plantillas aprobadas. Cuando la alerta
   escala, a todos les llega un WhatsApp con botones: «Ya hablé con ella» y «Llamar a Pedro».
   **Prueba antes de las 08:00:** que un segundo teléfono se sume y reciba desde el número de
   prueba de Kapso. Si falla, se queda Telegram.
2. **El vigilante en Render (P0).** Es la pieza de servidor de los puntos 3 y 4 del P0: un proceso
   siempre encendido que cada pocos segundos escala la alerta vencida que nadie canceló (cambio
   atómico en Supabase), marca «sin señal» cuando falta el latido y manda el WhatsApp o el
   Telegram. También recibe los webhooks de Kapso. Así el aviso no depende del teléfono de la casa
   ni de que alguien tenga la web abierta. Una instancia Starter (unos $7 al mes) no se duerme.
3. **Claude (P1).** Tres usos, ninguno en el camino de la alarma:
   - **El 🟢 de cada mañana**, por WhatsApp: dos o tres frases a partir de los eventos del día.
     Solo con eventos que existen; si no hay, un texto fijo.
   - **Preguntar por WhatsApp:** «¿Cómo amaneció mi mamá?», y Claude responde leyendo los eventos
     de hoy. En el demo, el público le puede escribir.
   - **Las pastillas desde la foto del récipe**, que la familia revisa antes de guardar.

   Con Claude Opus 5.5 ($4 por millón de tokens de entrada y $20 por millón de salida), cada
   llamada cuesta entre 2 y 4 centavos: los $200 alcanzan para miles.
4. **ElevenLabs (P2, si llegan los créditos).** Las frases fijas de la casa («Carmen, ¿está
   bien?», el recordatorio de las pastillas) se generan una vez y van dentro de la app, así que
   funcionan sin internet. Si no llegan, la voz del sistema de Android hace lo mismo.

Cada uno canjea sus créditos en su cuenta, pero se usa una sola cuenta por servicio mientras
alcance. Las llaves van en `web/.env.local` y en las variables de Vercel y Render, nunca en el repo.

## Cómo trabajamos

- Commits chicos y push seguido: el repo es lo que se juzga.
- Deploy después de cada avance grande.
- Datos de prueba inventados. Nada real de nadie.
- Nada de llaves ni `.env` en el repo: es público.

## Pendiente

- [x] Nombres de quién construye cada pieza
- [ ] Contarle a Víctor el enfoque del día a día
- [ ] Hablar con Adrián, gerente de IA de Yummy: Víctor lo recomendó para revisar la idea
- [ ] **Volver a probar `/escucha` con la música alta de la oficina, ya con las clases nuevas.**
  Ojo: el clasificador devuelve solo las 10 clases más probables (`maxResults: 10`). Con música
  fuerte, las 10 pueden ser todas de música y la alarma de humo quedar fuera aunque suene. Si
  pasa, se filtra por nuestras clases (`categoryAllowlist`) en vez de pedir el top 10
- [ ] Cifras con fuente: ver [investigacion.md](investigacion.md#anttony--antecedentes-y-usuarios)
