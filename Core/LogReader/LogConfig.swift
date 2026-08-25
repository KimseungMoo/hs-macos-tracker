import Foundation

public enum DefaultPaths {
    public static var logConfig: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Preferences/Blizzard/Hearthstone/log.config")
    }

    public static var logsDirectory: URL {
        URL(fileURLWithPath: "/Applications/Hearthstone/Logs")
    }
}

public enum LogConfig {
    public static let managedSections = ["Power", "Arena", "LoadingScreen"]

    public static func merge(existing: String) -> String {
        var document = INIDocument.parse(existing)
        for name in managedSections {
            var keys = document.section(name)
            keys.upsert(key: "LogLevel", value: "1")
            keys.upsert(key: "FilePrinting", value: "true")
            document.setSection(name, keys: keys)
        }
        return document.render()
    }

    public static func apply(at url: URL) throws {
        let existing = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
        let merged = merge(existing: existing)
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try merged.write(to: url, atomically: true, encoding: .utf8)
    }
}

struct INIKey: Equatable {
    var key: String
    var value: String
}

struct INIDocument {
    var sections: [(name: String, keys: [INIKey])] = []

    func section(_ name: String) -> [INIKey] {
        sections.first(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame })?.keys ?? []
    }

    mutating func setSection(_ name: String, keys: [INIKey]) {
        if let index = sections.firstIndex(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
            sections[index].keys = keys
        } else {
            sections.append((name, keys))
        }
    }

    func render() -> String {
        var parts: [String] = []
        for (name, keys) in sections {
            var block = "[\(name)]\n"
            for item in keys {
                block += "\(item.key)=\(item.value)\n"
            }
            parts.append(block)
        }
        return parts.joined(separator: "\n")
    }

    static func parse(_ text: String) -> INIDocument {
        var document = INIDocument()
        var current: String?
        var keys: [INIKey] = []

        func flush() {
            if let current {
                document.sections.append((current, keys))
            }
            keys = []
        }

        for raw in text.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline) {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.isEmpty || line.hasPrefix(";") || line.hasPrefix("#") {
                continue
            }
            if line.hasPrefix("["), line.hasSuffix("]"), line.count >= 2 {
                flush()
                current = String(line.dropFirst().dropLast())
                continue
            }
            guard current != nil, let eq = line.firstIndex(of: "=") else { continue }
            keys.append(INIKey(key: String(line[..<eq]), value: String(line[line.index(after: eq)...])))
        }
        flush()
        return document
    }
}

extension [INIKey] {
    mutating func upsert(key: String, value: String) {
        if let index = firstIndex(where: { $0.key.caseInsensitiveCompare(key) == .orderedSame }) {
            self[index].value = value
        } else {
            append(INIKey(key: key, value: value))
        }
    }
}
