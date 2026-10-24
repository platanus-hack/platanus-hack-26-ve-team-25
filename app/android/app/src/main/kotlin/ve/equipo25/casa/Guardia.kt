package ve.equipo25.casa

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder

/**
 * Lo que mantiene viva la app: un servicio en primer plano de tipo micrófono, con su aviso fijo.
 *
 * El oído (Dart, con el paquete `record`) corre en el mismo proceso. Sin este servicio, al apagarse
 * la pantalla o pasar la app a segundo plano, Android deja de darle el micrófono y puede matar el
 * proceso para ahorrar batería. Con él, sigue oyendo.
 *
 * Android 14 y posteriores solo dejan arrancarlo con la app a la vista y el permiso de micrófono ya
 * dado: por eso lo arranca la app después de pedir permisos, no un aviso de arranque del teléfono
 * (docs/riesgos.md §3). No hace nada más que existir: todo el trabajo sigue en Dart.
 */
class Guardia : Service() {
    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val avisos = getSystemService(NotificationManager::class.java)
        avisos.createNotificationChannel(
            NotificationChannel(CANAL, "Cuidando la casa", NotificationManager.IMPORTANCE_LOW).apply {
                description = "Mientras se ve este aviso, el teléfono oye la casa"
                setShowBadge(false)
            },
        )
        val abrir = PendingIntent.getActivity(
            this, 0,
            Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
            PendingIntent.FLAG_IMMUTABLE,
        )
        val aviso = Notification.Builder(this, CANAL)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("Cuidando la casa")
            .setContentText("El audio se procesa en el teléfono y no sale de él")
            .setContentIntent(abrir)
            .setOngoing(true)
            .build()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(ID, aviso, ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE)
        } else {
            startForeground(ID, aviso)
        }
        // Si Android lo mata igual, que lo vuelva a crear.
        return START_STICKY
    }

    private companion object {
        const val CANAL = "cuidando"
        const val ID = 1
    }
}
