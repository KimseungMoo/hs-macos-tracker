import Foundation

public enum LogSource: String, Sendable {
    case power
    case arena
    case loadingScreen
}

public enum Zone: String, Sendable {
    case hand = "HAND"
    case deck = "DECK"
    case play = "PLAY"
    case secret = "SECRET"
    case graveyard = "GRAVEYARD"
    case setaside = "SETASIDE"
    case unknown

    public var isPublic: Bool {
        self == .play || self == .graveyard
    }

    public static func parse(_ raw: String) -> Zone {
        Zone(rawValue: raw.uppercased()) ?? .unknown
    }
}

public enum Side: String, Sendable {
    case friendly
    case opponent
    case unknown

    public static func of(controllerID: Int?, friendly: Int?) -> Side {
        guard let controllerID, let friendly else { return .unknown }
        return controllerID == friendly ? .friendly : .opponent
    }
}

public enum CardType: String, Sendable {
    case hero = "HERO"
    case minion = "MINION"
    case spell = "SPELL"
    case weapon = "WEAPON"
    case heroPower = "HERO_POWER"
    case player = "PLAYER"
    case unknown

    public static func parse(_ raw: String) -> CardType {
        CardType(rawValue: raw.uppercased()) ?? .unknown
    }
}

public enum BuildRef: Equatable, Sendable {
    case unknown
    case pinned(String)

    public var pinnedValue: String? {
        if case .pinned(let value) = self { return value }
        return nil
    }
}

public struct DeckCard: Equatable, Sendable {
    public var dbfId: Int
    public var cardID: String?
    public var count: Int

    public init(dbfId: Int, cardID: String? = nil, count: Int) {
        self.dbfId = dbfId
        self.cardID = cardID
        self.count = count
    }
}

public enum DraftSource: String, Sendable {
    case arenaLog
    case manual
    case ocr
}

public enum Confidence: String, Sendable {
    case high
    case low
}

public struct DraftCard: Equatable, Sendable {
    public var nameOrID: String
    public var source: DraftSource
    public var confidence: Confidence

    public init(nameOrID: String, source: DraftSource, confidence: Confidence) {
        self.nameOrID = nameOrID
        self.source = source
        self.confidence = confidence
    }
}

public struct DraftState: Equatable, Sendable {
    public var offered: [DraftCard]
    public var picked: [DraftCard]

    public init(offered: [DraftCard] = [], picked: [DraftCard] = []) {
        self.offered = offered
        self.picked = picked
    }
}

public enum DraftInputError: Error, Equatable, Sendable {
    case needThreeCards
    case emptyName
}

public enum DraftInput {
    public static func manual(_ cards: [String]) throws -> DraftState {
        let names = cards.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        guard names.count == 3 else { throw DraftInputError.needThreeCards }
        guard names.allSatisfy({ !$0.isEmpty }) else { throw DraftInputError.emptyName }
        return DraftState(
            offered: names.map { DraftCard(nameOrID: $0, source: .manual, confidence: .high) }
        )
    }
}

public enum RawEvent: Equatable, Sendable {
    case gameCreate
    case fullEntity(id: Int, cardID: String?)
    case showEntity(id: Int, cardID: String)
    case tag(entityID: Int, name: String, value: String)
    case tagChange(entityID: Int?, name: String, value: String)
    case arenaReset
    case arenaCard(String)
    case arenaPick(String)
    case build(String)
}

public struct Entity: Equatable, Sendable {
    public var id: Int
    public var cardID: String?
    public var zone: Zone
    public var controllerID: Int?
    public var isSecret: Bool
    public var publiclyRevealed: Bool
    public var cardType: CardType
    public var cost: Int?
    public var attack: Int?
    public var health: Int?
    public var damage: Int?
    public var resources: Int?
    public var resourcesUsed: Int?
    public var isCurrentPlayer: Bool

    public init(
        id: Int,
        cardID: String? = nil,
        zone: Zone = .unknown,
        controllerID: Int? = nil,
        isSecret: Bool = false,
        publiclyRevealed: Bool = false,
        cardType: CardType = .unknown,
        cost: Int? = nil,
        attack: Int? = nil,
        health: Int? = nil,
        damage: Int? = nil,
        resources: Int? = nil,
        resourcesUsed: Int? = nil,
        isCurrentPlayer: Bool = false
    ) {
        self.id = id
        self.cardID = cardID
        self.zone = zone
        self.controllerID = controllerID
        self.isSecret = isSecret
        self.publiclyRevealed = publiclyRevealed
        self.cardType = cardType
        self.cost = cost
        self.attack = attack
        self.health = health
        self.damage = damage
        self.resources = resources
        self.resourcesUsed = resourcesUsed
        self.isCurrentPlayer = isCurrentPlayer
    }

    public var remainingHealth: Int? {
        guard let health else { return nil }
        return health - (damage ?? 0)
    }
}
