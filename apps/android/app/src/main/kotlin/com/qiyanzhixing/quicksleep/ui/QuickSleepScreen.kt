package com.qiyanzhixing.quicksleep.ui

import android.content.res.Configuration
import android.app.Activity
import android.os.Build
import androidx.core.view.WindowCompat
import android.provider.Settings as SystemSettings
import androidx.activity.compose.BackHandler
import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.qiyanzhixing.quicksleep.PlaybackUi
import com.qiyanzhixing.quicksleep.R
import com.qiyanzhixing.quicksleep.audio.PlaybackService
import com.qiyanzhixing.quicksleep.core.*
import kotlinx.coroutines.launch
import java.util.Locale
import kotlin.math.ceil

private data class Palette(val background: Color, val surface: Color, val accent: Color, val text: Color, val secondary: Color, val ink: Color)
private val night = Palette(Color(0xFF080D1B), Color(0xFF131A2C), Color(0xFFB6A2EF), Color(0xFFE9E5FB), Color(0xFFBBB5D7), Color(0xFF19132B))
private val light = Palette(Color(0xFFF7F4F0), Color(0xFFEDE7EF), Color(0xFF78618F), Color(0xFF332C3F), Color(0xFF60536F), Color(0xFFFCF8FF))
private val sans = FontFamily(Font(R.font.notosanssc))
private val serif = FontFamily(Font(R.font.notoserifsc))

