package ve.equipo25.casa

import android.Manifest
import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.ContactsContract
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "casa/llamadas").setMethodCallHandler { call, result ->
            when (call.method) {
                "whatsapp" -> result.success(llamarPorWhatsApp(call.argument<String>("numero").orEmpty()))
                else -> result.notImplemented()
            }
        }
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
                    true
                } catch (e: ActivityNotFoundException) {
                    false
                }
            }
        }
        return false
    }
}
