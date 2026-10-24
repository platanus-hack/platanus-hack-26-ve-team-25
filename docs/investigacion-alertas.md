# Investigación: capa de alertas (entrega, escalamiento y fallos)

Cómo asegurar que la alerta llegue a la familia aunque se corte la luz, caiga el Wi-Fi, la red celular sea precaria y el teléfono sea un Android Go de menos de 70 USD sin servicios de Google. Al 24-oct-2026.

---

## 1. Transporte con señal deficiente y sin GMS

En un teléfono de menos de 100 USD (típicamente Android Go con 1–2 GB de RAM y chipsets Unisoc o MediaTek de entrada), **no se puede asumir la presencia de Google Mobile Services (GMS)**. Si el equipo es importado o sin certificar, carece de Firebase Cloud Messaging (FCM) y de bibliotecas propietarias de Google Play. La aplicación se distribuye vía sideload (APK directo), lo que libera al proyecto de las restricciones de la tienda de Google y permite interactuar directamente con la pila de telefonía celular nativa.

| Canal | Funciona sin datos | Requiere GMS | Permisos Android | Coste | Latencia | Fiabilidad | Caveat | Veredicto |
|---|:---:|:---:|---|---|---|:---:|---|---|
| **HTTP/REST (Webhook)** | No | **No** | `INTERNET`, `ACCESS_NETWORK_STATE` | Mínimo (datos/Wi-Fi) | 200–800 ms | **Alta** (si hay enlace IP) | Inoperante si cae el router durante un corte o no hay datos móviles | **Canal primario** (con red activa) |
| **SMS directo (`SmsManager`)** | **Sí** | **No** | `SEND_SMS`, `READ_PHONE_STATE` | Tarifa SMS local | 2–10 s | **Alta** (canal de señalización 2G) | Rate limiting del SO (~30 SMS/min); no pasa la tienda sin exención (no aplica en sideload); **ningún acuse sirve de compuerta** | **Último recurso pasivo** (offline) |
| **Heartbeat inverso (Dead Man's Switch)** | N/A (servidor infiere) | **No** | `INTERNET` (en pings) | Tráfico despreciable | Configurable (p.ej. 180 s) | **Muy alta** | Si el intervalo es muy corto satura la radio; depende del backend en la nube | **Obligatorio** para fallos catastróficos |
| **Llamada saliente (`ACTION_CALL`)** | **Sí** | **No** | `CALL_PHONE` | Tarifa de voz local | 5–15 s | Media | `CALL_STATE_OFFHOOK` está activo mientras suena, así que **no se puede saber si contestaron**; en 2G corta los datos; no se usa para llamar al exterior | **Canal que despierta a un humano** (offline), sin acuse fiable |
| **FCM High-Priority** | No | **Sí** | GMS Play Services | Gratuito | 1–5 s | Media (Doze en Go) | Inútil en AOSP puro sin certificar; requiere cuenta Google activa en el dispositivo | **Descartado** en el dispositivo emisor |
| **USSD (`sendUssdRequest`)** | **Sí** | **No** | `CALL_PHONE` | Bajo/Gratuito | 3–8 s | **Muy baja** | APIs inestables o bloqueadas en SoCs de bajo coste; sintaxis atada al operador | **Descartado** |
| **BLE a vecino** | **Sí** | **No** | `BLUETOOTH_ADVERTISE`, `ACCESS_FINE_LOCATION` | Gratuito | N/A | **Nula** | Requiere receptor preinstalado a <10 m; hardware RF de gama baja es errático | **Descartado** |

### Decisiones de diseño en transporte

1. **Dual-Stack en orden de urgencia (HTTP → llamada → SMS)**: El canal primario es HTTP por rapidez y densidad de telemetría. Si el socket no responde en **10 s** o el sistema reporta desconexión de red, se pasa a la llamada al contacto local, que es el único canal que hace sonar un teléfono ajeno. El SMS queda al final. En 2G/EDGE un POST con TLS tarda más de 3 s, así que un timeout corto mandaba SMS innecesarios y gastaba saldo.
2. **Ningún canal celular confirma solo**: `SMS_SENT` dice que el PDU salió de la antena y `SMS_DELIVERED` depende del operador: llega tarde o no llega. En la llamada, `CALL_STATE_OFFHOOK` se activa al marcar y sigue activo mientras el otro teléfono **suena**, así que no distingue «contestó» de «está sonando». La única compuerta fiable es un humano: que alguien marque la alerta como atendida en la web o en Telegram.
3. **Dual SIM resuelto por API de bajo nivel**: Para terminales con dos ranuras SIM, se consulta `SubscriptionManager.getActiveSubscriptionInfoList()` y se obtiene `SmsManager.getSmsManagerForSubscriptionId(subId)`. Si falla o no hay datos, se usa `SmsManager.getDefault()`.
4. **El Heartbeat Inverso no es un fallback del teléfono**: El teléfono no "salta" al heartbeat si todo falla; el heartbeat corre como monitor pasivo paralelo en el servidor. Si el hardware sufre un daño físico, se apaga o la celda celular colapsa, **el silencio es la alerta**.

---

## 2. Garantías de entrega y persistencia

En Android Go, el daemon de memoria del kernel (`lmkd`) liquida procesos sin previo aviso ante picos de uso de RAM. Ningún evento crítico puede residir únicamente en memoria volátil.

```text
[ Detección de Evento ]
         │
         ▼
[ Escritura en SQLite / Room ] ──► Estado: PENDING, attempts: 0, UUIDv4
         │
         ▼
[ T1 · POST /alerta (timeout 10 s) ]
         │
         ├── 2xx ──► Estado: ACK_SERVER ──► fin de la cadena
         │
         └── NO / timeout / error
                 │
                 ▼
[ T2 · ACTION_CALL al contacto local ] ──► hasta 25 s, sin acuse posible
                 │
                 └── al terminar la llamada, o a los 25 s
                         │
                         ▼
[ T3 · SmsManager (PDU) al contacto local y al vecino ] ──► Estado: SENT
         ├── BroadcastReceiver (SMS_SENT) ──► Confirmación de salida de antena
         └── BroadcastReceiver (SMS_DELIVERED) ──► Informativo: no detiene ni avanza nada
```

| Mecanismo | Implementación | Propósito |
|---|---|---|
| **Persistencia pre-envío** | SQLite plano o Room antes de tocar la radio de red | Si el SO mata el proceso durante la transmisión, el evento no se pierde |
| **Idempotencia (Deduplicación)** | Cada evento genera un `UUIDv4` inmutable en el teléfono | Si se reintenta el POST mientras el escalamiento ya hizo la llamada o el SMS, el backend procesa el primero y descarta duplicados |
| **Muerte del proceso y reinicio** | Cola local en SQLite + `RECEIVE_BOOT_COMPLETED` que la barre al arrancar. La escucha **no** vuelve sola | Los `PENDING` se reintentan y nada se pierde. Pero `BOOT_COMPLETED` no puede levantar un servicio de micrófono: la app pide «Toque para volver a cuidar» y, mientras tanto, la familia ve el silencio |
| **Reintentos con Backoff** | $t_{\text{espera}} = \min(60\text{ s}, 2^{\text{intentos}} \times 2\text{ s})$ | Evita saturar el canal de señalización o agotar el saldo de la SIM ante caídas de la antena |

---

## 3. Detección de corte eléctrico y perfil energético

El teléfono permanece enchufado permanentemente. La señal fiable del apagón es que **deja de cargar** (`ACTION_POWER_DISCONNECTED`): es barata, llega al instante y no requiere escanear la red. El Wi-Fi del router sirve para **desambiguar el texto del aviso**, no para autorizar el evento. En los dos casos el evento sale; el perfil de salud decide el nivel.

| Condición | Evento de carga (`BatteryManager`) | Estado Wi-Fi (`ConnectivityManager`) | Texto del aviso | Nivel |
|---|---|---|---|---|
| **Apagón general** | `ACTION_POWER_DISCONNECTED` | `NetworkCallback.onLost` dentro de la ventana de 40 s | «Se fue la luz en la casa» | Lo decide el perfil |
| **Corte de energía sin confirmar** (cargador flojo, o router con UPS) | `ACTION_POWER_DISCONNECTED` | Wi-Fi sigue conectado, o el teléfono está en datos móviles | «El teléfono dejó de cargar» | Lo decide el perfil |
| **Caída aislada de ISP** | `ACTION_POWER_CONNECTED` | `NET_CAPABILITY_VALIDATED` perdido | Sin aviso: se anota como estado | — |

**Cuatro reglas de esta detección:**

1. **El Wi-Fi nunca es requisito.** Si el teléfono está en datos móviles —lo normal si el router no llega al pasillo, que es donde va el teléfono— no hay `onLost` que correlacionar y el evento sale igual, con el texto sin confirmar. Perder el evento por no tener Wi-Fi sería peor que no distinguir la causa.
2. **La ventana es de 40 s**, no «simultáneo». `ACTION_POWER_DISCONNECTED` llega al instante, pero Android tarda entre 5 y 30 s en declarar perdido un Wi-Fi cuya baliza desapareció. Sin ventana explícita, dos implementaciones distintas dan resultados distintos.
3. **El router puede tener respaldo.** En Venezuela es común tener el router en una UPS o un inversor y el cargador del teléfono en un tomacorriente normal: se va la luz, el Wi-Fi sobrevive y el cargador muere. Ese caso cae en «sin confirmar», y por eso el texto **no afirma** que se fue la luz.
4. **No se escanea la red.** Solo se usa `NetworkCallback`, porque Android limita los escaneos activos a uno cada 30 minutos en segundo plano. La correlación sale gratis.

**El nivel lo pone el perfil, no el evento.** Un apagón en una casa con concentrador de oxígeno es 🔴 inmediato; en una casa sin equipo eléctrico es 🟡 ([`investigacion.md`](investigacion.md#el-perfil-de-salud), [`plan.md`](plan.md#demo)). El evento no fuerza urgencia por sí solo: si lo hiciera, se perdería la demostración de «el mismo apagón, dos avisos».

### Cómo se sabe si el teléfono está cargando

La elección de la señal de carga tiene investigación propia en [`investigacion-carga.md`](investigacion-carga.md). Lo que este documento usa de ella:

- **`BatteryManager.EXTRA_PLUGGED`** (¿hay fuente de alimentación?) es la señal. `isCharging()` está descartado: se apaga al llegar al límite de carga del 80 % y convertiría cada apagón en permanente.
- `ACTION_POWER_CONNECTED` / `ACTION_POWER_DISCONNECTED` disparan el cambio, con antirrebote de 5 s y lectura *sticky* al arrancar.
- En Flutter, `battery_plus` da el nivel (`bateria`); el estado de la fuente va por un `EventChannel` nativo dentro del `ForegroundService`, para no depender de que el motor de Flutter siga vivo.
- `enchufado` significa «hay fuente de alimentación», no «la batería sube».

### Medición de consumo y autonomía en chips económicos
En procesadores gama baja (Unisoc/MediaTek), `BATTERY_PROPERTY_CURRENT_NOW` devuelve con frecuencia `Integer.MIN_VALUE`. La estimación de autonomía se calcula midiendo el tiempo entre deltas reales de porcentaje:

1. **Monitoreo por deltas**: Mediante `ACTION_BATTERY_CHANGED`, se registra el tiempo $\Delta t$ que toma descender cada 1% de carga.
2. **Estimación**: $\text{Minutos restantes} = \text{Batería actual (\%)} \times \overline{\Delta t}$.
3. **Mensaje de despedida (Last Gasp)**: Si la batería desciende a $\le 5\%$, se congelan los algoritmos pesados de escucha y se despacha un SMS prioritario de última voluntad: `{"e":"LAST_GASP","bat":5,"t":1729738000}`.

---

## 4. Política y máquina de estados de escalamiento

El sistema minimiza falsos positivos en el recinto antes de escalar a la familia en el exterior o a los contactos locales. **El escalamiento no empieza a los 0 s: empieza a los 60 s**, cuando la alarma de la casa ya venció y nadie la apagó. Y los canales van por urgencia: primero el que llega a una pantalla, después el que hace sonar un teléfono ajeno, al final el que espera a que alguien lo lea.

```text
[ T0 · Alarma en la casa (0 s) ]  (520 Hz + vibración, 60 s)
       │
       ├── La persona la apaga ──► [ CANCELADA ] ──► 🟡 y calibra los umbrales de esa casa
       │
       ▼ NO la apaga (vence a los 60 s)
[ T1 · HTTP/REST (60 s) ]  POST /alerta, timeout 10 s
       │
       ├── 2xx ──► [ ACK_SERVER ] ──► fin: no se llama ni se manda SMS
       │
       └── sin socket · timeout · error
               │
               ▼
[ T2 · Llamada (≈70 s) ]  ACTION_CALL al contacto local, en altavoz
       │  (hasta 25 s, o hasta que la llamada termine sola)
       │
       ▼
[ T3 · SMS (≈95 s) ]  al contacto local y al vecino. Último escalón: no se confirma
```

Entre el T1 y el T2 **no hay espera**: el T2 es la rama de fallo del POST, no un temporizador. **La llamada tampoco decide nada**, y eso hay que decirlo claro: Android no expone si el otro lado contestó. `CALL_STATE_OFFHOOK` se activa al marcar y permanece activo mientras el teléfono del vecino suena, así que un tono de llamada de 20 s es indistinguible de una conversación de 20 s. Por eso la llamada tiene un tope de 25 s y **el SMS sale siempre después**, conteste quien conteste.

Lo único que detiene la cadena es un humano: que alguien marque la alerta como atendida en la web o en Telegram, o que la persona en la casa apriete «Estoy bien». Si nadie acusa, la cadena llega hasta el final. El aviso digital del T1 sale a los 60 s cumplidos, no antes; adelantarlo anularía el filtro humano que es la defensa principal contra falsos positivos.

Después del T3 la cadena automática termina: no hay un T4, porque no habría con qué condicionarlo. Lo que sigue es la familia actuando.

### Quién avanza de un escalón al siguiente

La alerta se guarda como una fila con `estado`, `paso`, `vence_en` y `escalado_por`. El paso cambia con un update atómico (`UPDATE … WHERE id = ? AND paso = 'T1' AND estado = 'ABIERTA'`), así que dos clientes que vean lo mismo no escalan dos veces. Es el mismo patrón de vencimiento que ya usa el P0 para la alerta de 60 s.

| Situación | Quién avanza |
|---|---|
| El POST responde 2xx | Nadie: el backend se encarga de la web y de Telegram |
| La casa tiene señal de voz | La propia casa, porque el chip está ahí: el T2 y el T3 solo los puede disparar ella |
| La casa se quedó sin datos pero con señal | La casa igual: la llamada y el SMS no necesitan internet |
| La casa perdió todo | No hay escalón posible desde el teléfono; la familia lo ve por el silencio del latido |

### Los contactos son locales

El cliente que paga vive fuera del país, pero **el chip de la casa no lo alcanza**. La cadena celular existe para los que están cerca, y esto hay que decirlo en el pitch antes de que lo pregunte el jurado.

| Canal | Destinatario | Qué pasa con la familia en el exterior |
|---|---|---|
| **T1 · HTTP → backend** | Web de la familia y Telegram | **Es el único canal que llega afuera**, y solo con internet |
| **T2 · Llamada** | Contacto local (vecino, familiar en la ciudad) | Una llamada desde un chip venezolano al exterior cuesta y no siempre cursa: no se usa así |
| **T3 · SMS** | Contacto local y vecino | Igual: no se asume que un SMS al exterior llegue, ni que sea barato |

Consecuencia, que es la parte incómoda: **si el T1 falla, la familia en el exterior no recibe la alerta**. Lo que recibe es el silencio: el latido deja de llegar y la web muestra «sin señal desde las 14:05», con un botón para escribirle al vecino. La alerta accionable la recibe el que está cerca; el que está lejos se entera de que algo pasa y a quién llamar.

La salida para el aviso directo al exterior es una pasarela de SMS o llamadas (Twilio o similar), que está en [`futuro.md`](futuro.md) y depende de ingresos. En el hackatón no existe, y el documento no debe sugerir lo contrario.

### La alarma de confirmación

`investigacion-audio.md` ya decidió el tono: **520 Hz en onda cuadrada, no un pitido agudo**, porque es el que despierta al 92 % de las personas con pérdida auditiva. La voz de «¿Está bien?» va grave, lenta y fuerte, con la pantalla destellando y el teléfono vibrando. La duración es de **60 s**, también en el demo: lo que se muestra en la tarima es el producto, no una versión comprimida.

### El Dead Man's Switch en el Servidor (Paralelo)

* El teléfono envía un ping ligero (`{"id":25,"bat":95,"pwr":1}`) cada **90 segundos**.
* Si el backend acumula **180 segundos continuos** (2 pings perdidos) sin contacto:
  * El servidor asume pérdida de enlace o fallo crítico del terminal.
  * Dispara alerta autónoma a los familiares: *"Pérdida total de conexión con el dispositivo en la casa desde hace 3 minutos"*.

---

## 5. Plan de demo (3 minutos, sin depender del Wi-Fi del venue)

El objetivo es demostrar que la alerta sale aun cuando se cortan la luz y los datos móviles al mismo tiempo. **Los tiempos son los del producto**: 60 s de alarma, 10 s de timeout del POST y hasta 25 s de llamada. Nada comprimido.

* **Requisitos:** El teléfono Android de la prueba (con SIM y saldo de voz y SMS), el teléfono del evaluador o juez registrado como contacto local, y un router Wi-Fi portátil conectado a la misma regleta que el cargador del teléfono.

| Tiempo | Qué se hace | Qué muestra la pantalla / Qué ocurre | Qué se demuestra |
|---|---|---|---|
| **0:00 – 0:20** | Estado nominal | Teléfono en pantalla fija: "Monitoreando: AC conectado, Wi-Fi OK". El teléfono del evaluador en reposo sobre la mesa | Sistema operativo en régimen normal |
| **0:20 – 0:45** | Desconexión física de la regleta | Se desenchufa la regleta completa: caen el cargador y el router portátil al mismo tiempo. En <2 s la pantalla cambia a: *"Se fue la luz en la casa"*. Se desactivan además los datos móviles | Apagón confirmado por la caída del Wi-Fi, y pérdida inducida del canal IP |
| **0:45 – 0:55** | Se dispara el evento | Se deja caer el morral junto al teléfono (golpe + vibración). Arranca la alarma de confirmación | El evento nace en la casa, sin intervención de nadie |
| **0:55 – 1:55** | La alarma de 60 s | 520 Hz en onda cuadrada, la voz «¿Está bien?», la pantalla destella y el teléfono vibra. Nadie la apaga | El filtro humano: la familia no se enteró de nada todavía |
| **1:55 – 2:05** | El POST falla | La pantalla pasa a *"Sin red. Escalando"*. El POST se corta a los 10 s sin datos | El canal primario se agota y no se insiste |
| **2:05 – 2:25** | La llamada | El teléfono de la casa llama en altavoz al contacto local. Suena unos 20 s en el teléfono del evaluador y la red la corta | La llamada hace sonar un teléfono ajeno sin depender de internet |
| **2:25 – 2:35** | El SMS | Salen los SMS al contacto local y al vecino. Suenan los dos teléfonos con el mensaje de auxilio | **La cadena llega al último recurso sin GMS ni internet** |

Cinco cosas que hay que decir en voz alta durante el demo:

1. **Aunque el evaluador conteste, el SMS sale igual.** Android no distingue una llamada contestada de una que está sonando, así que la llamada no puede ser la compuerta. Lo que detiene la cadena es que alguien marque la alerta como atendida en la web o en Telegram.
2. **Si se usara el botón de pánico, la cadena arrancaría sin los 60 s**, porque es 🔴 directo. El demo usa un golpe detectado justamente para que se vea la alarma de confirmación.
3. **La llamada dura lo que dura el tono.** En la prueba del 24-oct sonó 20 s y la red la cortó sola; la contestadora no entró nunca. Hay que repetir la prueba con la SIM que va a estar en la tarima, porque el corte del tono depende del operador.
4. **Margen de sobra:** el SMS llega alrededor de 2:25 y quedan unos 35 s para el cierre. Si la llamada se corta antes, el SMS sale antes.
5. **La llamada y el SMS van a números locales.** La familia en el exterior no los recibe: si el POST falló, lo que le llega es el «sin señal» de la web. Es la limitación real del chip de la casa, y se dice antes de que la pregunten.

---

## 6. Top 3 riesgos técnicos y mitigación

| # | Riesgo | Por qué es crítico | Mitigación |
|---|---|---|---|
| 1 | **Matanza por Doze Mode / OEM en Android Go** | Fabricantes con ROMs agresivas cierran procesos en background para liberar los 2 GB de RAM | Implementar `ForegroundService` con notificación persistente, solicitar exclusión explícita (`ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`) y retener `PARTIAL_WAKE_LOCK` |
| 2 | **Filtros anti-spam del operador móvil** | Enviar SMS repetidos durante pruebas o emergencias puede suspender la línea prepago | Incorporar un nonce aleatorio y timestamp variable en el cuerpo del mensaje; fijar límite de salida a 1 SMS cada 30 segundos |
| 3 | **Bloqueo del hilo de UI al invocar telefonía** | Consultar `SubscriptionManager` o invocar la SIM en chips lentos puede provocar un ANR (Application Not Responding) | Envolver todas las llamadas a ContentProviders de telefonía y `SmsManager` en hilos de fondo (`Dispatchers.IO`) con timeouts estrictos |

---

## 7. Paquetes y APIs nativas

| Componente | API nativa / Paquete | Rol en la arquitectura |
|---|---|---|
| **Telefonía y SMS** | `android.telephony.SmsManager` | Envío directo de PDU celular saltándose la pila IP. Último escalón, sin acuse |
| **Llamada saliente** | `Intent.ACTION_CALL` + `TelephonyManager.getCallState()` | Marca al contacto local, mantiene el altavoz y detecta cuándo termina la llamada; **no** distingue si contestaron |
| **Gestión Dual SIM** | `android.telephony.SubscriptionManager` | Selección de ranura celular activa y extracción de `subId` |
| **Red y conectividad** | `android.net.ConnectivityManager.NetworkCallback` | Detección de pérdida de Wi-Fi en tiempo real mediante `onLost()` |
| **Estado de carga** | `BatteryManager.EXTRA_PLUGGED` vía `EventChannel` nativo; `ACTION_BATTERY_CHANGED` en modo *sticky* para la lectura inicial ([`investigacion-carga.md`](investigacion-carga.md)) | Detección de apagón por pérdida de fuente. `isCharging()` está descartado: confunde «límite de carga» con «desenchufado» |
| **Nivel de batería** | `battery_plus` 7.1.2 (Flutter) | Nivel (0–100) y `BatteryState` para el contrato; no sustituye a la señal nativa |
| **Persistencia local** | SQLite / Room Database | Cola persistente transaccional con estados `PENDING` y `ACK` |
| **Servicio continuo** | `ForegroundService` tipo `microphone` (`FOREGROUND_SERVICE_MICROPHONE` + `RECORD_AUDIO`) sobre `flutter_foreground_task` 11.0.3 | Escucha continua con la pantalla apagada. `dataSync` y `specialUse` están descartados: Android 15 limita `dataSync` a **6 h por cada 24** y después mata el servicio ([`investigacion-audio.md`](investigacion-audio.md)) |

---

## Fuentes citadas

* **Android Developers**:
  * *SmsManager API Reference:* [developer.android.com/reference/android/telephony/SmsManager](https://developer.android.com/reference/android/telephony/SmsManager)
  * *Foreground Services & Background Execution Restrictions:* [developer.android.com/about/versions/oreo/background](https://developer.android.com/about/versions/oreo/background)
  * *ConnectivityManager.NetworkCallback:* [developer.android.com/reference/android/net/ConnectivityManager.NetworkCallback](https://developer.android.com/reference/android/net/ConnectivityManager.NetworkCallback)
  * *Battery Monitoring Guide:* [developer.android.com/training/monitoring-device-state/battery-monitoring](https://developer.android.com/training/monitoring-device-state/battery-monitoring)
* **Investigación propia**:
  * *Señal de carga (`EXTRA_PLUGGED`, `battery_plus`, antirrebote y lectura al arrancar):* [`investigacion-carga.md`](investigacion-carga.md)
* **Android Open Source Project (AOSP)**:
  * *Low-RAM Configuration & lmkd Tuning:* [source.android.com/docs/core/perf/low-ram](https://source.android.com/docs/core/perf/low-ram)
* **Google Play Policy (Referencia de sideloading vs. Store)**:
  * *Permissions for SMS and Call Log:* [support.google.com/googleplay/android-developer/answer/10208820](https://support.google.com/googleplay/android-developer/answer/10208820)
