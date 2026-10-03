package com.qiyanzhixing.quicksleep.ui

import android.content.Context
import com.qiyanzhixing.quicksleep.core.SoundMode
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import org.json.JSONObject

data class Settings(val minutes: Int = 10, val mode: SoundMode = SoundMode.moon, val theme: String = "system", val language: String = "system")

class SettingsStore(context: Context) {
    private val storage = context.getSharedPreferences("quicksleep", Context.MODE_PRIVATE)
    private val mutex = Mutex()
    fun load(): Settings = try {
        val value = JSONObject(storage.getString("preferences", "{}") ?: "{}")
        Settings(
            minutes = (value.opt("minutes") as? Int)?.takeIf { it in 2..60 } ?: 10,
            mode = SoundMode.entries.find { it.name == value.optString("mode") } ?: SoundMode.moon,
            theme = value.optString("theme").takeIf { it in listOf("system", "night", "light") } ?: "system",
            language = value.optString("language").takeIf { it in listOf("system", "zh", "en") } ?: "system")
    } catch (_: Exception) { Settings() }
    suspend fun save(settings: Settings) = mutex.withLock {
        withContext(Dispatchers.IO) {
            check(storage.edit().putString("preferences", JSONObject().apply {
                put("minutes", settings.minutes); put("mode", settings.mode.name)
                put("theme", settings.theme); put("language", settings.language)
            }.toString()).commit()) { "Preference write failed" }
        }
    }
}
