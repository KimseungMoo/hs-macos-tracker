import Foundation
import GameState

public struct PublicEntity: Equatable, Sendable {
    public var id: Int
    public var cardID: String?
    public var zone: Zone
    public var side: Side
    public var cardType: CardType
    public var cost: Int?
    public var attack: Int?
    public var remainingHealth: Int?

    public init(
        id: Int,
        cardID: String?,
        zone: Zone,
        side: Side,
        cardType: CardType = .unknown,
        cost: Int? = nil,
        attack: Int? = nil,
        remainingHealth: Int? = nil
    ) {
        self.id = id
        self.cardID = cardID
        self.zone = zone
        self.side = side
        self.cardType = cardType
        self.cost = cost
        self.attack = attack
        self.remainingHealth = remainingHealth
    }
}

public struct PublicState: Equatable, Sendable {
    public var entities: [PublicEntity]
    public var turn: Int?
    public var build: BuildRef
    public var draft: DraftState
    public var decklist: [DeckCard]
    public var friendlyMana: Int?
    public var friendlyManaUsed: Int?
    public var friendlyHeroHealth: Int?
    public var opponentHeroHealth: Int?

    public init(
        entities: [PublicEntity] = [],
        turn: Int? = nil,
        build: BuildRef = .unknown,
        draft: DraftState = DraftState(),
        decklist: [DeckCard] = [],
        friendlyMana: Int? = nil,
        friendlyManaUsed: Int? = nil,
        friendlyHeroHealth: Int? = nil,
        opponentHeroHealth: Int? = nil
    ) {
        self.entities = entities
        self.turn = turn
        self.build = build
        self.draft = draft
        self.decklist = decklist
        self.friendlyMana = friendlyMana
        self.friendlyManaUsed = friendlyManaUsed
        self.friendlyHeroHealth = friendlyHeroHealth
        self.opponentHeroHealth = opponentHeroHealth
    }

    public var friendlyManaLeft: Int? {
        guard let friendlyMana else { return nil }
        return friendlyMana - (friendlyManaUsed ?? 0)
    }
}

public enum Visibility {
    public static func filter(_ state: GameState) -> PublicState {
        let entities = state.entities.values.compactMap { entity -> PublicEntity? in
            let side = Side.of(controllerID: entity.controllerID, friendly: state.friendlyControllerID)
            if entity.isSecret, side != .friendly {
                return nil
            }
            switch (side, entity.zone) {
            case (.friendly, _), (_, .play), (_, .graveyard):
                return PublicEntity(
                    id: entity.id,
                    cardID: entity.cardID,
                    zone: entity.zone,
                    side: side,
                    cardType: entity.cardType,
                    cost: entity.cost,
                    attack: entity.attack,
                    remainingHealth: entity.remainingHealth
                )
            default:
                return nil
            }
        }
        .sorted { $0.id < $1.id }

        return PublicState(
            entities: entities,
            turn: state.turn,
            build: state.build,
            draft: state.draft,
            decklist: state.decklist,
            friendlyMana: resource(in: state, side: .friendly, \.resources),
            friendlyManaUsed: resource(in: state, side: .friendly, \.resourcesUsed),
            friendlyHeroHealth: heroHealth(in: state, side: .friendly),
            opponentHeroHealth: heroHealth(in: state, side: .opponent)
        )
    }

    public static func redact(_ line: String) -> String {
        var text = line
        text = replace(text, #"GameAccountId=\[[^\]]*\]"#, "GameAccountId=[REDACTED]")
        text = replace(text, #"\bhi=\d+"#, "hi=0")
        text = replace(text, #"\blo=\d+"#, "lo=0")
        text = replace(text, #"PlayerName=\S+"#, "PlayerName=REDACTED")
        text = replace(text, #"[A-Za-z][A-Za-z0-9_]{1,15}#\d{4,5}"#, "REDACTED")
        return text
    }

    private static func replace(_ text: String, _ pattern: String, _ template: String) -> String {
        text.replacingOccurrences(of: pattern, with: template, options: .regularExpression)
    }

    private static func resource(
        in state: GameState,
        side: Side,
        _ keyPath: KeyPath<Entity, Int?>
    ) -> Int? {
        let entities = state.entities.values.filter {
            Side.of(controllerID: $0.controllerID, friendly: state.friendlyControllerID) == side
                && $0[keyPath: keyPath] != nil
        }
        if let player = entities.first(where: { $0.cardType == .player }) {
            return player[keyPath: keyPath]
        }
        return entities.first?[keyPath: keyPath]
    }

    private static func heroHealth(in state: GameState, side: Side) -> Int? {
        state.entities.values.first { entity in
            entity.cardType == .hero
                && Side.of(controllerID: entity.controllerID, friendly: state.friendlyControllerID) == side
        }?.remainingHealth
    }
}
