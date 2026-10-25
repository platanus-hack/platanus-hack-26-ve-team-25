# Armar el demo

> Qué va en cada teléfono, cómo se conectan y cómo se comprueba antes de subir a la tarima.
> Empezado por Abrahan el sábado 24 a las 17:30. El guion del demo sigue en
> [plan.md](plan.md#demo).

## Los cuatro teléfonos

| Teléfono | Vista | Qué hace en el demo |
|---|---|---|
| **Infinix** (Android 16) | De mesa: la app de la casa ([`app/`](../app/README.md)) | Es la casa de Carmen. Oye, pregunta «¿Está bien?», recuerda la pastilla y llama |
| **Samsung** | Familia: Josuep, el hijo | La web de la familia instalada (`/f/demo`) y el aviso por Telegram. Recibe la llamada de WhatsApp de la casa |
| **iPhone** | «El 911» | Recibe la llamada de «Lucero, llama a emergencias», en vez del 911 de verdad |
| **Honor** | Por definir (por defecto, el vecino) | El vecino Pedro, que recibe «Lucero, llama al vecino». Si se confirma la vista personal del abuelo, se cambia el papel |

**Cómo se conectan:** ninguno habla con otro directamente. La casa escribe en Supabase
(eventos, alertas, latido y tomas) y la familia lee de ahí cada 5 s; el vigilante de la base
escala lo vencido y manda el Telegram. Las llamadas salen del Infinix por la red de teléfono o
por WhatsApp. Es la misma conexión que ya funcionó entre el Infinix y `/f/demo`.

## Cómo se identifican en la mesa

En el pitch no va ninguna lámina que explique qué papel tiene cada teléfono. Cada teléfono lleva una
tarjeta o etiqueta visible con su rol, y esa etiqueta es lo que sustituye a la explicación en
pantalla.

| Teléfono | Texto de la etiqueta |
|---|---|
| **Infinix** | `LA CASA` |
| **Samsung** | `EL HIJO · EN OTRO PAÍS` |
| **iPhone** | `EL 911` |
| **Honor** | `EL VECINO` (depende de que se confirme ese papel; ver el punto 4) |

**Por qué:** durante los 60 s del escalamiento el jurado tiene que poder seguir la cadena con la
mirada en la mesa —la casa llama al hijo, el hijo no contesta, la casa llama al 911— sin que nadie
tenga que explicar nada en pantalla.

**Montaje:** la etiqueta no puede tapar la pantalla. Va en la parte de atrás del teléfono o en un pie
de tarjeta al lado. La del Infinix tiene que dejar ver la línea de diagnóstico con los dB y las
clases que pide el punto 1.

## 1. El Infinix: la casa

Los números van en `app/config/local.json`, que no se sube al repo:

| Clave | Número de | Para |
|---|---|---|
| `TELEFONO_EMERGENCIA` | el Samsung (Josuep) | El primer contacto: al que llama cuando la alerta escala, y «Lucero, llama a mi hijo» |
| `TELEFONO_VECINO` | el Honor | «Lucero, llama al vecino» |
| `NUMERO_EMERGENCIAS` | el iPhone | «Lucero, llama a emergencias». **Nunca el 911 de verdad** |
| `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, `CASA_CLAVE` | — | Ya están puestas y probadas |

- [ ] Poner los tres números en `local.json`.
- [ ] En la agenda del Infinix, guardar el número del Samsung como «Josuep». Sin eso no hay
      llamada de WhatsApp: cae directo a la llamada normal.
- [ ] `make run` con el Infinix conectado.
- [ ] Aceptar todos los permisos al abrir: micrófono, llamadas, contactos, notificaciones,
      «Mostrar sobre otras apps» y la batería sin optimizar.
- [ ] Ver en la línea de diagnóstico (debajo de la fecha) que el oído oye: dB y clases.
- [ ] En `/f/demo`, ver «Teléfono de la casa conectado, batería …».

## 2. El Samsung: la familia

- [ ] Abrir https://platanus-hack-26-ve-team-25.vercel.app/f/demo/bienvenida e instalar la web
      (en Chrome: «Agregar a la pantalla de inicio»).
- [ ] Suscribirse por Telegram con el botón de la invitación.
- [ ] Guardar el número del Infinix como «Casa de Carmen» y dejar que su llamada suene aunque el
      teléfono esté en silencio: en Samsung, una rutina de Modos y rutinas
      ([por-planificar.md](por-planificar.md#6-que-el-teléfono-del-hijo-suene-aunque-esté-en-silencio)).

## 3. El iPhone: el 911

- [ ] Guardar el número del Infinix como «Casa de Carmen» con **Omitir modo silencioso** en el
      tono del contacto. Sirve además para mostrar el punto 6 en el speech.

## 4. El Honor

- [ ] Esperar la decisión: vista personal o vecino.

## 5. La prueba de punta a punta, en el orden del demo

- [ ] Las cuatro etiquetas puestas y visibles desde la mesa del jurado.

| # | Qué se hace en el Infinix | Qué tiene que pasar |
|---|---|---|
| 0 | En el Samsung, `/f/demo/pastillas/factura`: foto de la factura impresa y confirmar | Sube el losartán y cambian los días que alcanzan; lo que no está en el récipe no se guarda |
| 1 | Mantener presionado «Pastillas de hoy» y decir «ya me la tomé» | Se quita el recordatorio; en `/f/demo/pastillas` del Samsung el losartán baja uno |
| 2 | Un golpe fuerte cerca y decir «Lucero, estoy bien» | Lucero pregunta «Carmen, ¿está bien?» de una vez, y se calla sin avisar a nadie |
| 3 | Otro golpe y no responder | A los 40 s la voz dice que va a llamar a Josuep; a los 60 s el Samsung se pone rojo, le llega el Telegram y suena el WhatsApp |
| 3b | En el Samsung, no contestar el WhatsApp ni la llamada | Al terminar la llamada, el Infinix pregunta «¿Pudo hablar con Josuep?»; a los 15 s llama al iPhone («el 911») en altavoz |
| 4 | Decir «Lucero, llama a emergencias» | Pantalla roja con 5 s; el iPhone recibe una llamada normal, con el Infinix en altavoz |
| 5 | Decir «Lucero, llama a mi hijo» y luego «no» | Se cancela y no llama |
| 6 | Apagar la pantalla del Infinix 10 min y repetir el 2 | Sigue oyendo: lo mantiene vivo el servicio en primer plano |

- [ ] Anotar aquí lo que falló, con el teléfono y la hora.

## 6. Probar la voz

Cada frase se dice a 1 m y a 3 m del Infinix, con la TV apagada y prendida. Se anota ✅ o ❌ y qué
entendió (en modo debug, debajo de la fecha se ve qué oye el oído). Para las llamadas, los números
de `local.json`, nunca el 911 de verdad.

**En reposo:**

| # | Decir | Tiene que pasar |
|---|---|---|
| V1 | «Lucero, llama a mi hijo» | «Llamando a Josuep» 5 s, y llama por WhatsApp (o teléfono) |
| V2 | «Lucero, llama a mi hijo» y a los 2 s «no» | Se cancela y no llama |
| V3 | «Lucero, llama al vecino» | 5 s y llamada normal en altavoz al Honor |
| V4 | «Lucero, llama a emergencias» | Pantalla roja 5 s y llamada en altavoz al iPhone |
| V5 | «Llama a mi hijo», sin «Lucero» | No llama: abre «¿Está bien?» (es un pedido de ayuda) |
| V6 | «Ayuda» · «auxilio» · «me caí» · «me siento malita» · «huele a gas» | Abre «¿Está bien?» con el motivo |
| V7 | Una conversación cualquiera y la TV hablando | No pasa nada |

**Durante «¿Está bien?»** (toque largo en el reloj para dispararla):

| # | Decir | Tiene que pasar |
|---|---|---|
| V8 | «Lucero, estoy bien» en los 4 s de «Le escucho» | Se calla y no avisa |
| V9 | «Lucero, estoy bien» encima del tono, en los últimos 3 s | Se calla (prueba el filtro de la sirena) |
| V10 | «Estoy bien», sin «Lucero» | No se calla |
| V11 | «Ayuda» · «me caí» · «no» | Llama a Josuep de una vez |

**Durante el aviso y la pastilla:**

| # | Decir | Tiene que pasar |
|---|---|---|
| V12 | En «¿Pudo hablar con Josuep?»: «sí» | Cierra el aviso |
| V13 | En «¿Pudo hablar con Josuep?»: «no» | Después del WhatsApp, llama por teléfono; después del teléfono, a emergencias |
| V14 | Ya llamando: «Lucero, estoy bien» | Cierra el aviso y no sale la llamada por teléfono |
| V15 | En el recordatorio (toque largo en «Pastillas de hoy»): «ya me la tomé» | Se quita y el losartán baja uno en `/f/demo/pastillas` |

