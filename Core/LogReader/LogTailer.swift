import Foundation

public struct LogTailer: Sendable {
    public let url: URL
    public private(set) var offset: UInt64
    public private(set) var pending: String

    public init(url: URL) {
        self.url = url
        self.offset = 0
        self.pending = ""
    }

    public mutating func poll() throws -> [String] {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let size = (attributes[.size] as? NSNumber)?.uint64Value ?? 0
        if size < offset {
            offset = 0
            pending = ""
        }

        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        try handle.seek(toOffset: offset)
        let data = try handle.readToEnd() ?? Data()
        offset += UInt64(data.count)

        guard let chunk = String(data: data, encoding: .utf8) else { return [] }
        pending += chunk

        var lines: [String] = []
        while let newline = pending.firstIndex(of: "\n") {
            var line = String(pending[..<newline])
            if line.last == "\r" {
                line.removeLast()
            }
            lines.append(line)
            pending.removeSubrange(...newline)
        }
        return lines
    }
}
