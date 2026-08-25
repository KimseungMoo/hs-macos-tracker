import Foundation
import LogReader
import Testing

struct LogTailerTests {
    @Test func holdsPartialLineThenEmits() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("hs-tail-\(UUID().uuidString).txt")
        try Data().write(to: url)
        var tailer = LogTailer(url: url)

        try "hel".write(to: url, atomically: true, encoding: .utf8)
        #expect(try tailer.poll() == [])

        try "hel\nlo\n".write(to: url, atomically: true, encoding: .utf8)
        #expect(try tailer.poll() == ["hel", "lo"])
    }

    @Test func resetOnTruncate() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("hs-rotate-\(UUID().uuidString).txt")
        try "alpha\nbeta\n".write(to: url, atomically: true, encoding: .utf8)
        var tailer = LogTailer(url: url)
        #expect(try tailer.poll() == ["alpha", "beta"])

        try "gamma\n".write(to: url, atomically: true, encoding: .utf8)
        #expect(try tailer.poll() == ["gamma"])
    }

    @Test func pollDoesNotShrinkFile() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("hs-readonly-\(UUID().uuidString).txt")
        try "one\n".write(to: url, atomically: true, encoding: .utf8)
        let before = try FileManager.default.attributesOfItem(atPath: url.path)[.size] as? NSNumber
        var tailer = LogTailer(url: url)
        _ = try tailer.poll()
        let after = try FileManager.default.attributesOfItem(atPath: url.path)[.size] as? NSNumber
        #expect(before == after)
    }
}
