package com.qiyanzhixing.quicksleep.audio

import android.app.PendingIntent
import android.content.Intent
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.os.Bundle
import androidx.media3.common.*
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.session.*
import com.google.common.util.concurrent.Futures
import com.google.common.util.concurrent.ListenableFuture
import com.qiyanzhixing.quicksleep.MainActivity
import com.qiyanzhixing.quicksleep.core.*
import kotlinx.coroutines.*
import java.io.File

@androidx.annotation.OptIn(UnstableApi::class)
class PlaybackService : MediaSessionService() {
    companion object {
        const val START = "quicksleep.start"
        const val PREVIEW = "quicksleep.preview"
        const val STOP = "quicksleep.stop"
        const val CLOSE_PREVIEW = "quicksleep.closePreview"
    }
    private lateinit var player: ExoPlayer
    private lateinit var session: MediaSession
    private lateinit var audioManager: AudioManager
    private lateinit var focus: AudioFocusRequest
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    private var generation = 0L
    private var preparation: Job? = null
    private var file: File? = null
    private var config: SessionConfig? = null
    private var preview = false
    private var previewMode: SoundMode? = null
    private var status = "idle"

    override fun onCreate() {
        super.onCreate()
        // A killed process never restores its old practice or resumes audio.
        cacheDir.listFiles { _, name -> name.startsWith("session-") }?.forEach { it.delete() }
        audioManager = getSystemService(AudioManager::class.java)
        focus = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
            .setAudioAttributes(android.media.AudioAttributes.Builder()
                .setUsage(android.media.AudioAttributes.USAGE_MEDIA)
                .setContentType(android.media.AudioAttributes.CONTENT_TYPE_SPEECH).build())
            .setWillPauseWhenDucked(true)
            .setOnAudioFocusChangeListener { change -> if (change < 0) player.pause() }
            .build()
        player = ExoPlayer.Builder(this).build().apply {
            setAudioAttributes(AudioAttributes.Builder().setUsage(C.USAGE_MEDIA).setContentType(C.AUDIO_CONTENT_TYPE_SPEECH).build(), false)
            setHandleAudioBecomingNoisy(true)
            setWakeMode(C.WAKE_MODE_LOCAL)
            repeatMode = Player.REPEAT_MODE_OFF
            shuffleModeEnabled = false
        }
        val controlled = object : ForwardingPlayer(player) {
            override fun play() { manualPlay() }
            override fun setPlayWhenReady(playWhenReady: Boolean) { if (playWhenReady) manualPlay() else player.pause() }
            override fun stop() { finish("idle") }
            override fun getAvailableCommands(): Player.Commands = super.getAvailableCommands().buildUpon().apply {
                remove(Player.COMMAND_SEEK_IN_CURRENT_MEDIA_ITEM)
                remove(Player.COMMAND_SEEK_BACK); remove(Player.COMMAND_SEEK_FORWARD)
                remove(Player.COMMAND_SEEK_TO_NEXT); remove(Player.COMMAND_SEEK_TO_NEXT_MEDIA_ITEM)
                remove(Player.COMMAND_SEEK_TO_PREVIOUS); remove(Player.COMMAND_SEEK_TO_PREVIOUS_MEDIA_ITEM)
                remove(Player.COMMAND_SEEK_TO_MEDIA_ITEM)
                remove(Player.COMMAND_SET_REPEAT_MODE); remove(Player.COMMAND_SET_SHUFFLE_MODE)
                remove(Player.COMMAND_CHANGE_MEDIA_ITEMS)
                remove(Player.COMMAND_SET_SPEED_AND_PITCH)
            }.build()
        }
        session = MediaSession.Builder(this, controlled)
            .setSessionActivity(PendingIntent.getActivity(this, 0, Intent(this, MainActivity::class.java), PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT))
            .setCallback(object : MediaSession.Callback {
                override fun onConnect(session: MediaSession, controller: MediaSession.ControllerInfo): MediaSession.ConnectionResult {
                    val own = controller.packageName == packageName
                    val commands = MediaSession.ConnectionResult.DEFAULT_SESSION_COMMANDS.buildUpon().apply {
                        add(SessionCommand(STOP, Bundle.EMPTY))
                        if (own) listOf(START, PREVIEW, CLOSE_PREVIEW).forEach { add(SessionCommand(it, Bundle.EMPTY)) }
                    }.build()
                    return MediaSession.ConnectionResult.AcceptedResultBuilder(session)
                        .setAvailableSessionCommands(commands).setAvailablePlayerCommands(controlled.availableCommands).build()
                }
                override fun onCustomCommand(session: MediaSession, controller: MediaSession.ControllerInfo, command: SessionCommand, args: Bundle): ListenableFuture<SessionResult> {
                    try {
                        when (command.customAction) {
                            START -> if (status !in listOf("loading", "active")) start(readConfig(args))
                            PREVIEW -> if (status !in listOf("loading", "active")) startPreview(readConfig(args))
                            STOP -> finish("idle")
                            CLOSE_PREVIEW -> if (preview) finish("idle")
                            else -> return Futures.immediateFuture(SessionResult(SessionError.ERROR_NOT_SUPPORTED))
                        }
                    } catch (_: Exception) { finish("error") }
                    return Futures.immediateFuture(SessionResult(SessionResult.RESULT_SUCCESS))
                }
            }).build()
        session.setCustomLayout(listOf(CommandButton.Builder(CommandButton.ICON_STOP)
            .setDisplayName("Stop").setSessionCommand(SessionCommand(STOP, Bundle.EMPTY)).build()))
        player.addListener(object : Player.Listener {
            override fun onPlaybackStateChanged(playbackState: Int) {
                if (playbackState == Player.STATE_ENDED) finish(if (preview) "idle" else "complete")
            }
            override fun onPlayerError(error: PlaybackException) { finish("error") }
        })
        publish("idle")
    }

