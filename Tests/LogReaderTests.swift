import XCTest
@testable import HSMacOSTrackerLib

final class LogLineBufferTests: XCTestCase {
    func testPartialLineAcrossChunks() {
        var buffer = LogLineBuffer()
        XCTAssertEqual(buffer.append("alpha\nbeta-"), ["alpha"])
        XCTAssertEqual(buffer.append("line\n"), ["beta-line"])
        XCTAssertEqual(buffer.remainder, "")
    }

    func testRotationResetsRemainderWhenReassembled() {
        var buffer = LogLineBuffer()
        _ = buffer.append("partial-without-newline")
        buffer = LogLineBuffer()
        XCTAssertEqual(buffer.append("fresh\n"), ["fresh"])
    }

    func testCarriageReturnTrimmed() {
        var buffer = LogLineBuffer()
        XCTAssertEqual(buffer.append("line\r\n"), ["line"])
    }
}

final class LogTailReaderIntegrationTests: XCTestCase {
    func testTailEmitsAppendedLinesAfterRotation() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("hs-log-tail-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let logURL = directory.appendingPathComponent("Power.log")
        FileManager.default.createFile(atPath: logURL.path, contents: Data("one\n".utf8))

        let reader = LogTailReader(url: logURL)
        let collector = LineCollector()
        reader.onLine = { line in
            collector.append(line)
        }
        reader.bootstrapForTesting()
        reader.readAvailableForTesting()

        try appendLog("two\n", to: logURL)
        reader.readAvailableForTesting()
        try rotateLog(at: logURL, contents: "three\n")
        reader.reopenFromStartForTesting()

        XCTAssertEqual(collector.values, ["two", "three"])
        reader.stop()
    }
}

private final class LineCollector: @unchecked Sendable {
    private let lock = NSLock()
    private(set) var values: [String] = []

    func append(_ line: String) {
        lock.lock()
        values.append(line)
        lock.unlock()
    }
}

private func appendLog(_ text: String, to url: URL) throws {
    let handle = try FileHandle(forWritingTo: url)
    defer { try? handle.close() }
    try handle.seekToEnd()
    try handle.write(contentsOf: Data(text.utf8))
}

private func rotateLog(at url: URL, contents: String) throws {
    try FileManager.default.removeItem(at: url)
    FileManager.default.createFile(atPath: url.path, contents: Data(contents.utf8))
}

final class GameBuildDetectorTests: XCTestCase {
    func testDetectsExplicitMarkersOnly() {
        let lines = [
            "noise",
            "GameVersion=31.2.0.123456",
        ]
        XCTAssertEqual(GameBuildDetector.detect(from: lines), "31.2.0.123456")
    }

    func testUnknownWhenNoMarker() {
        XCTAssertNil(GameBuildDetector.detect(from: ["LoadingScreen.OnSceneLoaded()"]))
    }
}
