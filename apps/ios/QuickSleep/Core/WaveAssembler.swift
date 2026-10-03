import Foundation

final class CancellationToken: @unchecked Sendable {
    private let lock = NSLock()
    private var cancelled = false
    func cancel() { lock.lock(); cancelled = true; lock.unlock() }
    var isCancelled: Bool { lock.lock(); defer { lock.unlock() }; return cancelled }
}

enum WaveAssembler {
    static func header(byteCount: Int) -> Data {
        var data = Data()
        func ascii(_ text: String) { data.append(contentsOf: text.utf8) }
        func u16(_ value: UInt16) { var little = value.littleEndian; withUnsafeBytes(of: &little) { data.append(contentsOf: $0) } }
        func u32(_ value: UInt32) { var little = value.littleEndian; withUnsafeBytes(of: &little) { data.append(contentsOf: $0) } }
        ascii("RIFF"); u32(UInt32(byteCount + 36)); ascii("WAVEfmt "); u32(16)
        u16(1); u16(1); u32(24000); u32(48000); u16(2); u16(16); ascii("data"); u32(UInt32(byteCount))
        return data
    }
    private static func exact(_ file: FileHandle, count: Int) throws -> Data {
        guard let bytes = try file.read(upToCount: count), bytes.count == count else { throw SessionError.invalidAudio }
        return bytes
    }
    private static func integer(_ bytes: Data, at offset: Int, width: Int = 4) -> Int {
        (0..<width).reduce(0) { $0 | (Int(bytes[offset + $1]) << ($1 * 8)) }
    }
    private static func dataBytes(_ file: FileHandle) throws -> Int {
        let riff = try exact(file, count: 12)
        guard String(data: riff[0..<4], encoding: .ascii) == "RIFF", String(data: riff[8..<12], encoding: .ascii) == "WAVE" else { throw SessionError.invalidAudio }
        var valid = false
        for _ in 0..<32 {
            let chunk = try exact(file, count: 8)
            let size = integer(chunk, at: 4)
            guard (0...8_000_000).contains(size) else { throw SessionError.invalidAudio }
            switch String(data: chunk[0..<4], encoding: .ascii) {
            case "fmt ":
                guard size >= 16 else { throw SessionError.invalidAudio }
                let fmt = try exact(file, count: size)
                guard integer(fmt, at: 0, width: 2) == 1, integer(fmt, at: 2, width: 2) == 1,
                      integer(fmt, at: 4) == 24000, integer(fmt, at: 8) == 48000,
                      integer(fmt, at: 12, width: 2) == 2, integer(fmt, at: 14, width: 2) == 16 else { throw SessionError.invalidAudio }
                valid = true
            case "data":
                guard valid else { throw SessionError.invalidAudio }
                return size
            default: _ = try exact(file, count: size)
            }
            if size % 2 != 0 { _ = try exact(file, count: 1) }
        }
        throw SessionError.invalidAudio
    }
    static func write(plan: SessionPlan, output: URL, source: (String) throws -> URL, cancelled: () -> Bool) throws {
        do {
            guard FileManager.default.createFile(atPath: output.path, contents: nil) else { throw SessionError.invalidAudio }
            let sink = try FileHandle(forWritingTo: output)
            defer { try? sink.close() }
            try sink.write(contentsOf: header(byteCount: plan.duration * 48000))
            for segment in plan.segments {
                if cancelled() { throw SessionError.cancelled }
                let file = try FileHandle(forReadingFrom: source(segment.path))
                defer { try? file.close() }
                var remaining = segment.seconds * 48000
                guard try dataBytes(file) >= remaining else { throw SessionError.invalidAudio }
                while remaining > 0 {
                    if cancelled() { throw SessionError.cancelled }
                    let count = min(65536, remaining)
                    try sink.write(contentsOf: exact(file, count: count))
                    remaining -= count
                }
            }
        } catch { try? FileManager.default.removeItem(at: output); throw error }
    }
}
