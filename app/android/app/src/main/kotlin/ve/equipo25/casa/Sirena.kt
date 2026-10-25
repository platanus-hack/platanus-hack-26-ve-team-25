package ve.equipo25.casa

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioTrack
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.VibrationAttributes
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

/**
 * La alarma de «¿Está bien?»: primero la voz del teléfono, de una vez y sin tono («Carmen, ¿está
 * bien?»), que se calla 4 s para oír la respuesta y vuelve a preguntar; en los últimos segundos,
 * un tono de 520 Hz en onda cuadrada y vibración, en bucle (lo pide Dart con tono()). Frases
 * fijas y no una IA que responda: en la alarma la voz tiene que ser predecible y funcionar sin internet
 * (docs/por-planificar.md, punto 9). La voz es grave y lenta, como pide la investigación de audio.
 *
 * 520 Hz y no un pitido agudo porque con la edad se oyen peor los agudos: en las pruebas de la
 * NFPA, ese tono despertó al 92% de las personas con pérdida auditiva, contra el 56% del de
 * 3.100 Hz (docs/investigacion-audio.md). Suena con el patrón temporal-3 de las alarmas de humo:
 * tres pulsos de 0,5 s y una pausa de 1,5 s, y la vibración sigue el mismo ritmo.
 *
 * Va por el canal de alarma, que suena aunque el teléfono esté en silencio o en vibración, con el
 * volumen de alarma al máximo mientras dura; al callar, se devuelve el que tenía.
 */
class Sirena(private val contexto: Context, mensajero: BinaryMessenger) {
    private val audio = contexto.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    private var pista: AudioTrack? = null
    private var volumenAntes: Int? = null
    private val reloj = Handler(Looper.getMainLooper())
    private var voz: TextToSpeech? = null
    private var vozLista = false

    /** Lo primero que dice, apenas nace la alerta: corto, «Carmen, ¿está bien?». */
    private var primera: String? = null

    /** Lo que dice en los turnos siguientes. Dart lo cambia cerca del final. */
    private var frase = ""

    /** True desde que Dart pide el tono, en los últimos segundos: ya no habla, suena y vibra. */
    private var conTono = false

    /** True mientras la sirena calla para oír la respuesta. */
    private var ventanaAbierta = false

    private val canal = MethodChannel(mensajero, "casa/sirena")

