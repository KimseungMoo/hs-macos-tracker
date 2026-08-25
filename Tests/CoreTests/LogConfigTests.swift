import Foundation
import LogReader
import Testing

struct LogConfigTests {
    @Test func mergeAddsManagedSectionsWithoutVerbose() {
        let merged = LogConfig.merge(existing: "")
        #expect(merged.contains("[Power]"))
        #expect(merged.contains("[Arena]"))
        #expect(merged.contains("[LoadingScreen]"))
        #expect(merged.contains("LogLevel=1"))
        #expect(merged.contains("FilePrinting=true"))
        #expect(!merged.lowercased().contains("verbose"))
    }

    @Test func mergeKeepsForeignSections() {
        let existing = """
        [Zone]
        LogLevel=1
        FilePrinting=true

        [Power]
        LogLevel=2
        Verbose=true
        """
        let merged = LogConfig.merge(existing: existing)
        #expect(merged.contains("[Zone]"))
        #expect(merged.contains("LogLevel=1"))
        #expect(merged.contains("Verbose=true"))
        #expect(merged.contains("[Arena]"))
    }

    @Test func applyWritesOnlyConfigFile() throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("hs-logconfig-\(UUID().uuidString)")
        let config = dir.appendingPathComponent("log.config")
        let log = dir.appendingPathComponent("Power.log")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try "keep\n".write(to: log, atomically: true, encoding: .utf8)

        try LogConfig.apply(at: config)
        let written = try String(contentsOf: config, encoding: .utf8)
        let leftover = try String(contentsOf: log, encoding: .utf8)
        #expect(written.contains("[Power]"))
        #expect(leftover == "keep\n")
    }
}
