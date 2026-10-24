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
 * La alarma de «¿Está bien?»: un tono de 520 Hz en onda cuadrada y vibración, en bucle, y cada dos
 * ciclos una frase fija con la voz del teléfono («Carmen, ¿está bien?…»). Frases fijas y no una IA
 * que responda: en la alarma la voz tiene que ser predecible y funcionar sin internet
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

    /** Lo que dice en el próximo turno de voz. Dart lo cambia cerca del final. */
    private var frase = ""

    init {
        MethodChannel(mensajero, "casa/sirena").setMethodCallHandler { call, result ->
            when (call.method) {
                "sonar" -> { frase = call.argument<String>("frase").orEmpty(); sonar(); result.success(null) }
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
                override fun onDone(id: String?) { reloj.post { volverAlTono() } }
                @Deprecated("Deprecated in Java")
                override fun onError(id: String?) { reloj.post { volverAlTono() } }
            })
            vozLista = true
        }
    }

    // Dos ciclos del tono (8 s), la frase, y otra vez el tono.
    private val turnoDeVoz: Runnable = Runnable {
        val p = pista ?: return@Runnable
        val v = voz
        if (!vozLista || v == null || frase.isEmpty()) {
            programarVoz()
            return@Runnable
        }
        p.pause()
        v.speak(frase, TextToSpeech.QUEUE_FLUSH, null, "frase")
    }

    private fun programarVoz(): Boolean = reloj.postDelayed(turnoDeVoz, CICLOS_ENTRE_FRASES * 4000L)

    private fun volverAlTono() {
        val p = pista ?: return
        p.play()
        programarVoz()
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
                play()
            }
        programarVoz()

        // El mismo ritmo en la vibración: espera, pulso, pausa… y se repite desde el principio.
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
        reloj.removeCallbacks(turnoDeVoz)
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
    private fun cicloTemporal3(): ShortArray {
        val muestras = ShortArray(TASA * 4)
        val medio = TASA / 2
        val periodo = TASA.toDouble() / FRECUENCIA
        for (pulso in 0 until 3) {
            val inicio = pulso * TASA
            for (i in 0 until medio) {
                val arriba = (i % periodo) < periodo / 2
                muestras[inicio + i] = (if (arriba) AMPLITUD else -AMPLITUD).toShort()
            }
        }
        return muestras
    }

    private companion object {
        const val TASA = 22050
        const val FRECUENCIA = 520.0
        // No a tope: una cuadrada al máximo satura el parlante de un teléfono viejo y suena rota.
        const val AMPLITUD = 26000
        const val CICLOS_ENTRE_FRASES = 2
    }
}