@OptIn(ExperimentalMaterial3Api::class, ExperimentalLayoutApi::class)
@Composable
fun QuickSleepScreen(playback: PlaybackUi, command: (String, SessionConfig?) -> Unit, retry: () -> Unit) {
    val base = LocalContext.current
    val store = remember { SettingsStore(base.applicationContext) }
    var settings by remember { mutableStateOf(store.load()) }
    var sheet by remember { mutableStateOf<String?>(null) }
    var custom by remember { mutableStateOf("") }
    var customError by remember { mutableStateOf(false) }
    var saveError by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()
    val configuration = LocalConfiguration.current
    val systemLanguage = configuration.locales[0].language
    val language = if (settings.language == "system") { if (systemLanguage == "zh") "zh" else "en" } else settings.language
    val context = remember(base, language, configuration) { base.createConfigurationContext(Configuration(configuration).apply { setLocale(Locale(language)) }) }
    fun text(key: String, parameter: String? = null): String {
        val id = context.resources.getIdentifier(key, "string", base.packageName)
        val value = if (id != 0) context.getString(id) else key
        return if (parameter == null) value else value.replace("{count}", parameter).replace("{time}", parameter)
    }
    fun save(next: Settings) {
        settings = next
        scope.launch { try { store.save(next); saveError = false } catch (_: Exception) { saveError = true } }
    }
    fun cfg(mode: SoundMode = settings.mode) = SessionConfig(settings.minutes, mode, AppLanguage.valueOf(language))
    fun modeKey(mode: SoundMode) = "mode" + mode.name.replaceFirstChar { it.uppercase() }
    fun descriptionKey(mode: SoundMode) = "desc" + mode.name.replaceFirstChar { it.uppercase() }
    fun dismissSheet() { if (sheet == "sounds") command(PlaybackService.CLOSE_PREVIEW, null); sheet = null }
    val dark = when (settings.theme) { "night" -> true; "light" -> false; else -> isSystemInDarkTheme() }
    SideEffect {
        (base as? Activity)?.window?.let { window ->
            val bars = WindowCompat.getInsetsController(window, window.decorView)
            bars.isAppearanceLightStatusBars = !dark
            bars.isAppearanceLightNavigationBars = !dark
            if (Build.VERSION.SDK_INT >= 29) window.isNavigationBarContrastEnforced = false
        }
    }
    val colors = if (dark) night else light
    val scheme = (if (dark) darkColorScheme() else lightColorScheme()).copy(
        primary = colors.accent, onPrimary = colors.ink, background = colors.background, onBackground = colors.text,
        surface = colors.surface, onSurface = colors.text, onSurfaceVariant = colors.secondary)
    val inSession = playback.config != null && playback.status in listOf("loading", "active", "complete", "error")
    BackHandler(sheet != null) { dismissSheet() }
    BackHandler(inSession && sheet == null) { command(PlaybackService.STOP, null) }
    MaterialTheme(colorScheme = scheme, typography = Typography(
        bodyLarge = TextStyle(fontFamily = sans, fontSize = 17.sp, lineHeight = 26.sp),
        bodyMedium = TextStyle(fontFamily = sans, fontSize = 13.sp, lineHeight = 21.sp),
        bodySmall = TextStyle(fontFamily = sans, fontSize = 12.sp, lineHeight = 18.sp),
        labelLarge = TextStyle(fontFamily = sans, fontSize = 16.sp, lineHeight = 24.sp),
        titleMedium = TextStyle(fontFamily = serif, fontSize = 18.sp, lineHeight = 28.sp),
        titleLarge = TextStyle(fontFamily = serif, fontSize = 24.sp, lineHeight = 34.sp),
        headlineLarge = TextStyle(fontFamily = serif, fontSize = 32.sp, lineHeight = 44.sp))) {
        ProvideTextStyle(MaterialTheme.typography.bodyMedium) {
        Surface(modifier = Modifier.fillMaxSize(), color = colors.background) {
            Column(Modifier.safeDrawingPadding().verticalScroll(rememberScrollState()).padding(horizontal = 24.dp, vertical = 16.dp)
                .widthIn(max = 478.dp), horizontalAlignment = Alignment.CenterHorizontally) {
                Box(Modifier.fillMaxWidth().heightIn(min = 48.dp)) {
                    Text(if (inSession) text("sessionTitle") else "QuickSleep", Modifier.align(Alignment.Center).padding(horizontal = 60.dp), style = MaterialTheme.typography.titleMedium, textAlign = TextAlign.Center)
                    IconButton(onClick = { sheet = "settings" }, Modifier.align(Alignment.CenterEnd)) { Icon(painterResource(R.drawable.settings_icon), text("settings"), Modifier.size(20.dp)) }
                }
                Spacer(Modifier.height(18.dp))
                if (!inSession) {
                    Text(text("introTitle"), style = MaterialTheme.typography.headlineLarge, textAlign = TextAlign.Center)
                    Text(text("introSubtitle"), style = MaterialTheme.typography.bodyLarge, color = colors.secondary, textAlign = TextAlign.Center)
                    Orb(dark, null)
                    Text(text("durationTitle"), style = MaterialTheme.typography.bodyLarge)
                    Spacer(Modifier.height(12.dp))
                    FlowRow(Modifier.fillMaxWidth().background(colors.surface, RoundedCornerShape(16.dp)).padding(8.dp), horizontalArrangement = Arrangement.Center) {
                        for (minutes in listOf(5, 10, 15, null)) {
                            val selected = if (minutes == null) settings.minutes !in listOf(5, 10, 15) else settings.minutes == minutes
                            val label = if (minutes != null) text("minutes", "$minutes") else if (selected) text("minutes", "${settings.minutes}") else text("customDuration")
                            FilterChip(selected, onClick = { if (minutes == null) { custom = "${settings.minutes}"; customError = false; sheet = "duration" } else save(settings.copy(minutes = minutes)) }, label = { Text(label) }, modifier = Modifier.padding(horizontal = 3.dp), border = BorderStroke(0.dp, Color.Transparent), colors = FilterChipDefaults.filterChipColors(selectedContainerColor = colors.accent, selectedLabelColor = colors.ink))
                        }
                    }
                    Text(text("durationHint"), Modifier.padding(top = 8.dp), color = colors.secondary, textAlign = TextAlign.Center)
                    Spacer(Modifier.height(12.dp))
                    Surface(shape = RoundedCornerShape(20.dp), color = colors.surface, modifier = Modifier.fillMaxWidth().clickable { sheet = "sounds" }) {
                        Column(Modifier.padding(16.dp)) {
                            Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                                Text(text("soundMode"), Modifier.weight(1f))
                                Text(text("change") + " ›", color = colors.accent)
                            }
                            Spacer(Modifier.height(8.dp))
                            Text(text(modeKey(settings.mode)), style = MaterialTheme.typography.titleMedium)
                            Text(text(descriptionKey(settings.mode)), color = colors.secondary)
                            Text(text("mixedHint"), Modifier.padding(top = 8.dp), color = colors.secondary, style = MaterialTheme.typography.bodySmall)
                        }
                    }
                    Spacer(Modifier.height(56.dp))
                    Button(onClick = { command(PlaybackService.START, cfg()) }, enabled = playback.status !in listOf("connecting", "connectionError"), modifier = Modifier.fillMaxWidth().heightIn(min = 58.dp)) { Text(text("start")) }
                    Row(Modifier.padding(top = 14.dp), verticalAlignment = Alignment.CenterVertically) {
                        Image(painterResource(if (dark) R.drawable.lock_night else R.drawable.lock_light), null, Modifier.size(14.dp, 16.dp))
                        Spacer(Modifier.width(8.dp)); Text(text("lockHint"), color = colors.secondary)
                    }
                    if (playback.status == "error") Text(text("audioError"), Modifier.padding(12.dp))
                    if (playback.status == "connectionError") {
                        Text(text("startupError"))
                        TextButton(onClick = retry) { Text(text("retry")) }
                    }
                    if (playback.status == "connecting") Text(text("loading"), Modifier.padding(top = 12.dp))
                } else {
                    val plan = remember(playback.config) { SessionPlan(playback.config!!) }
                    val frame = plan.frameAt(if (playback.status == "complete") plan.duration.toDouble() else playback.elapsed)
                    // Session copy uses the frozen narration language, even if settings change.
                    val frozen = remember(plan, configuration) { base.createConfigurationContext(Configuration(configuration).apply { setLocale(Locale(plan.config.language.name)) }) }
                    fun sessionText(key: String, parameter: String? = null): String {
                        val id = frozen.resources.getIdentifier(key, "string", base.packageName)
                        val value = if (id != 0) frozen.getString(id) else key
                        return if (parameter == null) value else value.replace("{count}", parameter).replace("{time}", parameter)
                    }
                    Text(sessionText(modeKey(plan.config.mode)), color = colors.secondary)
                    Orb(dark, frame)
                    val title = when (playback.status) {
                        "loading" -> "loading"; "error" -> "audioError"; "complete" -> "completed"
                        else -> if (!playback.playing) "paused" else when (frame.phase) {
                            Phase.inhale -> "inhale"; Phase.hold -> "hold"; Phase.exhale -> "exhale"
                            Phase.fade -> "fading"; else -> "natural"
                        }
                    }
                    Text(sessionText(title), style = MaterialTheme.typography.headlineLarge, textAlign = TextAlign.Center)
                    if (frame.count != null && playback.status == "active") {
                        Text("${frame.count}", fontSize = 48.sp, color = colors.accent)
                        Text(sessionText("round", "${frame.cycle}"))
                    }
                    val remaining = ceil(frame.remaining).toInt()
                    Text(sessionText("remaining", "%02d:%02d".format(remaining / 60, remaining % 60)), Modifier.padding(24.dp), style = MaterialTheme.typography.bodyLarge)
                    if (playback.status == "active") Button(onClick = { command(if (playback.playing) "pause" else "play", null) }, Modifier.fillMaxWidth().heightIn(min = 58.dp)) { Text(sessionText(if (playback.playing) "pause" else "resume")) }
                    TextButton(onClick = { command(PlaybackService.STOP, null) }) { Text(sessionText(if (playback.status in listOf("error", "complete")) "backHome" else "end")) }
                    Text(sessionText("safetyHint"), Modifier.padding(top = 24.dp), color = colors.secondary, textAlign = TextAlign.Center)
                }
                if (saveError) Text(text("saveError"), Modifier.padding(top = 16.dp))
                Spacer(Modifier.height(24.dp))
            }
        }
        if (sheet != null) ModalBottomSheet(onDismissRequest = { dismissSheet() }, containerColor = colors.surface) {
            Column(Modifier.fillMaxWidth().verticalScroll(rememberScrollState()).padding(24.dp).navigationBarsPadding(), horizontalAlignment = Alignment.CenterHorizontally) {
                when (sheet) {
                    "sounds" -> {
                        Text(text("soundMode"), style = MaterialTheme.typography.titleLarge)
                        Text(text("soundHint"), Modifier.padding(vertical = 12.dp), textAlign = TextAlign.Center)
                        for (mode in SoundMode.entries) {
                            Surface(Modifier.fillMaxWidth().padding(vertical = 6.dp).clickable { save(settings.copy(mode = mode)) }, shape = RoundedCornerShape(18.dp), color = colors.background) {
                                Column(Modifier.padding(16.dp)) {
                                    Row(verticalAlignment = Alignment.CenterVertically) {
                                        RadioButton(settings.mode == mode, onClick = { save(settings.copy(mode = mode)) })
                                        Text(text(modeKey(mode)), Modifier.weight(1f), style = MaterialTheme.typography.titleLarge)
                                        TextButton(onClick = { if (playback.previewMode == mode) command(PlaybackService.CLOSE_PREVIEW, null) else { save(settings.copy(mode = mode)); command(PlaybackService.PREVIEW, cfg(mode)) } }) { Text(text(if (playback.previewMode == mode) "stopPreview" else "preview")) }
                                    }
                                    Text(text(descriptionKey(mode)), color = colors.secondary)
                                }
                            }
                        }
                    }
                    "duration" -> {
                        Text(text("customTitle"), style = MaterialTheme.typography.titleLarge)
                        OutlinedTextField(custom, onValueChange = { custom = it; customError = false }, label = { Text(text("customHint")) }, isError = customError, modifier = Modifier.fillMaxWidth().padding(vertical = 20.dp), singleLine = true)
                        if (customError) Text(text("customError"))
                        Button(onClick = { val minutes = parseMinutes(custom); if (minutes == null) customError = true else { save(settings.copy(minutes = minutes)); sheet = null } }) { Text(text("save")) }
                    }
                    "settings" -> {
                        Text(text("settings"), style = MaterialTheme.typography.titleLarge)
                        Text(text("language"), Modifier.padding(top = 24.dp), style = MaterialTheme.typography.bodyLarge)
                        for ((value, key) in listOf("system" to "system", "zh" to "chinese", "en" to "english")) SettingRow(text(key), settings.language == value) { save(settings.copy(language = value)) }
                        Text(text("theme"), Modifier.padding(top = 20.dp), style = MaterialTheme.typography.bodyLarge)
                        for (value in listOf("system", "night", "light")) SettingRow(text(value), settings.theme == value) { save(settings.copy(theme = value)) }
                        Text(text("nextSessionHint"), Modifier.padding(top = 20.dp), textAlign = TextAlign.Center)
                        Text(text("offlineNote"), Modifier.padding(top = 20.dp), color = colors.secondary)
                        Text(text("syntheticNote"), Modifier.padding(top = 12.dp), color = colors.secondary, textAlign = TextAlign.Center)
                    }
                }
                TextButton(onClick = { dismissSheet() }) { Text(text("close")) }
            }
        }
        }
    }
}

