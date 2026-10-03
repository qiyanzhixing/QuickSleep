import Foundation

enum SoundMode: String, CaseIterable, Codable { case moon, mountain, forest }
enum AppLanguage: String, CaseIterable, Codable { case zh, en }
enum Phase: String { case inhale, hold, exhale, transition, natural, fade, complete }
struct SessionConfig: Equatable {
    let minutes: Int
    let mode: SoundMode
    let language: AppLanguage
}
struct Segment { let path: String; let seconds: Int }
struct Frame {
    let phase: Phase
    let elapsed: Double
    let remaining: Double
    let cycle: Int?
    let count: Int?
}
enum SessionError: Error { case invalidDuration, invalidAudio, cancelled }

func parseMinutes(_ input: String) -> Int? {
    let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !text.isEmpty, text.utf8.allSatisfy({ $0 >= 48 && $0 <= 57 }), let value = Int(text), (2...60).contains(value) else { return nil }
    return value
}

struct SessionPlan {
    let config: SessionConfig
    let segments: [Segment]
    var duration: Int { config.minutes * 60 }
    init(config: SessionConfig) throws {
        guard (2...60).contains(config.minutes) else { throw SessionError.invalidDuration }
        self.config = config
        let mode = config.mode.rawValue
        segments = [Segment(path: "audio/\(config.language.rawValue)/\(mode)_guide.wav", seconds: 80)] +
            Array(repeating: Segment(path: "audio/beds/\(mode)_bed.wav", seconds: 60), count: config.minutes - 2) +
            [Segment(path: "audio/beds/\(mode)_bed.wav", seconds: 25), Segment(path: "audio/beds/\(mode)_fade.wav", seconds: 15)]
    }
    func frame(at position: Double) -> Frame {
        let elapsed = min(max(position.isFinite ? position : 0, 0), Double(duration))
        let seconds = Int(elapsed)
        let local = seconds % 19
        let phase: Phase
        if elapsed >= Double(duration) { phase = .complete }
        else if elapsed >= Double(duration - 15) { phase = .fade }
        else if seconds >= 80 { phase = .natural }
        else if seconds >= 76 { phase = .transition }
        else if local < 4 { phase = .inhale }
        else if local < 11 { phase = .hold }
        else { phase = .exhale }
        let count: Int? = seconds < 76 ? (local < 4 ? local + 1 : local < 11 ? local - 3 : local - 10) : nil
        return Frame(phase: phase, elapsed: elapsed, remaining: Double(duration) - elapsed, cycle: seconds < 76 ? seconds / 19 + 1 : nil, count: count)
    }
}
