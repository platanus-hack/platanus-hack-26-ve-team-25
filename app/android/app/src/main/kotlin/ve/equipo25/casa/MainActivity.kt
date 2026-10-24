package ve.equipo25.casa

import android.Manifest
import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.media.AudioManager
import android.net.Uri
import android.os.BatteryManager
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.provider.ContactsContract
import android.telecom.TelecomManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var canal: MethodChannel? = null
    private val reloj = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        canal = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "casa/llamadas").apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "whatsapp" -> result.success(llamarPorWhatsApp(call.argument<String>("numero").orEmpty()))
                    "llamarEnAltavoz" -> result.success(llamarEnAltavoz(call.argument<String>("numero").orEmpty()))
                    else -> result.notImplemented()
                }
            }
        }
        Frases(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "casa/energia").setMethodCallHandler { call, result ->
            if (call.method == "leer") result.success(leerEnergia()) else result.notImplemented()
        }
    }

    /**
     * Una llamada telefónica normal, en altavoz y con el volumen de llamada al máximo: quien
     * llama puede estar en el suelo, lejos del teléfono. Es la de emergencias.
     *
     * El altavoz se pide con `EXTRA_START_CALL_WITH_SPEAKERPHONE`, pero quien decide es la app de
     * teléfono de cada marca. Por si lo ignora, se insiste cuando la llamada ya está en curso.
     * Devuelve false si falta el permiso de llamadas.
     */
    private fun llamarEnAltavoz(numero: String): Boolean {
        if (checkSelfPermission(Manifest.permission.CALL_PHONE) != PackageManager.PERMISSION_GRANTED) return false
        val audio = getSystemService(AUDIO_SERVICE) as AudioManager
        fun alMaximo() {
            val maximo = audio.getStreamMaxVolume(AudioManager.STREAM_VOICE_CALL)
            audio.setStreamVolume(AudioManager.STREAM_VOICE_CALL, maximo, 0)
        }
        alMaximo()
        startActivity(
            Intent(Intent.ACTION_CALL, Uri.fromParts("tel", numero, null))
                .putExtra(TelecomManager.EXTRA_START_CALL_WITH_SPEAKERPHONE, true)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
        )
        reloj.postDelayed({
            if (audio.mode == AudioManager.MODE_IN_CALL) {
                @Suppress("DEPRECATION")
                audio.isSpeakerphoneOn = true
                alMaximo()
            }
        }, 3000)
        return true
    }

    /**
     * Si hay fuente de alimentación y cuánta batería queda, para el latido. `EXTRA_PLUGGED` dice si
     * hay corriente; `isCharging()` no sirve, porque se apaga al 100 % o con el límite de carga
     * (docs/investigacion-carga.md). `ACTION_BATTERY_CHANGED` es sticky: devuelve el estado actual
     * sin registrar nada.
     */
    private fun leerEnergia(): Map<String, Any> {
        val bateria = registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        val enchufado = (bateria?.getIntExtra(BatteryManager.EXTRA_PLUGGED, 0) ?: 0) != 0
        val nivel = bateria?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
        val escala = bateria?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1
        val porcentaje = if (nivel >= 0 && escala > 0) nivel * 100 / escala else 100
        return mapOf("enchufado" to enchufado, "bateria" to porcentaje)
    }

    /**
     * Abre una llamada de voz de WhatsApp sin que nadie toque nada.
     *
     * WhatsApp no tiene una forma oficial de iniciar llamadas desde otra app. Lo que sí hace es
     * crear, para cada contacto de la agenda que tiene WhatsApp, una fila de «llamada de voz» en
     * los contactos de Android. Abrir esa fila inicia la llamada: es lo que usan las apps de
     * accesibilidad. Por eso el contacto tiene que estar guardado en la agenda del teléfono de la
     * casa. Devuelve false si no hay permiso, no hay WhatsApp o no se encuentra el contacto, y
     * entonces la app cae a la llamada telefónica normal.
     */
    private fun llamarPorWhatsApp(numero: String): Boolean {
        if (checkSelfPermission(Manifest.permission.READ_CONTACTS) != PackageManager.PERMISSION_GRANTED) return false
        val digitos = numero.filter { it.isDigit() }
        if (digitos.length < 7) return false
        // Se compara por los últimos 10 dígitos: así coincide con o sin código de país.
        val final = digitos.takeLast(10)

        val tipo = "vnd.android.cursor.item/vnd.com.whatsapp.voip.call"
        contentResolver.query(
            ContactsContract.Data.CONTENT_URI,
            arrayOf(ContactsContract.Data._ID, ContactsContract.Data.DATA1),
            "${ContactsContract.Data.MIMETYPE} = ?",
            arrayOf(tipo),
            null,
        )?.use { filas ->
            while (filas.moveToNext()) {
                val dato = filas.getString(1) ?: continue
                if (!dato.filter { it.isDigit() }.endsWith(final)) continue
                val intent = Intent(Intent.ACTION_VIEW).apply {
                    setDataAndType(Uri.parse("content://com.android.contacts/data/${filas.getLong(0)}"), tipo)
                    setPackage("com.whatsapp")
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                return try {
                    startActivity(intent)
                    vigilarLlamada()
                    true
                } catch (e: ActivityNotFoundException) {
                    false
                }
            }
        }
        return false
    }

    /**
     * Android no avisa a otra app si la llamada de WhatsApp fue contestada. Lo que sí se ve es el
     * modo de audio: mientras hay una llamada de voz por internet está en MODE_IN_COMMUNICATION.
     * Se mira cada medio segundo; cuando la llamada termina, la app vuelve al frente y le dice a
     * Dart cuántos segundos duró (timbre incluido). Si nunca empezó en 20 s, cuenta como 0.
     */
    private fun vigilarLlamada() {
        val audio = getSystemService(AUDIO_SERVICE) as AudioManager
        val pedida = SystemClock.elapsedRealtime()
        var empezo = 0L

        val tic = object : Runnable {
            override fun run() {
                val ahora = SystemClock.elapsedRealtime()
                val enLlamada = audio.mode == AudioManager.MODE_IN_COMMUNICATION
                when {
                    empezo == 0L && enLlamada -> empezo = ahora
                    empezo == 0L && ahora - pedida > 20_000 -> return terminar(0)
                    empezo != 0L && !enLlamada -> return terminar(((ahora - empezo) / 1000).toInt())
                }
                reloj.postDelayed(this, 500)
            }
        }
        reloj.postDelayed(tic, 500)
    }

    private fun terminar(segundos: Int) {
        // Volver al frente necesita el permiso «Mostrar sobre otras apps»: sin él, Android no deja
        // que una app en segundo plano se abra sola. Si no está, la persona vuelve con la tecla
        // de inicio, porque la app es la pantalla de inicio del teléfono de la casa.
        try {
            startActivity(
                Intent(this, MainActivity::class.java)
                    .addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or Intent.FLAG_ACTIVITY_NEW_TASK),
            )
        } catch (e: Exception) {
            // Si Android no deja volver, igual se avisa a Dart para que llame por teléfono.
        }
        canal?.invokeMethod("whatsappTermino", mapOf("segundos" to segundos))
    }
}