@Composable private fun SettingRow(label: String, selected: Boolean, action: () -> Unit) {
    Row(Modifier.fillMaxWidth().clickable(onClick = action).heightIn(min = 48.dp), verticalAlignment = Alignment.CenterVertically) {
        RadioButton(selected, onClick = action); Text(label)
    }
}

@Composable private fun Orb(dark: Boolean, frame: Frame?) {
    val context = LocalContext.current
    val reduceMotion = runCatching { SystemSettings.Global.getFloat(context.contentResolver, SystemSettings.Global.ANIMATOR_DURATION_SCALE, 1f) == 0f }.getOrDefault(false)
    val local = (frame?.elapsed ?: 0.0) % 19
    val scale = if (frame == null || reduceMotion) 1.0 else when (frame.phase) {
        Phase.inhale -> .8 + .2 * local / 4; Phase.hold -> 1.0; Phase.exhale -> 1.0 - .2 * (local - 11) / 8; else -> .9
    }
    Box(Modifier.padding(vertical = 14.dp).size(134.dp), contentAlignment = Alignment.Center) {
        Image(painterResource(if (dark) R.drawable.orb_night else R.drawable.orb_light), contentDescription = null,
            modifier = Modifier.requiredSize(164.dp).graphicsLayer { scaleX = scale.toFloat(); scaleY = scale.toFloat(); alpha = if (frame?.phase == Phase.complete) .5f else 1f })
    }
}

