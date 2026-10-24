# Preguntas técnicas

Las preguntas que un juez técnico probablemente haga, con la respuesta corta y la evidencia. Cada
respuesta dice en qué estado está:

- ✅ **Hecho**: está en el código o en un experimento que se puede correr.
- 📐 **Diseñado**: decidido y escrito en los documentos, todavía no en código.
- ⏳ **Pendiente**: aún no se sabe o no se ha medido.

Al 24-oct-2026. Cuando una pieza pase a código, se actualiza aquí.

## El audio y la privacidad

### ¿El audio sale del teléfono?

✅ **No, en la prueba `/escucha`.** El audio vive solo en un buffer circular de 5 s en memoria que
se pisa a sí mismo ([`anillo.ts`](../web/src/lib/escucha/anillo.ts)). El modelo corre en el
navegador con MediaPipe ([`escucha.tsx`](../web/src/app/escucha/escucha.tsx)) y no hay ninguna
llamada de red con audio.

📐 En la app de la casa es igual: al servidor solo van etiquetas de eventos, alertas y latidos
([plan.md](plan.md)).

### ¿Por qué no limpian el audio antes del modelo?

✅ Porque YAMNet se entrenó con audio crudo y ruidoso, y los supresores de ruido borran justo lo
que buscamos: golpes y alarmas. La prueba pide el micrófono con `echoCancellation`,
`noiseSuppression` y `autoGainControl` apagados
([`escucha.tsx`](../web/src/app/escucha/escucha.tsx)). El razonamiento está en
[investigacion-audio.md §1.2](investigacion-audio.md).

## El modelo

### ¿Por qué YAMNet y no otro modelo?

✅ Comparamos 9 modelos de 4 familias (YAMNet, EfficientAT, PANNs y sherpa-onnx) con 640 sonidos
de casa del set ESC-50 ([experimento](../experimentos/modelos-audio/README.md)):

- Con ventanas de 1 s, YAMNet acierta más (82% en el top-5), pesa 4,1 MB y analiza 1 s de audio
  en 2,5 ms en una CPU de escritorio.
- Con ventanas de 5 s, los modelos CED de sherpa-onnx llegan a 86–87%, contra 81% de YAMNet.

Nos quedamos con YAMNet porque ya funciona y la diferencia es chica. El alternativo es sherpa-onnx
CED tiny, que además trae la palabra clave y la detección de voz en el mismo paquete de Flutter.
Las tablas: [resultados-1s.md](../experimentos/modelos-audio/resultados-1s.md),
[resultados-5s.md](../experimentos/modelos-audio/resultados-5s.md).

### ¿Los modelos en PyTorch se pueden usar en el teléfono?

✅ Sí. [`exportar_onnx.py`](../experimentos/modelos-audio/exportar_onnx.py) pasa EfficientAT y
PANNs a ONNX con el espectrograma adentro, y la salida coincide con PyTorch (diferencia máxima
menor a 0,000001). En Flutter corren con ONNX Runtime.

### ¿Qué tan rápido corre en un teléfono viejo?

⏳ No medido todavía. En la computadora, YAMNet analiza 1 s de audio en 2,5–4,8 ms con un hilo.
Falta medirlo en un Android de 2019 conectado por USB.

### ¿Funciona con la voz de una persona mayor?

⏳ No medido todavía. Las voces mayores son más débiles, aireadas y temblorosas, y el
reconocimiento de voz se equivoca más con ellas
([investigacion-audio.md §1.1](investigacion-audio.md)). El plan: medir con voces de 60 años o
más de Mozilla Common Voice y con notas de voz donadas. Mientras no esté medido, no lo afirmamos.

## Las falsas alarmas

### ¿Cómo evitan avisarle a la familia por cualquier ruido?

Por capas, de la más barata a la más cara:

| Capa | Qué hace | Estado |
|---|---|---|
| Compuerta de dB | Mide el nivel contra el fondo aprendido de esa casa. Un golpe aislado casi no mueve el fondo; una TV prendida lo sube poco a poco | ✅ [`nivel.ts`](../web/src/lib/escucha/nivel.ts), con pruebas |
| Clases de YAMNet | Las 521 clases se reducen a 6 tipos (alarma, vidrio, golpe, grito, TV, rutina), con un umbral de 0,3. La TV y la rutina no son alertas | ✅ [`eventos.ts`](../web/src/lib/escucha/eventos.ts), con pruebas |
| Sin repeticiones | El mismo tipo de evento no se anota más de una vez cada 3 s | ✅ [`escucha.tsx`](../web/src/app/escucha/escucha.tsx) |
| Sonido más vibración | Un golpe que suena y también hace vibrar el teléfono. La TV puede gritar, pero no mueve el piso | 📐 [contexto.md](contexto.md) |
| Confirmación humana en la casa | Una alarma de 60 s con «Estoy bien» y «Necesito ayuda». Una falsa alarma cuesta un toque, no un susto a la familia | 📐 [plan.md](plan.md) |
| Calibración por casa | Cada alarma apagada queda anotada como falsa en esa casa y ajusta sus umbrales | 📐 [plan.md](plan.md) |
| Niveles y tope diario | 🔴 urgente, 🟡 para saber, 🟢 todo bien. Fuera del rojo, uno o dos avisos al día como máximo | 📐 [riesgos.md](riesgos.md) |

### ¿Y una caída silenciosa?

📐 El golpe no siempre suena. Por eso la rutina es una señal principal: conteos de qué suena y se
mueve en cada franja del día (agua, cocina, puerta, TV, luz). Si a la hora de siempre falta todo,
se avisa ([investigacion-audio.md §2 y §3](investigacion-audio.md)). Está en P1.

## La alerta

### ¿Cómo se garantiza que una alerta escale una sola vez?

📐 La casa registra la alerta en Supabase con su hora de vencimiento. Si nadie la cancela, el
primero que vea el vencimiento (la casa o cualquier teléfono de la familia) la escala. El paso de
«pendiente» a «escalada» es un cambio de estado atómico: solo una escritura puede ganarlo. Así
la alerta escala aunque el teléfono de la casa se apague en plena alarma
([plan.md](plan.md), P0 punto 3).

### ¿Qué pasa si se va la luz, el internet o la señal?

📐 Está en [riesgos.md §4](riesgos.md):

- **Sin luz:** el teléfono sigue con su batería y detecta que dejó de cargar.
- **Sin internet:** la alarma local suena igual y los eventos esperan en cola.
- **Sin ninguna señal:** la alarma pasa a sirena para los vecinos.
- **Teléfono apagado:** deja de llegar el latido y la familia ve «sin señal desde las 14:05».

### ¿Qué pasa si el teléfono se reinicia?

📐 Desde Android 14 y 15, un servicio de micrófono no puede arrancar solo al encender el teléfono.
La salida es que la app sea la pantalla de inicio del teléfono: al encender, Android la abre y,
como está a la vista, puede arrancar el micrófono ([riesgos.md §3](riesgos.md)). La prueba de
reinicio está pendiente.

### ¿Por qué la casa es Android y no iPhone?

📐 iOS no deja escuchar todo el día en segundo plano, y sin la cuenta de Apple paga la instalación
vence a los 7 días ([riesgos.md §2](riesgos.md)). La familia sí puede usar cualquier teléfono: entra
por web y recibe el aviso por Telegram.

## Seguridad

### ¿Cómo se protege el enlace de invitación de la familia?

⏳ Pendiente de implementar. Es lo primero que hay que cerrar en el código de Supabase:

- El enlace lleva un token aleatorio de al menos 128 bits, imposible de adivinar, y se puede
  revocar.
- Reglas de acceso por fila (RLS) en Supabase: cada token solo ve los datos de su casa.
- Las llaves de Supabase y de Telegram nunca van al repo, que es público.

### ¿Qué datos personales guardan?

📐 Etiquetas de eventos con su hora, alertas, latidos y el perfil de la casa (nombre, contactos,
condición de salud), nunca audio ([plan.md](plan.md)). Para el demo, todos los datos son
inventados.

## Cómo comprobarlo

```bash
cd web && bun install && bun test          # 12 pruebas de la lógica de audio
cd experimentos/modelos-audio && uv sync && ./descargar.sh && uv run comparar.py
```
