package com.qiyanzhixing.quicksleep.core

enum class SoundMode { moon, mountain, forest }
enum class AppLanguage { zh, en }
enum class Phase { inhale, hold, exhale, transition, natural, fade, complete }
data class SessionConfig(val minutes: Int, val mode: SoundMode, val language: AppLanguage)
data class Segment(val path: String, val seconds: Int)
data class Frame(val phase: Phase, val elapsed: Double, val remaining: Double, val cycle: Int? = null, val count: Int? = null)

fun parseMinutes(input: String): Int? {
    val text = input.trim()
    if (!Regex("[0-9]+").matches(text)) return null
    return text.toIntOrNull()?.takeIf { it in 2..60 }
}

class SessionPlan(val config: SessionConfig) {
    init { require(config.minutes in 2..60) }
    val duration: Int get() = config.minutes * 60
    val segments: List<Segment> = buildList {
        add(Segment("audio/${config.language.name}/${config.mode.name}_guide.wav", 80))
        repeat(config.minutes - 2) { add(Segment("audio/beds/${config.mode.name}_bed.wav", 60)) }
        add(Segment("audio/beds/${config.mode.name}_bed.wav", 25))
        add(Segment("audio/beds/${config.mode.name}_fade.wav", 15))
    }
    fun frameAt(position: Double): Frame {
        val elapsed = (if (position.isFinite()) position else 0.0).coerceIn(0.0, duration.toDouble())
        val seconds = elapsed.toInt()
        val phase = when {
            elapsed >= duration -> Phase.complete
            elapsed >= duration - 15 -> Phase.fade
            seconds >= 80 -> Phase.natural
            seconds >= 76 -> Phase.transition
            seconds % 19 < 4 -> Phase.inhale
            seconds % 19 < 11 -> Phase.hold
            else -> Phase.exhale
        }
        val local = seconds % 19
        val count = if (seconds < 76) when (phase) {
            Phase.inhale -> local + 1
            Phase.hold -> local - 3
            else -> local - 10
        } else null
        return Frame(phase, elapsed, duration - elapsed, if (seconds < 76) seconds / 19 + 1 else null, count)
    }
}
