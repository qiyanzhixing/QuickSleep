package com.qiyanzhixing.quicksleep

import android.content.ComponentName
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.runtime.*
import androidx.core.content.ContextCompat
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.lifecycleScope
import androidx.lifecycle.repeatOnLifecycle
import androidx.media3.session.*
import com.google.common.util.concurrent.ListenableFuture
import com.qiyanzhixing.quicksleep.audio.PlaybackService
import com.qiyanzhixing.quicksleep.core.*
import com.qiyanzhixing.quicksleep.ui.*
import kotlinx.coroutines.*

data class PlaybackUi(val status: String = "connecting", val config: SessionConfig? = null, val elapsed: Double = 0.0, val playing: Boolean = false, val previewMode: SoundMode? = null)

class MainActivity : ComponentActivity() {
    private var controller: MediaController? = null
    private var connection: ListenableFuture<MediaController>? = null
    private var playback by mutableStateOf(PlaybackUi())
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        connect()
        setContent { QuickSleepScreen(playback, ::command, ::connect) }
        lifecycleScope.launch {
            repeatOnLifecycle(Lifecycle.State.STARTED) {
                while (isActive) {
                    controller?.let { c ->
                        val extras = c.sessionExtras
                        val cfg = extras.getString("mode")?.let { mode ->
                            runCatching { SessionConfig(extras.getInt("minutes", 10), SoundMode.valueOf(mode), AppLanguage.valueOf(extras.getString("language") ?: "en")) }.getOrNull()
                        }
                        val previewMode = SoundMode.entries.find { it.name == extras.getString("previewMode") }
                        playback = PlaybackUi(extras.getString("status") ?: "idle", cfg, c.currentPosition.coerceAtLeast(0) / 1000.0, c.playWhenReady, previewMode)
                    }
                    delay(100)
                }
            }
        }
    }
    private fun connect() {
        connection?.let { MediaController.releaseFuture(it) }
        controller = null
        playback = PlaybackUi()
        val future = MediaController.Builder(this, SessionToken(this, ComponentName(this, PlaybackService::class.java))).buildAsync()
        connection = future
        future.addListener({
            if (connection === future && !isDestroyed) {
                try { controller = future.get(); playback = PlaybackUi("idle") }
                catch (_: Exception) { playback = PlaybackUi("connectionError") }
            }
        }, ContextCompat.getMainExecutor(this))
    }
    private fun command(action: String, config: SessionConfig?) {
        val c = controller ?: return
        when (action) {
            "play" -> c.play()
            "pause" -> c.pause()
            else -> {
                val args = Bundle().apply { config?.let { putInt("minutes", it.minutes); putString("mode", it.mode.name); putString("language", it.language.name) } }
                c.sendCustomCommand(SessionCommand(action, Bundle.EMPTY), args)
            }
        }
    }
    override fun onDestroy() {
        connection?.let { MediaController.releaseFuture(it) }; connection = null; controller = null
        super.onDestroy()
    }
}
