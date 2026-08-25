import Foundation

public enum ArenaTag: String, Equatable, Sendable, CaseIterable {
    case removal
    case draw
    case survival
    case minion
    case spell
    case beast
    case undead
    case dragon
    case mech
    case naga
    case elemental
    case murloc
    case demon
    case pirate
    case totem
}

public struct ArenaCard: Equatable, Sendable, Identifiable {
    public var id: String { name.lowercased() }
    public var name: String
    public var cost: Int
    public var tags: Set<ArenaTag>

    public init(name: String, cost: Int, tags: Set<ArenaTag> = []) {
        self.name = name
        self.cost = cost
        self.tags = tags
    }

    public var tribes: Set<ArenaTag> {
        tags.intersection(Self.tribeTags)
    }

    public static let tribeTags: Set<ArenaTag> = [
        .beast, .undead, .dragon, .mech, .naga, .elemental, .murloc, .demon, .pirate, .totem,
    ]

    /// `Name cost tag,tag` — cost required. Missing cost → not high-confidence.
    public static func parse(_ line: String) -> ArenaCard? {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let parts = trimmed.split(whereSeparator: { $0.isWhitespace }).map(String.init)
        guard parts.count >= 2 else { return nil }
        guard let costIndex = parts.lastIndex(where: { Int($0) != nil }),
              let cost = Int(parts[costIndex]),
              cost >= 0, cost <= 25
        else { return nil }
        let nameParts = parts[..<costIndex]
        guard !nameParts.isEmpty else { return nil }
        let name = nameParts.joined(separator: " ")
        guard !isTruncatedName(name) else { return nil }
        let tagTokens = parts[(costIndex + 1)...].joined(separator: ",").split(separator: ",").map {
            $0.trimmingCharacters(in: .whitespaces).lowercased()
        }
        let tags = Set(tagTokens.compactMap(ArenaTag.init(rawValue:)))
        return ArenaCard(name: name, cost: cost, tags: tags)
    }

    /// Click-preview list can clip long names. Those are not high-confidence.
    public static func isTruncatedName(_ name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        return trimmed.contains("...") || trimmed.contains("…") || trimmed.hasSuffix("..")
    }
}

public struct ArenaOffer: Equatable, Sendable {
    public var face: ArenaCard
    public var bucket: [ArenaCard]

    public init(face: ArenaCard, bucket: [ArenaCard] = []) {
        self.face = face
        self.bucket = bucket
    }

    public var pack: [ArenaCard] { [face] + bucket }

    /// `Face 5 | Extra 2 minion | Extra 3 removal` — first card is the legendary face.
    public static func parse(_ line: String) -> ArenaOffer? {
        let segments = line.split(separator: "|", omittingEmptySubsequences: false).map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        guard !segments.isEmpty else { return nil }
        var cards: [ArenaCard] = []
        for segment in segments {
            guard !segment.isEmpty, let card = ArenaCard.parse(segment) else { return nil }
            cards.append(card)
        }
        guard let face = cards.first else { return nil }
        return ArenaOffer(face: face, bucket: Array(cards.dropFirst()))
    }
}
