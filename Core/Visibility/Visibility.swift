import Foundation
import GameState

public struct PublicEntity: Equatable, Sendable {
    public var id: Int
    public var cardID: String?
    public var zone: Zone
    public var side: Side

    public init(id: Int, cardID: String?, zone: Zone, side: Side) {
        self.id = id
        self.cardID = cardID
        self.zone = zone
        self.side = side
    }
}

public struct PublicState: Equatable, Sendable {
    public var entities: [PublicEntity]
    public var turn: Int?
    public var build: BuildRef
    public var draft: DraftState

    public init(
        entities: [PublicEntity] = [],
        turn: Int? = nil,
        build: BuildRef = .unknown,
        draft: DraftState = DraftState()
    ) {
        self.entities = entities
        self.turn = turn
        self.build = build
        self.draft = draft
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
            case (.friendly, _):
                return PublicEntity(id: entity.id, cardID: entity.cardID, zone: entity.zone, side: side)
            case (_, .play), (_, .graveyard):
                return PublicEntity(id: entity.id, cardID: entity.cardID, zone: entity.zone, side: side)
            default:
                return nil
            }
        }
        .sorted { $0.id < $1.id }

        return PublicState(
            entities: entities,
            turn: state.turn,
            build: state.build,
            draft: state.draft
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
}
