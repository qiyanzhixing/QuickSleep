package com.qiyanzhixing.quicksleep.core

import org.junit.Assert.*
import org.junit.Test
import java.io.ByteArrayInputStream
import java.io.File
import org.json.JSONObject

class SessionPlanTest {
    @Test fun sharedProductContract() {
        val contract = JSONObject(File(requireNotNull(System.getProperty("sessionVectors"))).readText())
        val boundaries = contract.getJSONArray("boundaries")
        val plan = SessionPlan(SessionConfig(2, SoundMode.moon, AppLanguage.zh))
        for (i in 0 until boundaries.length()) {
            val vector = boundaries.getJSONObject(i)
            val frame = plan.frameAt(vector.getDouble("seconds"))
            assertEquals(vector.getString("phase"), frame.phase.name)
            assertEquals(vector.getDouble("elapsed"), frame.elapsed, 0.00001)
            assertEquals(if (vector.isNull("cycle")) null else vector.getInt("cycle"), frame.cycle)
            assertEquals(if (vector.isNull("count")) null else vector.getInt("count"), frame.count)
        }
    }
    @Test fun everyDurationHasExactFiniteTimeline() {
        for (minutes in 2..60) for (mode in SoundMode.entries) for (language in AppLanguage.entries) {
            val plan = SessionPlan(SessionConfig(minutes, mode, language))
            assertEquals(minutes * 60, plan.segments.sumOf { it.seconds })
            assertEquals(80, plan.segments.first().seconds)
            assertEquals(25, plan.segments[plan.segments.lastIndex - 1].seconds)
            assertEquals(15, plan.segments.last().seconds)
            assertEquals("audio/${language.name}/${mode.name}_guide.wav", plan.segments.first().path)
        }
    }
    @Test fun breathingAndEndBoundaries() {
        val plan = SessionPlan(SessionConfig(2, SoundMode.moon, AppLanguage.zh))
        val expected = listOf(0.0 to Phase.inhale, 4.0 to Phase.hold, 11.0 to Phase.exhale,
            19.0 to Phase.inhale, 75.0 to Phase.exhale, 76.0 to Phase.transition,
            80.0 to Phase.natural, 105.0 to Phase.fade, 120.0 to Phase.complete)
        expected.forEach { (time, phase) -> assertEquals(phase, plan.frameAt(time).phase) }
        assertEquals(4, plan.frameAt(75.0).cycle)
        assertEquals(8, plan.frameAt(75.0).count)
        assertEquals(0.0, plan.frameAt(-10.0).elapsed, 0.0)
        assertEquals(0.0, plan.frameAt(200.0).remaining, 0.0)
    }
    @Test fun customMinutesAndInvalidConfig() {
        listOf("", "1", "61", "2.5", "-2", "abc", "999999999999").forEach { assertNull(parseMinutes(it)) }
        assertEquals(2, parseMinutes(" 2 "))
        assertEquals(60, parseMinutes("60"))
        assertThrows(IllegalArgumentException::class.java) { SessionPlan(SessionConfig(1, SoundMode.moon, AppLanguage.en)) }
    }
    @Test fun waveAssemblyPreservesSamplesAndExactDuration() {
        val plan = SessionPlan(SessionConfig(2, SoundMode.moon, AppLanguage.en))
        val file = File.createTempFile("session", ".wav")
        try {
            WaveAssembler.write(plan, file, { path ->
                val seconds = when { path.endsWith("guide.wav") -> 80; path.endsWith("bed.wav") -> 60; else -> 15 }
                val value = when { path.endsWith("guide.wav") -> 1; path.endsWith("bed.wav") -> 2; else -> 3 }
                ByteArrayInputStream(WaveAssembler.header(seconds * 48000) + ByteArray(seconds * 48000) { value.toByte() })
            }, { false })
            val bytes = file.readBytes()
            assertEquals(44 + 120 * 48000, bytes.size)
            assertEquals(1.toByte(), bytes[44 + 80 * 48000 - 1])
            assertEquals(2.toByte(), bytes[44 + 80 * 48000])
            assertEquals(3.toByte(), bytes[44 + 105 * 48000])
        } finally { file.delete() }
    }
    @Test fun cancelledAssemblyCannotProducePlayableOutput() {
        val file = File.createTempFile("cancel", ".wav")
        try {
            assertThrows(java.util.concurrent.CancellationException::class.java) {
                WaveAssembler.write(SessionPlan(SessionConfig(2, SoundMode.moon, AppLanguage.en)), file,
                    { ByteArrayInputStream(byteArrayOf()) }, { true })
            }
            assertFalse(file.exists())
        } finally { file.delete() }
    }
}