    private fun readConfig(args: Bundle) = SessionConfig(args.getInt("minutes", 10),
        SoundMode.valueOf(args.getString("mode") ?: "moon"), AppLanguage.valueOf(args.getString("language") ?: "en"))

    private fun manualPlay() {
        if (player.mediaItemCount == 0 || status !in listOf("active", "preview")) return
        if (audioManager.requestAudioFocus(focus) == AudioManager.AUDIOFOCUS_REQUEST_GRANTED) player.play()
        else finish("error")
    }

    private fun publish(value: String) {
        status = value
        session.setSessionExtras(Bundle().apply {
            putString("status", value)
            putString("previewMode", previewMode?.name)
            config?.let { putInt("minutes", it.minutes); putString("mode", it.mode.name); putString("language", it.language.name) }
        })
    }

    private fun reset() {
        generation++
        preparation?.cancel(); preparation = null
        player.stop(); player.clearMediaItems()
        audioManager.abandonAudioFocusRequest(focus)
        file?.delete(); file = null
    }
    private fun finish(value: String) {
        reset()
        val wasPreview = preview
        preview = false
        previewMode = null
        if (value == "idle" || wasPreview) config = null
        publish(value)
    }

    private fun metadata(cfg: SessionConfig): MediaMetadata {
        val zh = cfg.language == AppLanguage.zh
        val names = if (zh) listOf("月下轻语", "山间静心", "林间晚风") else listOf("Moonlit Whispers", "Mountain Stillness", "Forest Evening Breeze")
        return MediaMetadata.Builder().setTitle(names[cfg.mode.ordinal])
            .setArtist(if (zh) "助眠练习" else "Sleep practice").build()
    }

    private fun start(cfg: SessionConfig) {
        val plan = SessionPlan(cfg)
        reset(); config = cfg; preview = false; previewMode = null; publish("loading")
        val request = generation
        preparation = scope.launch {
            val output = File(cacheDir, "session-$request.wav")
            try {
                withContext(Dispatchers.IO) {
                    val task = currentCoroutineContext()
                    WaveAssembler.write(plan, output, { assets.open(it) }, { !task.isActive })
                }
                if (generation != request) { output.delete(); return@launch }
                file = output
                player.setMediaItem(MediaItem.Builder().setUri(output.toURI().toString()).setMediaMetadata(metadata(cfg)).build())
                publish("active"); player.prepare(); manualPlay()
            } catch (_: CancellationException) { output.delete() }
            catch (_: Exception) { output.delete(); if (request == generation) finish("error") }
        }
    }

    private fun startPreview(cfg: SessionConfig) {
        reset(); config = null; preview = true; previewMode = cfg.mode
        player.setMediaItem(MediaItem.Builder().setUri("asset:///audio/${cfg.language.name}/${cfg.mode.name}_preview.wav")
            .setMediaMetadata(metadata(cfg)).build())
        publish("preview"); player.prepare(); manualPlay()
    }

    override fun onGetSession(controllerInfo: MediaSession.ControllerInfo): MediaSession = session
    override fun onTaskRemoved(rootIntent: Intent?) { if (status !in listOf("active", "loading")) { finish("idle"); stopSelf() } }
    override fun onDestroy() {
        reset(); scope.cancel(); session.release(); player.release(); super.onDestroy()
    }
}
