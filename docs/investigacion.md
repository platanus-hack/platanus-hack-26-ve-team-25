# Investigación por persona

> Las preguntas abiertas de cada uno, con lo que ya sabemos para no partir de cero. Cada quien
> anota aquí lo que encuentra, **con fuente**. Lo que se decide pasa a [plan.md](plan.md).

## Josuep · Alertas y conexión

**Preguntas:**

1. ¿Cómo filtramos para que la familia no reciba falsas alarmas?
2. Botón de pánico y botón «¿Está bien?»: ¿cómo se ven y qué disparan?
3. ¿Cómo sale una alerta con señal mínima, sin wifi o sin luz?

**Lo que ya sabemos:**

- El filtro principal es humano: la alarma de 60 s en la casa. Encima van la fusión de sonido y
  vibración y los umbrales que se ajustan con cada falsa alarma apagada.
- Tres niveles de aviso (🔴 🟡 🟢) y un presupuesto de avisos al día: ver
  [riesgos.md](riesgos.md#la-regla-de-oro-despreocupar-no-angustiar).
- **Botón de pánico:** va directo a 🔴, sin los 60 s.
- **Check-in «Estoy bien»:** la persona lo toca en la mañana y la familia recibe el 🟢 del día.
- **Al apagar una alarma:** dos botones, «Estoy bien» y «Necesito ayuda».
- **Sin conexión:** cola local que se reenvía al volver, SMS desde el chip en Android y latido
  cada pocos minutos para que el silencio avise. Detalle en
  [riesgos.md](riesgos.md#4-sin-luz-sin-wifi-sin-datos).

**Por resolver:**

- [ ] Canal real: Telegram (recomendado: gratis y suena en iOS sin cuenta de Apple paga) o correo
- [ ] **Latido y silencio** (C4 y C5): cada cuánto late el teléfono, cuánto silencio es «sin señal» y **quién lo declara**. Hoy no hay servidor con cron que lo haga. La tabla de lo que falta y la propuesta de 90 s / 180 s están en [investigacion-alertas.md](investigacion-alertas.md#el-dead-mans-switch-pendiente-de-decidir)
- [ ] Probar el SMS desde el chip en Android con Flutter

## Abrahan · La IA

**Preguntas:**

1. ¿Local o en la nube?
2. ¿YAMNet u otro modelo?
3. ¿Se entrena con la voz específica del usuario?
4. ¿Cómo se usa a la persona como sensor?

Detalle de las frecuencias de la voz, los modelos candidatos y la personalización por casa en
[investigacion-audio.md](investigacion-audio.md).

**Lo que ya sabemos:**

- **Local, decidido:** el audio nunca sale del teléfono (privacidad), funciona sin internet (el
  caso venezolano) y no cuesta nada por uso. YAMNet ya corre en el navegador en `/escucha`.
- **En Flutter:** YAMNet existe como `.tflite` y corre con `tflite_flutter`. Hay que comprobar
  que corra fluido en un Android viejo.
- **La nube no va en el camino de la alerta**, porque sin internet tiene que funcionar igual. Si
  se usa Claude ($50 de crédito), es para cosas que pueden esperar, como redactar el resumen del
  día. Lo decide Rogelio.
- **Voz específica, no en el hackatón.** YAMNet no distingue voces, y entrenar con la voz de una
  persona necesita grabaciones suyas y tiempo que no tenemos. Lo que sí cabe: reconocer en el
  teléfono una palabra clave («¡auxilio!», «¡ayuda!») con el reconocimiento de voz del sistema,
  que funciona sin conexión. Va como extra.
- **La persona como sensor** es barato y vale mucho: lo que ella reporta está confirmado por un
  humano y no es falso positivo. Botones en la pantalla de la casa:

  | Botón | Qué es | Nivel |
  |---|---|---|
  | «Huele a gas» | El sensor de gas que no tiene (bombonas) | 🔴 |
  | «Huele a quemado» | El sensor de humo | 🔴 |
  | «Me siento mal» | Pide que la llamen | 🔴 |
  | «Me caí, pero estoy bien» | Queda en el historial para la familia | 🟡 |

**Por resolver:**

- [ ] Probar `/escucha` con micrófono real: alarma de humo, golpe, grito, TV
- [ ] YAMNet en Flutter: ¿cuánto tarda por ventana en un Android viejo?
- [ ] Qué clases de YAMNet pesan para «gas» o «agua corriendo» (llave abierta), si alguna sirve

## Anttony · Antecedentes y usuarios

**Preguntas:** el tamaño del problema, quién lo sufre y quién pagaría.

**Lo que hay que traer, con fuente:**

- [ ] Venezolanos emigrados (R4V, ~8 millones por confirmar)
- [ ] Adultos mayores que viven solos en Venezuela (INE o encuestas como ENCOVI)
- [ ] Caídas en casa de adultos mayores: cuántas y qué pasa si nadie llega a tiempo (OMS)
- [ ] Apagones en Venezuela: frecuencia y duración por región
- [ ] Pacientes que dependen de equipos eléctricos (oxígeno) en casa
- [ ] Qué parte de los teléfonos en Venezuela son Android
- [ ] Cuánto cuesta un SMS y una llamada local desde un chip venezolano, y si un SMS al exterior
  llega
- [ ] Cuántas horas aguantan las antenas de telefonía en un apagón largo
- [ ] Cuánto paga hoy la diáspora por cuidar a sus padres (cuidadoras, CareBridge y similares)
- [ ] **Usuarios reales para el pitch:** dos o tres emigrados del entorno que digan cuántas veces
  llaman a sus padres al día. Un testimonio vale más que una cifra. Se cuenta con su permiso y sin
  datos que los identifiquen

**El cliente:** paga el que emigró (en dólares, desde afuera) y lo usa el que se quedó. Son dos
personas distintas con necesidades distintas.

## El perfil de salud

**La pregunta:** ¿los patrones son de cada persona o hay modelos generales?

**La respuesta: las dos cosas, en capas.**

1. **Reglas generales por condición.** No hay que entrenar nada y se pueden defender ante un
   jurado. La condición cambia el nivel del aviso o el umbral:

   | Condición (inventada en el demo) | Qué cambia |
   |---|---|
   | Usa concentrador de oxígeno u otro equipo eléctrico | **Apagón = 🔴 inmediato.** Para otra persona es 🟡 |
   | Riesgo de caídas o movilidad reducida | Umbral de golpe más sensible. Rutina vigilada más de cerca |
   | Hipertensión o diabetes | Inactividad larga a media mañana pasa a 🔴 antes |
   | Hipoacusia | La alarma destella y vibra, además de sonar |
   | Deterioro cognitivo | Apagar la alarma no basta: también avisa 🟡 |

2. **Calibración por casa.** Con los datos de esa casa, sin reentrenar el modelo: umbrales que
   se ajustan con cada falsa alarma apagada y la hora habitual de levantarse.

Entrenar un modelo propio por persona no cabe en 30 horas, y no hay datos para hacerlo. Lo que sí
mostramos en el demo: **el mismo apagón en dos casas da dos avisos distintos.**
