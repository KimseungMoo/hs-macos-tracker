import Foundation

public struct BoardEntity: Equatable, Sendable, Identifiable {
    public var id: Int
    public var dbfId: Int?
    public var cardId: String?

    public init(id: Int, dbfId: Int?, cardId: String? = nil) {
        self.id = id
        self.dbfId = dbfId
        self.cardId = cardId
    }
}

public struct PublicCard: Equatable, Sendable {
    public var dbfId: Int?
    public var cardId: String?

    public init(dbfId: Int?, cardId: String?) {
        self.dbfId = dbfId
        self.cardId = cardId
    }
}

public enum GameEvent: Equatable, Sendable {
    case importDeck([Int: Int])
    case setFriendlyPlayer(Int)
    case gameReset
    case gap
    case turn(Int)
    case friendlyResources(available: Int?, used: Int?)
    case friendlyDraw(dbfId: Int?)
    case friendlyPlay(entityId: Int, dbfId: Int?, cardId: String?)
    case opponentPlay(entityId: Int, dbfId: Int?, cardId: String?)
    case boardLeave(entityId: Int)
}
