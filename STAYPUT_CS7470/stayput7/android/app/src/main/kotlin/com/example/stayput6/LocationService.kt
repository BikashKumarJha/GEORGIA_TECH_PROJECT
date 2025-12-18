package com.example.stayput7   // <-- change to your app package

import android.app.*
import android.content.Context
import android.content.Intent
import android.location.Location
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import com.google.android.gms.location.*
import org.json.JSONObject
import java.io.OutputStreamWriter
import java.text.SimpleDateFormat
import java.util.*

class LocationService : Service() {

    companion object {
        private const val TAG = "LocationService"
        private const val CHANNEL_ID = "stayput_foreground_channel"
        private const val CHANNEL_NAME = "StayPut Tracking"
        private const val NOTIF_ID = 1001
        const val ACTION_START = "com.example.stayput7.action.START"
        const val ACTION_STOP = "com.example.stayput7.action.STOP"
        const val ACTION_LOCATION_BROADCAST = "com.example.stayput7.LOCATION_UPDATE"

        // Use these helper functions from other Kotlin code (or from MainActivity) to start/stop
        fun startService(context: Context) {
            val intent = Intent(context, LocationService::class.java).apply { action = ACTION_START }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stopService(context: Context) {
            val intent = Intent(context, LocationService::class.java).apply { action = ACTION_STOP }
            context.startService(intent)
        }
    }

    private lateinit var fusedClient: FusedLocationProviderClient
    private lateinit var locationRequest: LocationRequest
    private var locationCallback: LocationCallback? = null
    private val logFileName = "stayput_locations.log"
    private val dateFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSZ", Locale.US)

    override fun onCreate() {
        super.onCreate()
        fusedClient = LocationServices.getFusedLocationProviderClient(this)

        // Balanced power accuracy and 5 minute interval
        locationRequest = LocationRequest.Builder(Priority.PRIORITY_BALANCED_POWER_ACCURACY, 5 * 60 * 1000L)
            .setMinUpdateIntervalMillis(2 * 60 * 1000L) // allow faster updates occasionally (2 min)
            .setMaxUpdateDelayMillis(0) // use 0 to not batch beyond the interval (you can tune)
            .build()

        createNotificationChannel()
        Log.d(TAG, "Service created")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action
        if (action == ACTION_START) {
            startForeground(NOTIF_ID, buildNotification("Initializing StayPut tracking..."))
            startLocationUpdates()
            Log.d(TAG, "Received ACTION_START")
            return START_STICKY
        } else if (action == ACTION_STOP) {
            stopLocationUpdates()
            stopForeground(true)
            stopSelf()
            Log.d(TAG, "Received ACTION_STOP")
            return START_NOT_STICKY
        } else {
            // If started without explicit action, ensure service runs
            startForeground(NOTIF_ID, buildNotification("StayPut tracking active"))
            startLocationUpdates()
            return START_STICKY
        }
    }

    private fun startLocationUpdates() {
        if (locationCallback != null) return // already running

        locationCallback = object : LocationCallback() {
            override fun onLocationResult(result: LocationResult) {
                super.onLocationResult(result)
                val loc: Location? = result.lastLocation
                loc?.let { handleNewLocation(it) }
            }
        }

        try {
            fusedClient.requestLocationUpdates(locationRequest, locationCallback as LocationCallback, mainLooper)
            Log.d(TAG, "Requested location updates")
        } catch (sec: SecurityException) {
            // Shouldn't happen if callers ensure permissions. Log for debugging.
            Log.e(TAG, "Missing location permission: ${sec.message}")
        }
    }

    private fun stopLocationUpdates() {
        locationCallback?.let {
            fusedClient.removeLocationUpdates(it)
        }
        locationCallback = null
        Log.d(TAG, "Stopped location updates")
    }

    private fun handleNewLocation(location: Location) {
        val timestamp = dateFormat.format(Date(location.time))
        val lat = location.latitude
        val lon = location.longitude
        val accuracy = location.accuracy
        val speed = if (location.hasSpeed()) location.speed else -1f

        // 1) Broadcast to Flutter if it's listening (or to any receiver)
        val b = Intent(ACTION_LOCATION_BROADCAST).apply {
            putExtra("timestamp", timestamp)
            putExtra("latitude", lat)
            putExtra("longitude", lon)
            putExtra("accuracy", accuracy)
            putExtra("speed", speed)
        }
        sendBroadcast(b)

        // 2) Append JSON line to file (persistent log)
        val json = JSONObject().apply {
            put("timestamp", timestamp)
            put("latitude", lat)
            put("longitude", lon)
            put("accuracy", accuracy)
            put("speed", speed)
            put("provider", location.provider ?: JSONObject.NULL)
        }
        appendToLogFile(json.toString())

        // 3) Update the ongoing notification (brief content change)
        val contentText = String.format(Locale.US, "Tracking: %.5f, %.5f (acc %.1fm)", lat, lon, accuracy)
        val notif = buildNotification(contentText)
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.notify(NOTIF_ID, notif)

        Log.d(TAG, "New location: $json")
    }

    private fun appendToLogFile(line: String) {
        try {
            // openFileOutput writes to /data/data/<package>/files/
            val fos = openFileOutput(logFileName, Context.MODE_APPEND)
            val writer = OutputStreamWriter(fos, Charsets.UTF_8)
            writer.append(line)
            writer.append("\n")
            writer.flush()
            writer.close()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to append location to file: ${e.message}")
        }
    }

    private fun buildNotification(contentText: String): Notification {
        val notificationIntent = packageManager.getLaunchIntentForPackage(packageName)
        val pendingIntent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PendingIntent.getActivity(this, 0, notificationIntent, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
        } else {
            PendingIntent.getActivity(this, 0, notificationIntent, PendingIntent.FLAG_UPDATE_CURRENT)
        }

        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("StayPut — tracking active")
            .setContentText(contentText)
            .setSmallIcon(getSmallIcon())
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setOnlyAlertOnce(true)

        // Provide a Stop action to stop the service from the notification
        val stopIntent = Intent(this, LocationService::class.java).apply { action = ACTION_STOP }
        val stopPending = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PendingIntent.getService(this, 0, stopIntent, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
        } else {
            PendingIntent.getService(this, 0, stopIntent, PendingIntent.FLAG_UPDATE_CURRENT)
        }
        builder.addAction(android.R.drawable.ic_menu_close_clear_cancel, "Stop", stopPending)
        return builder.build()
    }

    private fun getSmallIcon(): Int {
        // return a valid small icon resource (fallback to app icon)
        // Put a proper white-on-transparent notification icon in res/mipmap or res/drawable (recommended).
        return try {
            R.mipmap.ic_launcher // replace with your notification icon if you have one
        } catch (e: Exception) {
            android.R.drawable.ic_menu_mylocation
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val chan = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_LOW // low importance for ongoing tracking
            ).apply {
                description = "StayPut location tracking"
                setShowBadge(false)
            }
            val nm = getSystemService(NotificationManager::class.java)
            nm.createNotificationChannel(chan)
        }
    }

    override fun onBind(intent: Intent?): IBinder? {
        // not binding
        return null
    }

    override fun onDestroy() {
        stopLocationUpdates()
        super.onDestroy()
    }
}
