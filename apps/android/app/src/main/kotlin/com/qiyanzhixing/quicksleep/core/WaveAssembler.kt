package com.qiyanzhixing.quicksleep.core

import java.io.File
import java.io.InputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.concurrent.CancellationException

object WaveAssembler {
    fun header(byteCount: Int): ByteArray = ByteBuffer.allocate(44).order(ByteOrder.LITTLE_ENDIAN).apply {
        put("RIFF".toByteArray()); putInt(byteCount + 36); put("WAVEfmt ".toByteArray())
        putInt(16); putShort(1); putShort(1); putInt(24000); putInt(48000); putShort(2); putShort(16)
        put("data".toByteArray()); putInt(byteCount)
    }.array()

    private fun InputStream.exact(count: Int): ByteArray {
        val bytes = ByteArray(count)
        var offset = 0
        while (offset < count) {
            val read = read(bytes, offset, count - offset)
            require(read > 0) { "Truncated WAV" }
            offset += read
        }
        return bytes
    }

    private fun dataBytes(input: InputStream): Int {
        val riff = input.exact(12)
        require(String(riff, 0, 4) == "RIFF" && String(riff, 8, 4) == "WAVE") { "Invalid WAV" }
        var valid = false
        repeat(32) {
            val chunk = input.exact(8)
            val size = ByteBuffer.wrap(chunk, 4, 4).order(ByteOrder.LITTLE_ENDIAN).int
            require(size in 0..8_000_000) { "Invalid WAV chunk" }
            when (String(chunk, 0, 4)) {
                "fmt " -> {
                    require(size >= 16)
                    val fmt = ByteBuffer.wrap(input.exact(size)).order(ByteOrder.LITTLE_ENDIAN)
                    require(fmt.short.toInt() == 1 && fmt.short.toInt() == 1 && fmt.int == 24000 &&
                        fmt.int == 48000 && fmt.short.toInt() == 2 && fmt.short.toInt() == 16) { "Unsupported PCM" }
                    valid = true
                }
                "data" -> { require(valid); return size }
                else -> input.exact(size)
            }
            if (size % 2 != 0) input.exact(1)
        }
        error("Missing PCM data")
    }

    fun write(plan: SessionPlan, output: File, readAsset: (String) -> InputStream, cancelled: () -> Boolean) {
        try {
            output.outputStream().buffered().use { sink ->
                sink.write(header(plan.duration * 48000))
                val buffer = ByteArray(65536)
                for (segment in plan.segments) {
                    if (cancelled()) throw CancellationException()
                    readAsset(segment.path).use { source ->
                        var remaining = segment.seconds * 48000
                        require(dataBytes(source) >= remaining) { "Short audio asset" }
                        while (remaining > 0) {
                            if (cancelled()) throw CancellationException()
                            val count = source.read(buffer, 0, minOf(buffer.size, remaining))
                            require(count > 0) { "Truncated PCM" }
                            sink.write(buffer, 0, count)
                            remaining -= count
                        }
                    }
                }
            }
        } catch (error: Throwable) { output.delete(); throw error }
    }
}
