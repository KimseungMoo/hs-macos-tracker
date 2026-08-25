import Foundation

public enum GameBuildDetector {
    /// Parses only explicit version/build markers. Returns nil when unknown.
    public static func detect(from lines: [String]) -> String? {
        for line in lines.reversed() {
            if let value = match(line: line, pattern: #"BuildNumber=(\d+)"#) {
                return "build \(value)"
            }
            if let value = match(line: line, pattern: #"GameVersion=([\d.]+)"#) {
                return value
            }
            if let value = match(line: line, pattern: #"Hearthstone version (\d+\.\d+\.\d+\.\d+)"#) {
                return value
            }
        }
        return nil
    }

    public static func scanFile(at url: URL, maxBytes: Int = 256_000) -> String? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        guard let handle = FileHandle(forReadingAtPath: url.path) else { return nil }
        defer { try? handle.close() }

        let attrs = try? FileManager.default.attributesOfItem(atPath: url.path)
        let size = (attrs?[.size] as? NSNumber)?.intValue ?? 0
        let readSize = min(size, maxBytes)
        let start = max(0, size - readSize)

        do {
            try handle.seek(toOffset: UInt64(start))
            let data = try handle.read(upToCount: readSize) ?? Data()
            guard let text = String(data: data, encoding: .utf8) else { return nil }
            return detect(from: text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init))
        } catch {
            return nil
        }
    }

    private static func match(line: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(line.startIndex..<line.endIndex, in: line)
        guard let result = regex.firstMatch(in: line, range: range),
              result.numberOfRanges > 1,
              let capture = Range(result.range(at: 1), in: line)
        else { return nil }
        return String(line[capture])
    }
}
