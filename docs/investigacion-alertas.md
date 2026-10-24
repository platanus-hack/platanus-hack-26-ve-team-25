# Investigación: capa de alertas (entrega, escalamiento y fallos)

Cómo asegurar que la alerta llegue a la familia aunque se corte la luz, caiga el Wi-Fi, la red celular sea precaria y el teléfono sea un Android Go de menos de 70 USD sin servicios de Google. Al 24-oct-2026.

---

## 1. Transporte con señal deficiente y sin GMS

En un teléfono de menos de 100 USD (típicamente Android Go con 1–2 GB de RAM y chipsets Unisoc o MediaTek de entrada), **no se puede asumir la presencia de Google Mobile Services (GMS)**. Si el equipo es importado o sin certificar, carece de Firebase Cloud Messaging (FCM) y de bibliotecas propietarias de Google Play. La aplicación se distribuye vía sideload (APK directo), lo que libera al proyecto de las restricciones de la tienda de Google y permite interactuar directamente con la pila de telefonía celular nativa.

| Canal | Funciona sin datos | Requiere GMS | Permisos Android | Coste | Latencia | Fiabilidad | Caveat | Veredicto |
|---|:---:|:---:|---|---|---|:---:|---|---|
| **HTTP/REST (Webhook)** | No | **No** | `INTERNET`, `ACCESS_NETWORK_STATE` | Mínimo (datos/Wi-Fi) | 200–800 ms | **Alta** (si hay enlace IP) | Inoperante si cae el router durante un corte o no hay datos móviles | **Canal primario** (con red activa) |
| **SMS directo (`SmsManager`)** | **Sí** | **No** | `SEND_SMS`, `READ_PHONE_STATE` | Tarifa SMS local plana | 2–10 s | **Alta** (canal de señalización 2G) | Rate limiting del SO (~30 SMS/min); no pasa la tienda sin exención (no aplica en sideload) | **Canal crítico de contingencia** (offline) |
| **Heartbeat inverso (Dead Man's Switch)** | N/A (servidor infiere) | **No** | `INTERNET` (en pings) | Tráfico despreciable | Configurable (p.ej. 180 s) | **Muy alta** | Si el intervalo es muy corto satura la radio; depende del backend en la nube | **Obligatorio** para fallos catastróficos |
| **Llamada saliente (`ACTION_CALL`)** | **Sí** | **No** | `CALL_PHONE` | Tarifa de voz | 5–15 s | Media | Puede degradar/cortar datos en 2G/3G; requiere saldo de voz en la SIM | **Escalamiento** acústico final |
| **FCM High-Priority** | No | **Sí** | GMS Play Services | Gratuito | 1–5 s | Media (Doze en Go) | Inútil en AOSP puro sin certificar; requiere cuenta Google activa en el dispositivo | **Descartado** en el dispositivo emisor |
| **USSD (`sendUssdRequest`)** | **Sí** | **No** | `CALL_PHONE` | Bajo/Gratuito | 3–8 s | **Muy baja** | APIs inestables o bloqueadas en SoCs de bajo coste; sintaxis atada al operador | **Descartado** |
| **BLE a vecino** | **Sí** | **No** | `BLUETOOTH_ADVERTISE`, `ACCESS_FINE_LOCATION` | Gratuito | N/A | **Nula** | Requiere receptor preinstalado a <10 m; hardware RF de gama baja es errático | **Descartado** |

### Decisiones de diseño en transporte

1. **Dual-Stack Híbrido (HTTP + SMS local)**: El canal primario es HTTP por rapidez y densidad de telemetría. Si el socket no responde en 3 segundos o el sistema reporta desconexión de red, conmuta de inmediato a `SmsManager`. Al ser un APK sideloaded, se aprovecha el permiso directo `SEND_SMS` sin riesgo de rechazo por política de Google Play.
2. **Dual SIM resuelto por API de bajo nivel**: Para terminales con dos ranuras SIM, se consulta `SubscriptionManager.getActiveSubscriptionInfoList()` y se obtiene `SmsManager.getSmsManagerForSubscriptionId(subId)`. Si falla o no hay datos, se usa `SmsManager.getDefault()`.
3. **El Heartbeat Inverso no es un fallback del teléfono**: El teléfono no "salta" al heartbeat si todo falla; el heartbeat corre como monitor pasivo paralelo en el servidor. Si el hardware sufre un daño físico, se apaga o la celda celular colapsa, **el silencio es la alerta**.

---

## 2. Garantías de entrega y persistencia

En Android Go, el daemon de memoria del kernel (`lmkd`) liquida procesos sin previo aviso ante picos de uso de RAM. Ningún evento crítico puede residir únicamente en memoria volátil.

```text
[ Detección de Evento ]
         │
         ▼
[ Escritura en SQLite / Room ] ──► Estado: PENDING, attempts: 0, UUIDv4
         │
         ├──► ¿Socket IP disponible?
         │       ├── SÍ ──► POST /alerta (timeout 3 s) ──► 200 OK ──► Estado: ACK_SERVER
         │       └── NO / Timeout
         │               │
         ▼               ▼
[ Envío vía SmsManager (PDU codificado) ]
         │
         ├── BroadcastReceiver (SMS_SENT) ──► Confirmación de salida de antena
         └── BroadcastReceiver (SMS_DELIVERED) ──► Confirmación de la central (SMSC)
```

| Mecanismo | Implementación | Propósito |
|---|---|---|
| **Persistencia pre-envío** | SQLite plano o Room antes de tocar la radio de red | Si el SO mata el proceso durante la transmisión, el evento no se pierde |
| **Idempotencia (Deduplicación)** | Cada evento genera un `UUIDv4` inmutable en el teléfono | Si se disparan reintentos por HTTP y SMS a la vez, el backend procesa el primero y descarta duplicados |
| **Muerte del proceso y reinicio** | `RECEIVE_BOOT_COMPLETED` en el Manifest + `START_STICKY` en el `ForegroundService` | Al encender o reiniciar el teléfono tras agotamiento de batería, se barre la base local y se reintentan los `PENDING` |
| **Reintentos con Backoff** | $t_{\text{espera}} = \min(60\text{ s}, 2^{\text{intentos}} \times 2\text{ s})$ | Evita saturar el canal de señalización o agotar el saldo de la SIM ante caídas de la antena |

---

## 3. Detección de corte eléctrico y perfil energético

El teléfono permanece enchufado permanentemente. Distinguir si se cortó el suministro general o si se aflojó el cable de carga se resuelve correlacionando la carga con el router Wi-Fi, sin incurrir en escaneos activos de red (que Android limita a 1 vez cada 30 minutos en segundo plano).

| Condición | Evento de carga (`BatteryManager`) | Estado Wi-Fi local (`ConnectivityManager`) | Interpretación | Acción |
|---|---|---|---|---|
| **Apagón general confirmado** | `ACTION_POWER_DISCONNECTED` | `NetworkCallback.onLost` simultáneo | Se cortó la luz general (router y cargador sin corriente al unísono) | Disparo inmediato de evento **CORTE_LUZ_CONFIRMADO** |
| **Desconexión local / Falla de cargador** | `ACTION_POWER_DISCONNECTED` | Wi-Fi sigue conectado y con enlace | El router tiene energía; el cargador se soltó o falló | Se inicia timer de gracia de 60 s antes de emitir alerta leve |
| **Caída aislada de ISP** | `ACTION_POWER_CONNECTED` | `NetworkCapabilities.NET_CAPABILITY_VALIDATED` perdido | Hay luz pero falló el proveedor de internet | Conmutación silenciosa a SMS para emergencias |

### Medición de consumo y autonomía en chips económicos
En procesadores gama baja (Unisoc/MediaTek), `BATTERY_PROPERTY_CURRENT_NOW` devuelve con frecuencia `Integer.MIN_VALUE`. La estimación de autonomía se calcula midiendo el tiempo entre deltas reales de porcentaje:

1. **Monitoreo por deltas**: Mediante `ACTION_BATTERY_CHANGED`, se registra el tiempo $\Delta t$ que toma descender cada 1% de carga.
2. **Estimación**: $\text{Minutos restantes} = \text{Batería actual (\%)} \times \overline{\Delta t}$.
3. **Mensaje de despedida (Last Gasp)**: Si la batería desciende a $\le 5\%$, se congelan los algoritmos pesados de escucha y se despacha un SMS prioritario de última voluntad: `{"e":"LAST_GASP","bat":5,"t":1729738000}`.

---

## 4. Política y máquina de estados de escalamiento

El sistema minimiza falsos positivos en el recinto antes de escalar a la familia en el exterior o a los contactos locales.

```text
[ T0: Detección local (0 s) ]
       │
       ▼ (Alarma audible 520 Hz + vibración por 15 s)
¿Cancelado por usuario? ──SÍ──► [ ALERTA CANCELADA ]
       │ NO (Timeout: 15 s)
       ▼
[ T1: Canal Digital (15 s) ] ──► POST /alerta al backend (Push/Telegram/WhatsApp al familiar)
       │
       ▼ (Sin confirmación tras 30 s)
[ T2: Canal Celular (45 s) ] ──► SMS Directo desde el teléfono a números de emergencia
       │
       ▼ (Sin confirmación tras 60 s)
[ T3: Canal de Voz (105 s) ] ──► Llamada automatizada desde backend o ACTION_CALL local
       │
       ▼ (Sin contestar tras 120 s)
[ T4: Contacto Vecinal (225 s) ] ──► SMS/Llamada a vecino o contacto de apoyo local
```

### El Dead Man's Switch en el Servidor (Paralelo)

* El teléfono envía un ping ligero (`{"id":25,"bat":95,"pwr":1}`) cada **90 segundos**.
* Si el backend acumula **180 segundos continuos** (2 pings perdidos) sin contacto:
  * El servidor asume pérdida de enlace o fallo crítico del terminal.
  * Dispara alerta autónoma a los familiares: *"Pérdida total de conexión con el dispositivo en la casa desde hace 3 minutos"*.

---

## 5. Plan de demo (3 minutos, sin depender del Wi-Fi del venue)

El objetivo es demostrar que la alerta sale aun cuando se cortan la luz y los datos móviles al mismo tiempo.

* **Requisitos:** El teléfono Android de la prueba (con SIM y saldo SMS), el teléfono del evaluador o juez registrado como contacto, y un router Wi-Fi portátil conectado a la misma regleta que el cargador del teléfono.

| Tiempo | Qué se hace | Qué muestra la pantalla / Qué ocurre | Qué se demuestra |
|---|---|---|---|
| **0:00 – 0:30** | Estado nominal | Teléfono en pantalla fija: "Monitoreando: AC conectado, Wi-Fi OK". El teléfono del evaluador en reposo sobre la mesa | Sistema operativo en régimen normal |
| **0:30 – 1:15** | Desconexión física de la regleta | Se desenchufa la regleta completa: caen el cargador y el router portátil al mismo tiempo. En <2 s la pantalla cambia a: *"Corte de energía detectado (Wi-Fi + AC caídos)"* | Correlación inteligente de apagón sin escaneo pesado de Wi-Fi |
| **1:15 – 2:00** | Aislamiento de datos | Se desactivan los datos móviles en el Android Go. Queda en modo celular básico (icono de red 2G/llamadas) | Pérdida inducida del canal IP |
| **2:00 – 2:30** | Golpe o botón de pánico | Se pulsa el botón de pánico / impacto. Se activa la pre-alarma ruidosa de 15 s sin interactuar | Conteo de pre-alarma para mitigar falsos positivos |
| **2:30 – 3:00** | Salida por SMS y recepción | Expira el tiempo, falla el HTTP de inmediato y el teléfono despacha por `SmsManager`. Suena el teléfono del evaluador con el SMS de auxilio | **Entrega garantizada offline sin GMS ni internet** |

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
| **Telefonía y SMS** | `android.telephony.SmsManager` | Envío directo de PDU celular saltándose la pila IP |
| **Gestión Dual SIM** | `android.telephony.SubscriptionManager` | Selección de ranura celular activa y extracción de `subId` |
| **Red y conectividad** | `android.net.ConnectivityManager.NetworkCallback` | Detección de pérdida de Wi-Fi en tiempo real mediante `onLost()` |
| **Estado de carga** | `android.content.Intent.ACTION_POWER_DISCONNECTED` | Detección inmediata de pérdida de suministro eléctrico |
| **Persistencia local** | SQLite / Room Database | Cola persistente transaccional con estados `PENDING` y `ACK` |
| **Servicio continuo** | Android `ForegroundService` (`dataSync` / `specialUse`) | Ejecución continua inmune al cierre de interfaz de usuario |

---

## Fuentes citadas

* **Android Developers**:
  * *SmsManager API Reference:* [developer.android.com/reference/android/telephony/SmsManager](https://developer.android.com/reference/android/telephony/SmsManager)
  * *Foreground Services & Background Execution Restrictions:* [developer.android.com/about/versions/oreo/background](https://developer.android.com/about/versions/oreo/background)
  * *ConnectivityManager.NetworkCallback:* [developer.android.com/reference/android/net/ConnectivityManager.NetworkCallback](https://developer.android.com/reference/android/net/ConnectivityManager.NetworkCallback)
  * *Battery Monitoring Guide:* [developer.android.com/training/monitoring-device-state/battery-monitoring](https://developer.android.com/training/monitoring-device-state/battery-monitoring)
* **Android Open Source Project (AOSP)**:
  * *Low-RAM Configuration & lmkd Tuning:* [source.android.com/docs/core/perf/low-ram](https://source.android.com/docs/core/perf/low-ram)
* **Google Play Policy (Referencia de sideloading vs. Store)**:
  * *Permissions for SMS and Call Log:* [support.google.com/googleplay/android-developer/answer/10208820](https://support.google.com/googleplay/android-developer/answer/10208820)
