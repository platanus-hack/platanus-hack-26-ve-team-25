# Investigación: cómo se sabe si el teléfono está cargando

El teléfono de la casa vive enchufado y el apagón se detecta por la **pérdida de la fuente de
alimentación** ([`investigacion-alertas.md` §3](investigacion-alertas.md)). Todo ese mecanismo
depende de una señal que hay que elegir bien: elegirla mal no da un aviso tardío, da un **apagón
falso permanente**. La app es Flutter, así que la decisión tiene dos capas: qué expone el plugin y
qué hay que escribir del lado nativo.

**La regla, en una línea: `EXTRA_PLUGGED` manda, `isCharging()` nunca.**

## 1. Las señales que expone Android

| Señal | Qué mide | ¿Sirve para el apagón? | Problema |
|---|---|---|---|
| `BatteryManager.EXTRA_PLUGGED` (API 5) | Si hay una fuente de alimentación conectada | **Sí, es la señal** | Ninguno relevante: `0` = con batería, otros valores = tipo de fuente |
| `ACTION_POWER_CONNECTED` / `ACTION_POWER_DISCONNECTED` | El cambio de esa fuente | **Sí, es el disparador** | No es *sticky*: hay que registrar el receiver en ejecución y leer el estado al arrancar |
| `BatteryManager.isCharging()` (API 23) | Enchufado **y** con energía suficiente para que el nivel suba | **No** | Se apaga al 100 %, al límite de carga del 80 % y con un cargador débil |
| `EXTRA_STATUS` / `BATTERY_PROPERTY_STATUS` | Estado de la batería (`CHARGING`, `FULL`, `NOT_CHARGING`) | Solo informativo | `NOT_CHARGING` no significa «desenchufado»: puede ser un límite alcanzado |
| `BATTERY_PROPERTY_CURRENT_NOW` | Corriente instantánea | No | Devuelve `Integer.MIN_VALUE` en MediaTek y Unisoc |

## 2. Por qué `isCharging()` no sirve

La definición oficial de `BatteryManager.isCharging()` es literal: «el dispositivo está enchufado
**y** suministrando energía suficiente para que el nivel de batería suba (o la batería está llena)».
No mide si hay corriente: mide si la batería está ganando carga. Se apaga en tres casos que este
producto provoca a diario:

1. **Batería al 100 %**: el teléfono sigue enchufado y `isCharging()` pasa a `false`.
2. **Límite de carga alcanzado**: [`riesgos.md`](riesgos.md) recomienda activar el límite al 80 %
   para proteger la batería de estar enchufada todo el día. Ese teléfono deja de cargar a los 80 %
   y el sistema reportaría un apagón que nunca termina.
3. **Cargador débil**: un puerto USB flojo deja el teléfono enchufado sin subir el nivel.

**La señal correcta mide presencia de corriente, no estado de la batería** — y es exactamente lo
que el contrato de [`pantallas.md`](pantallas.md) llama `enchufado`: hay fuente de alimentación, no
«la batería sube».

## 3. En Flutter: `battery_plus` informa, el canal nativo decide

`battery_plus` 7.1.2 (BSD-3, publisher verificado, exige Flutter ≥ 3.22 y AGP ≥ 8.12.1) es el
paquete natural para el nivel, y en Android sí tiene un estado honesto:

| `BatteryState` (Dart) | Qué implica en Android |
|---|---|
| `charging` | Enchufado y cargando |
| `connectedNotCharging` | **Enchufado sin cargar**: límite de carga alcanzado, o fuente poco potente. El plugin lo documenta así |
| `full` | Batería llena |
| `discharging` | Con batería, sin fuente |
| `unknown` | El sistema no lo reporta |

Es decir, `enchufado` se puede derivar de los tres primeros estados, y eso ya es mucho mejor que
`isCharging()`. Pero tiene dos límites que importan en este proyecto:

1. **No dice el tipo de fuente** (`BATTERY_PLUGGED_AC`, `_USB`, `_WIRELESS`): solo si hay o no. Para
   el diagnóstico del apagón alcanza; para saber si el cargador es el correcto, no.
2. **El evento viaja por un `EventChannel` al isolate de Dart.** Si el motor de Flutter no está
   corriendo, no hay quien reciba el cambio. Con `flutter_foreground_task` el isolate sobrevive,
   pero el apagón es justo la situación en que todo se degrada: no se puede aceptar que la señal
   dependa de que el motor siga vivo.

Por eso: **`battery_plus` para el nivel que se muestra y se manda al contrato (`bateria`), y un
`EventChannel` propio para el estado de la fuente.** El canal nativo vive en el
`ForegroundService`, lee `EXTRA_PLUGGED` y no depende del ciclo de vida de la pantalla.

## 4. Tres detalles que hunden la implementación si se olvidan

1. **Lectura *sticky* al arrancar.** `ACTION_POWER_CONNECTED` no es *sticky*: si la app arranca (o
   se reinicia tras un apagón de batería) con el teléfono ya enchufado, no llega ningún evento y la
   app cree que está desenchufado. Se resuelve con
   `registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))`, que devuelve el estado
   actual en el acto sin necesidad de un receiver.
2. **Antirrebote de 5 s.** Cargadores baratos y cables flojos producen secuencias
   `CONNECT`/`DISCONNECT` en segundos; sin ventana de confirmación, el demo puede dispararse solo o
   no dispararse porque el estado rebotó. Se confirma el estado y solo se emite evento si persiste
   5 s.
3. **El receiver se registra en ejecución, no en el manifest.** `ACTION_POWER_CONNECTED` y
   `ACTION_POWER_DISCONNECTED` **no** están en la lista de excepciones a los broadcasts implícitos
   de Android 8+, así que declararlos en el manifest no garantiza que lleguen. Se registran desde el
   `ForegroundService` con `ContextCompat.registerReceiver(..., RECEIVER_NOT_EXPORTED)`, que es lo
   que hace `battery_plus` internamente.

## 5. Lo que falta medir, en el teléfono del demo

Ninguna de las dos cosas se puede resolver leyendo documentación; se miden con el teléfono y el
cargador que van a la tarima:

- **Cuánto rebota la señal de carga** con ese cargador y ese cable. Define si la ventana
  antirrebote son 5 s o 10 s.
- **Que `connectedNotCharging` aparezca de verdad** al activar el límite de carga al 80 %. Si el
  teléfono del demo no trae esa opción, se puede forzar el caso con un cargador de poca corriente.

## Fuentes citadas

* **Android Developers**:
  * *`BatteryManager` (referencia de API: `EXTRA_PLUGGED`, `isCharging()`, `BATTERY_PROPERTY_*`):*
    [developer.android.com/reference/android/os/BatteryManager](https://developer.android.com/reference/android/os/BatteryManager)
  * *Monitoring the Battery Level and Charging State:*
    [developer.android.com/training/monitoring-device-state/battery-monitoring](https://developer.android.com/training/monitoring-device-state/battery-monitoring)
  * *Broadcasts implícitos: excepciones (Android 8+):*
    [developer.android.com/develop/background-work/background-tasks/broadcasts/broadcast-exceptions](https://developer.android.com/develop/background-work/background-tasks/broadcasts/broadcast-exceptions)
* **Flutter / comunidad**:
  * *`battery_plus` 7.1.2 (pub.dev):* [pub.dev/packages/battery_plus](https://pub.dev/packages/battery_plus)
  * *`BatteryState` (enum del platform interface, incluido `connectedNotCharging`):*
    [github.com/fluttercommunity/plus_plugins](https://github.com/fluttercommunity/plus_plugins/blob/main/packages/battery_plus/battery_plus_platform_interface/lib/src/enums.dart)
