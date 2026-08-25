import Foundation
import GameState

public struct LogParser: Sendable {
    public var currentEntityID: Int?

    public init() {}

    public mutating func parse(_ line: String, source: LogSource) -> [RawEvent] {
        let body = Self.stripPrefix(line)
        switch source {
        case .power:
            return parsePower(body)
        case .arena:
            return parseArena(body)
        case .loadingScreen:
            return parseLoading(body)
        }
    }

    private mutating func parsePower(_ body: String) -> [RawEvent] {
        if body.contains("CREATE_GAME") {
            currentEntityID = nil
            return [.gameCreate]
        }
        if body.contains("FULL_ENTITY") {
            guard let id = Scan.creatingID(body) ?? Scan.entityID(body) else { return [] }
            currentEntityID = id
            return [.fullEntity(id: id, cardID: Scan.cardID(body))]
        }
        if body.contains("SHOW_ENTITY") {
            guard let id = Scan.entityID(body), let cardID = Scan.cardID(body) else { return [] }
            currentEntityID = id
            return [.showEntity(id: id, cardID: cardID)]
        }
        if body.contains("TAG_CHANGE") {
            return [
                .tagChange(
                    entityID: Scan.entityID(body),
                    name: Scan.tagName(body) ?? "",
                    value: Scan.tagValue(body) ?? ""
                )
            ].filter { event in
                if case .tagChange(_, let name, let value) = event {
                    return !name.isEmpty && !value.isEmpty
                }
                return false
            }
        }
        if body.contains("tag="), body.contains("value="), let id = currentEntityID,
           let name = Scan.tagName(body), let value = Scan.tagValue(body)
        {
            return [.tag(entityID: id, name: name, value: value)]
        }
        return []
    }

    private func parseArena(_ body: String) -> [RawEvent] {
        let lower = body.lowercased()
        if lower.contains("onbegin") || lower.contains("onstartdraft") || lower.contains("redraft") {
            return [.arenaReset]
        }
        if lower.contains("onchosen"), let cardID = Scan.cardID(body) {
            return [.arenaPick(cardID)]
        }
        if let cardID = Scan.cardID(body) {
            return [.arenaCard(cardID)]
        }
        return []
    }

    private func parseLoading(_ body: String) -> [RawEvent] {
        if let build = Scan.build(body) {
            return [.build(build)]
        }
        return []
    }

    private static func stripPrefix(_ line: String) -> String {
        if let range = line.range(of: #"^[DWE] [0-9:.]+\s+"#, options: .regularExpression) {
            return String(line[range.upperBound...])
        }
        return line
    }
}

enum Scan {
    static func creatingID(_ line: String) -> Int? {
        int(after: "Creating ID=", in: line) ?? int(after: "Creating ID =", in: line)
    }

    static func entityID(_ line: String) -> Int? {
        int(after: " id=", in: line) ?? int(after: "EntityID=", in: line) ?? int(after: "Entity=", in: line)
    }

    static func cardID(_ line: String) -> String? {
        for key in ["CardID=", "cardId=", "cardid="] {
            if let value = token(after: key, in: line) {
                return value.isEmpty ? nil : value
            }
        }
        return nil
    }

    static func tagName(_ line: String) -> String? {
        token(after: "tag=", in: line)
    }

    static func tagValue(_ line: String) -> String? {
        token(after: "value=", in: line)
    }

    static func build(_ line: String) -> String? {
        guard let match = firstMatch(#"(?i)build[\s:=]+(\d{5,})"#, in: line) else { return nil }
        return match
    }

    private static func int(after prefix: String, in line: String) -> Int? {
        guard let token = token(after: prefix, in: line) else { return nil }
        let digits = token.prefix(while: \.isNumber)
        return Int(digits)
    }

    private static func token(after prefix: String, in line: String) -> String? {
        guard let start = line.range(of: prefix, options: .caseInsensitive) else { return nil }
        let rest = line[start.upperBound...]
        let end = rest.firstIndex(where: { $0 == " " || $0 == "]" || $0 == "," }) ?? rest.endIndex
        return String(rest[..<end])
    }

    private static func firstMatch(_ pattern: String, in line: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(line.startIndex..<line.endIndex, in: line)
        guard let match = regex.firstMatch(in: line, range: range), match.numberOfRanges > 1,
              let swiftRange = Range(match.range(at: 1), in: line)
        else { return nil }
        return String(line[swiftRange])
    }
}