    init {
        canal.setMethodCallHandler { call, result ->
            when (call.method) {
                "sonar" -> {
                    frase = call.argument<String>("frase").orEmpty()
                    primera = call.argument<String>("primera")
                    sonar()
                    result.success(null)
                }
                "tono" -> { tono(); result.success(null) }
                "decir" -> { frase = call.argument<String>("frase").orEmpty(); result.success(null) }
                "callar" -> { callar(); result.success(null) }
                else -> result.notImplemented()
            }
        }
        voz = TextToSpeech(contexto) { estado ->
            val v = voz ?: return@TextToSpeech
            if (estado != TextToSpeech.SUCCESS) return@TextToSpeech
            // El español del teléfono, prefiriendo el latinoamericano.
            val idioma = listOf(Locale("es", "VE"), Locale("es", "US"), Locale("es", "MX"), Locale("es", "ES"), Locale("es"))
                .firstOrNull { v.isLanguageAvailable(it) >= TextToSpeech.LANG_AVAILABLE }
                ?: return@TextToSpeech
            v.language = idioma
            v.setPitch(0.8f)
            v.setSpeechRate(0.85f)
            v.setAudioAttributes(atributos())
            v.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
                override fun onStart(id: String?) {}
                override fun onDone(id: String?) { reloj.post { calloLaVoz(); abrirVentana() } }
                @Deprecated("Deprecated in Java")
                override fun onError(id: String?) { reloj.post { calloLaVoz(); abrirVentana() } }
                override fun onStop(id: String?, interrumpida: Boolean) { reloj.post { calloLaVoz() } }
            })
            vozLista = true
        }
    }

    // Primero la voz, sin tono: Lucero pregunta apenas nace la alerta, se calla 4 s para oír la
    // respuesta y vuelve a preguntar. El tono y la vibración entran solo al final (tono()).
    private val turnoDeVoz: Runnable = Runnable {
        if (pista == null || conTono) return@Runnable
        val v = voz
        val texto = primera ?: frase
        if (!vozLista || v == null || texto.isEmpty()) {
            programarVoz(REINTENTO_VOZ_MS)
            return@Runnable
        }
        primera = null
        // Dart deja de pasarle audio a Vosk mientras el teléfono habla: la frase dice «Lucero,
        // estoy bien», y si Vosk la oyera, la alarma se callaría sola.
        canal.invokeMethod("hablando", true)
        v.speak(texto, TextToSpeech.QUEUE_FLUSH, null, "frase")
    }

    private fun calloLaVoz() {
        canal.invokeMethod("hablando", false)
    }

    // Después de la frase, silencio: sin tono ni vibración, para que «Lucero, estoy bien» se oiga
    // limpio. Dart muestra «Le escucho…» y, al cerrarse, reconoce lo que se dijo en ese rato.
    private fun abrirVentana() {
        if (pista == null || conTono) return
        ventanaAbierta = true
        canal.invokeMethod("ventana", true)
        reloj.postDelayed(cerrarVentana, VENTANA_MS)
    }

    private val cerrarVentana: Runnable = Runnable {
        ventanaAbierta = false
        canal.invokeMethod("ventana", false)
        if (!conTono) programarVoz(PAUSA_ENTRE_FRASES_MS)
    }

    private fun programarVoz(ms: Long): Boolean = reloj.postDelayed(turnoDeVoz, ms)

    // Los últimos segundos antes de llamar: se corta la voz y suenan el tono de 520 Hz y la
    // vibración, para quien no oyó la pregunta.
    private fun tono() {
        val p = pista ?: return
        if (conTono) return
        conTono = true
        reloj.removeCallbacks(turnoDeVoz)
        if (ventanaAbierta) {
            ventanaAbierta = false
            reloj.removeCallbacks(cerrarVentana)
            canal.invokeMethod("ventana", false)
        }
        voz?.stop()
        p.play()
        vibrar()
    }

    private fun sonar() {
        if (pista != null) return
        volumenAntes = audio.getStreamVolume(AudioManager.STREAM_ALARM)
        audio.setStreamVolume(AudioManager.STREAM_ALARM, audio.getStreamMaxVolume(AudioManager.STREAM_ALARM), 0)

        val muestras = cicloTemporal3()
        pista = AudioTrack.Builder()
            .setAudioAttributes(atributos())
            .setAudioFormat(
                AudioFormat.Builder()
                    .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                    .setSampleRate(TASA)
                    .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                    .build(),
            )
            .setTransferMode(AudioTrack.MODE_STATIC)
            .setBufferSizeInBytes(muestras.size * 2)
            .build()
            .apply {
                write(muestras, 0, muestras.size)
                setLoopPoints(0, muestras.size, -1)
            }
        conTono = false
        // La voz pregunta de una vez; el tono espera a tono().
        reloj.post(turnoDeVoz)
    }

    // El mismo ritmo en la vibración: espera, pulso, pausa… y se repite desde el principio.
    private fun vibrar() {
        val patron = longArrayOf(0, 500, 500, 500, 500, 500, 1500)
        val efecto = VibrationEffect.createWaveform(patron, 0)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            vibrador().vibrate(efecto, VibrationAttributes.createForUsage(VibrationAttributes.USAGE_ALARM))
        } else {
            @Suppress("DEPRECATION")
            vibrador().vibrate(efecto, atributos())
        }
    }

    private fun callar() {
        conTono = false
        ventanaAbierta = false
        primera = null
        reloj.removeCallbacks(turnoDeVoz)
        reloj.removeCallbacks(cerrarVentana)
        voz?.stop()
        pista?.run {
            stop()
            release()
        }
        pista = null
        vibrador().cancel()
        volumenAntes?.let { audio.setStreamVolume(AudioManager.STREAM_ALARM, it, 0) }
        volumenAntes = null
    }

    private fun atributos() = AudioAttributes.Builder()
        .setUsage(AudioAttributes.USAGE_ALARM)
        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
        .build()

    private fun vibrador(): Vibrator =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            (contexto.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager).defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            contexto.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }

    // Un ciclo de 4 s: tono 0,5 s, silencio 0,5 s, tono, silencio, tono, silencio 1,5 s.
    //
    // La onda cuadrada se arma sumando sus armónicos impares (520, 1.560, 2.600 Hz…) y no
    // saltando de +1 a -1 muestra a muestra: así no aparecen frecuencias fantasma (aliasing), y toda
    // la sirena cae en múltiplos exactos de 520 Hz, que es donde el filtro de Dart la corta para que
    // Vosk entienda lo que se dice encima (lib/oido/filtro.dart).
    private fun cicloTemporal3(): ShortArray {
        val medio = TASA / 2
        val pulso = DoubleArray(medio)
        var k = 1
        while (k * FRECUENCIA < TASA / 2.0 - 1000) {
            val w = 2 * Math.PI * k * FRECUENCIA / TASA
            for (i in 0 until medio) pulso[i] += Math.sin(w * i) / k
            k += 2
        }
        val pico = pulso.maxOf { Math.abs(it) }
        val muestras = ShortArray(TASA * 4)
        for (n in 0 until 3) {
            for (i in 0 until medio) muestras[n * TASA + i] = (pulso[i] / pico * AMPLITUD).toInt().toShort()
        }
        return muestras
    }

    private companion object {
        const val TASA = 22050
        const val FRECUENCIA = 520.0
        // No a tope: una cuadrada al máximo satura el parlante de un teléfono viejo y suena rota.
        const val AMPLITUD = 26000
        const val VENTANA_MS = 4000L
        // Entre el fin de la ventana y la próxima pregunta.
        const val PAUSA_ENTRE_FRASES_MS = 1500L
        // Si la voz del teléfono todavía no está lista, cuánto esperar para intentar de nuevo.
        const val REINTENTO_VOZ_MS = 500L
    }
}
