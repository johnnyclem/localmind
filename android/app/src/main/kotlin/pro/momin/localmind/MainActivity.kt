package pro.momin.localmind

import androidx.annotation.NonNull
import android.app.ActivityManager
import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "localmind/chat_background"
    private val MEMORY_CHANNEL = "localmind/device_memory"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startForeground" -> {
                    ChatForegroundService.startService(this)
                    result.success(null)
                }
                "stopForeground" -> {
                    ChatForegroundService.stopService(this)
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MEMORY_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getMemoryInfo" -> {
                    val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
                    val memoryInfo = ActivityManager.MemoryInfo()
                    activityManager.getMemoryInfo(memoryInfo)
                    result.success(
                        mapOf(
                            "totalMemoryMb" to (memoryInfo.totalMem / (1024 * 1024)),
                            "availableMemoryMb" to (memoryInfo.availMem / (1024 * 1024))
                        )
                    )
                }
                else -> result.notImplemented()
            }
        }
    }
}
