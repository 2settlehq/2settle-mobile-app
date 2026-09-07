package com.sirfitech.settleio

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.FileProvider
import java.io.File
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val shareChannel = "com.sirfitech.settleio/share"
    private val rateChannelId = "rate_updates"
    private val rateNotificationGroup = "com.sirfitech.settleio.RATE_UPDATES"
    private val rateNotificationSummaryId = 4472
    private val notificationPermissionRequest = 2401

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        createNotificationChannel()
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, shareChannel).setMethodCallHandler { call, result ->
            when (call.method) {
                "shareText" -> {
                    val text = call.argument<String>("text").orEmpty()
                    val subject = call.argument<String>("subject") ?: "2Settle"
                    val intent = Intent(Intent.ACTION_SEND).apply {
                        type = "text/plain"
                        putExtra(Intent.EXTRA_SUBJECT, subject)
                        putExtra(Intent.EXTRA_TEXT, text)
                    }
                    startActivity(Intent.createChooser(intent, subject))
                    result.success(true)
                }
                "shareFile" -> {
                    val path = call.argument<String>("path").orEmpty()
                    val subject = call.argument<String>("subject") ?: "2Settle"
                    val mimeType = call.argument<String>("mimeType") ?: "image/png"
                    val file = File(path)
                    if (!file.exists()) {
                        result.error("missing_file", "Share file does not exist", path)
                        return@setMethodCallHandler
                    }
                    val uri = FileProvider.getUriForFile(
                        this,
                        "${applicationContext.packageName}.fileprovider",
                        file
                    )
                    val intent = Intent(Intent.ACTION_SEND).apply {
                        type = mimeType
                        putExtra(Intent.EXTRA_SUBJECT, subject)
                        putExtra(Intent.EXTRA_STREAM, uri)
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    }
                    startActivity(Intent.createChooser(intent, subject))
                    result.success(true)
                }
                "showRateNotification" -> {
                    val title = call.argument<String>("title") ?: "2Settle rate update"
                    val body = call.argument<String>("body") ?: "Your exchange rate has been updated."
                    val shown = showRateNotification(title, body)
                    result.success(shown)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                rateChannelId,
                "Rate updates",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "2Settle exchange rate updates"
            }
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    private fun showRateNotification(title: String, body: String): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            ActivityCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                notificationPermissionRequest
            )
            return false
        }

        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
            ?: Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(this, rateChannelId)
            .setSmallIcon(applicationInfo.icon)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .setGroup(rateNotificationGroup)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .build()

        val summary = NotificationCompat.Builder(this, rateChannelId)
            .setSmallIcon(applicationInfo.icon)
            .setContentTitle("2Settle rate updates")
            .setContentText("New exchange-rate updates are available.")
            .setStyle(
                NotificationCompat.InboxStyle()
                    .setSummaryText("2Settle")
                    .addLine(body.lines().firstOrNull() ?: body)
            )
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .setGroup(rateNotificationGroup)
            .setGroupSummary(true)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .build()

        val notificationId = (System.currentTimeMillis() % Int.MAX_VALUE).toInt()
        NotificationManagerCompat.from(this).notify(notificationId, notification)
        NotificationManagerCompat.from(this).notify(rateNotificationSummaryId, summary)
        return true
    }
}
