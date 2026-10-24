package ve.equipo25.casa

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.vosk.LibVosk
import org.vosk.LogLevel
import org.vosk.Model
import org.vosk.Recognizer
import org.vosk.android.StorageService
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Reconoce las frases de ayuda con Vosk, sin internet, sobre el audio que ya oyó la casa.
 *
 * No abre el micrófono: Dart le pasa los últimos segundos del anillo del oído en PCM de 16 bits a
 * 16 kHz. Así YAMNet nunca se queda sordo mientras se reconoce, y la frase que despertó al
 * reconocedor también se entiende.
 *
 * El reconocedor solo puede contestar con las palabras del banco (una gramática cerrada) o con
 * «[unk]». Con un vocabulario tan corto se equivoca menos con una voz débil; a cambio, puede
 * forzar una frase del banco sobre algo que no lo era, y por eso Dart filtra por confianza y lo
 * que pide pasa por «¿Está bien?».
 */
class Frases(private val contexto: Context, mensajero: BinaryMessenger) {
    private val hilo = Executors.newSingleThreadExecutor()
    private val principal = Handler(Looper.getMainLooper())
    private var modelo: Model? = null
    private var gramatica = "[]"

    init {
        MethodChannel(mensajero, "casa/frases").setMethodCallHandler { call, result ->
            when (call.method) {
                "iniciar" -> iniciar(call.argument<List<String>>("frases").orEmpty(), result)
                "reconocer" -> reconocer(call.argument<ByteArray>("pcm") ?: ByteArray(0), result)
                else -> result.notImplemented()
            }
        }
    }

    // El modelo viene en los assets de Android (tool/descargar_vosk.sh) y se copia una vez a la
    // memoria del teléfono, porque Vosk lo lee de archivos.
    private fun iniciar(frases: List<String>, result: MethodChannel.Result) {
        gramatica = JSONArray(frases).toString()
        if (modelo != null) return result.success(true)
        LibVosk.setLogLevel(LogLevel.WARNINGS)
        StorageService.unpack(
            contexto, "vosk-es", "vosk-es",
            { m -> modelo = m; result.success(true) },
            { e -> result.error("modelo", e.message, null) },
        )
    }

    // Devuelve el JSON de Vosk tal cual, con la confianza de cada palabra: Dart decide.
    // Si todavía está reconociendo lo anterior, lo nuevo se descarta en vez de hacer cola: en un
    // teléfono viejo, con la TV hablando, la cola crecería sin fin y la app se iría trabando.
    private fun reconocer(pcm: ByteArray, result: MethodChannel.Result) {
        val m = modelo ?: return result.success(null)
        if (!ocupado.compareAndSet(false, true)) {
            Log.d(ETIQUETA, "ocupado: se descarta un audio de ${pcm.size / 32} ms")
            return result.success(null)
        }
        hilo.execute {
            val inicio = SystemClock.elapsedRealtime()
            val json = try {
                Recognizer(m, 16000f, gramatica).use { r ->
                    r.setWords(true)
                    r.acceptWaveForm(pcm, pcm.size)
                    r.finalResult
                }
            } catch (e: Exception) {
                Log.w(ETIQUETA, "falló el reconocimiento", e)
                null
            } finally {
                ocupado.set(false)
            }
            // Cuánto tarda en el teléfono: si se acerca a los segundos de audio, no da abasto.
            Log.d(ETIQUETA, "${pcm.size / 32} ms de audio en ${SystemClock.elapsedRealtime() - inicio} ms: $json")
            principal.post { result.success(json) }
        }
    }

    private val ocupado = AtomicBoolean(false)

    private companion object {
        const val ETIQUETA = "casa.vosk"
    }
}
