import Foundation

public struct CardRecord: Equatable, Sendable, Codable {
    public var id: String
    public var dbfId: Int
    public var name: [String: String]
    public var cost: Int?
    public var type: String
    public var cardClass: String?
    public var rarity: String?
    public var attack: Int?
    public var health: Int?
    public var mechanics: [String]
    public var text: String?

    public init(
        id: String,
        dbfId: Int,
        name: [String: String],
        cost: Int? = nil,
        type: String,
        cardClass: String? = nil,
        rarity: String? = nil,
        attack: Int? = nil,
        health: Int? = nil,
        mechanics: [String] = [],
        text: String? = nil
    ) {
        self.id = id
        self.dbfId = dbfId
        self.name = name
        self.cost = cost
        self.type = type
        self.cardClass = cardClass
        self.rarity = rarity
        self.attack = attack
        self.health = health
        self.mechanics = mechanics
        self.text = text
    }

    public func displayName(locale: String = "koKR") -> String {
        name[locale] ?? name["enUS"] ?? id
    }
}

public struct CardPack: Equatable, Sendable, Codable {
    public var build: String
    public var cards: [CardRecord]

    public init(build: String, cards: [CardRecord]) {
        self.build = build
        self.cards = cards
    }
}

public enum CardCatalogError: Error, Equatable, Sendable {
    case unreadable
    case unknownBuild
}

public struct CardCatalog: Equatable, Sendable {
    public var pack: CardPack
    private var byID: [String: CardRecord]
    private var byDbf: [Int: CardRecord]
    private var byName: [String: CardRecord]

    public init(pack: CardPack) {
        self.pack = pack
        var byID: [String: CardRecord] = [:]
        var byDbf: [Int: CardRecord] = [:]
        var byName: [String: CardRecord] = [:]
        for card in pack.cards {
            byID[card.id] = card
            byDbf[card.dbfId] = card
            for name in card.name.values {
                byName[Self.normalize(name)] = card
            }
        }
        self.byID = byID
        self.byDbf = byDbf
        self.byName = byName
    }

    public static func load(from url: URL, expectedBuild: String? = nil) throws -> CardCatalog {
        let data = try Data(contentsOf: url)
        return try load(from: data, expectedBuild: expectedBuild)
    }

    public static func load(from data: Data, expectedBuild: String? = nil) throws -> CardCatalog {
        let pack: CardPack
        do {
            pack = try JSONDecoder().decode(CardPack.self, from: data)
        } catch {
            throw CardCatalogError.unreadable
        }
        if let expectedBuild, pack.build != expectedBuild {
            throw CardCatalogError.unknownBuild
        }
        return CardCatalog(pack: pack)
    }

    public func card(id: String) -> CardRecord? { byID[id] }
    public func card(dbfId: Int) -> CardRecord? { byDbf[dbfId] }

    public func card(nameOrID: String) -> CardRecord? {
        if let card = byID[nameOrID] { return card }
        if let dbfId = Int(nameOrID), let card = byDbf[dbfId] { return card }
        return byName[Self.normalize(nameOrID)]
    }

    public func matches(build: String) -> Bool {
        pack.build == build
    }

    private static func normalize(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}

public enum UserScores {
    public static func load(from url: URL) throws -> [String: Int] {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([String: Int].self, from: data)
    }
}
