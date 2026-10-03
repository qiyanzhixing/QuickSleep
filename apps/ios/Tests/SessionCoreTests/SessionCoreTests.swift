import XCTest
@testable import SessionCore

final class SessionCoreTests: XCTestCase {
    func testSharedProductContract() throws {
        var root = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { root.deleteLastPathComponent() }
        let data = try Data(contentsOf: root.appendingPathComponent("shared/session-vectors.json"))
        let contract = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let boundaries = try XCTUnwrap(contract["boundaries"] as? [[String: Any]])
        let plan = try SessionPlan(config: .init(minutes: 2, mode: .moon, language: .zh))
        for vector in boundaries {
            let seconds = try XCTUnwrap(vector["seconds"] as? NSNumber).doubleValue
            let frame = plan.frame(at: seconds)
            XCTAssertEqual(frame.phase.rawValue, vector["phase"] as? String)
            XCTAssertEqual(frame.elapsed, try XCTUnwrap(vector["elapsed"] as? NSNumber).doubleValue, accuracy: 0.00001)
            XCTAssertEqual(frame.cycle, (vector["cycle"] as? NSNumber)?.intValue)
            XCTAssertEqual(frame.count, (vector["count"] as? NSNumber)?.intValue)
        }
    }
    func testAllDurationsAndLanguages() throws {
        for minutes in 2...60 {
            for mode in SoundMode.allCases {
                for language in AppLanguage.allCases {
                    let plan = try SessionPlan(config: .init(minutes: minutes, mode: mode, language: language))
                    XCTAssertEqual(plan.segments.reduce(0) { $0 + $1.seconds }, minutes * 60)
                    XCTAssertEqual(plan.segments.first?.seconds, 80)
                    XCTAssertEqual(plan.segments.last?.seconds, 15)
                    XCTAssertEqual(plan.segments[plan.segments.count - 2].seconds, 25)
                }
            }
        }
    }
    func testBoundariesAndClamping() throws {
        let plan = try SessionPlan(config: .init(minutes: 2, mode: .moon, language: .zh))
        let cases: [(Double, Phase)] = [(0,.inhale),(4,.hold),(11,.exhale),(19,.inhale),(75,.exhale),(76,.transition),(80,.natural),(105,.fade),(120,.complete)]
        for (time, phase) in cases { XCTAssertEqual(plan.frame(at: time).phase, phase) }
        XCTAssertEqual(plan.frame(at: 75).cycle, 4)
        XCTAssertEqual(plan.frame(at: 75).count, 8)
        XCTAssertEqual(plan.frame(at: -2).elapsed, 0)
        XCTAssertEqual(plan.frame(at: 200).remaining, 0)
    }
    func testInvalidInput() {
        for text in ["", "1", "61", "2.5", "-2", "abc", "99999999999"] { XCTAssertNil(parseMinutes(text)) }
        XCTAssertEqual(parseMinutes(" 2 "), 2)
        XCTAssertEqual(parseMinutes("60"), 60)
        XCTAssertThrowsError(try SessionPlan(config: .init(minutes: 61, mode: .moon, language: .en)))
    }
    func testWaveAssembly() throws {
        let plan = try SessionPlan(config: .init(minutes: 2, mode: .moon, language: .en))
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        for segment in plan.segments {
            let seconds = segment.path.contains("bed") ? 60 : segment.seconds
            let value: UInt8 = segment.path.contains("guide") ? 1 : segment.path.contains("bed") ? 2 : 3
            let source = directory.appendingPathComponent(segment.path.replacingOccurrences(of: "/", with: "_"))
            try (WaveAssembler.header(byteCount: seconds * 48000) + Data(repeating: value, count: seconds * 48000)).write(to: source)
        }
        let output = directory.appendingPathComponent("session.wav")
        try WaveAssembler.write(plan: plan, output: output, source: {
            directory.appendingPathComponent($0.replacingOccurrences(of: "/", with: "_"))
        }, cancelled: { false })
        let data = try Data(contentsOf: output)
        XCTAssertEqual(data.count, 44 + 120 * 48000)
        XCTAssertEqual(data[44 + 80 * 48000 - 1], 1)
        XCTAssertEqual(data[44 + 80 * 48000], 2)
        XCTAssertEqual(data[44 + 105 * 48000], 3)
    }
    func testCancellationRemovesOutput() throws {
        let output = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".wav")
        let plan = try SessionPlan(config: .init(minutes: 2, mode: .moon, language: .en))
        XCTAssertThrowsError(try WaveAssembler.write(plan: plan, output: output, source: { _ in output }, cancelled: { true }))
        XCTAssertFalse(FileManager.default.fileExists(atPath: output.path))
    }
}
