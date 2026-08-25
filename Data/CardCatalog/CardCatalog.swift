import Foundation

public struct CardInfo: Equatable, Sendable {
    public var dbfId: Int
    public var cardId: String
    public var name: String

    public init(dbfId: Int, cardId: String, name: String) {
        self.dbfId = dbfId
        self.cardId = cardId
        self.name = name
    }
}

/// Local lookup only. Empty until a build-pinned datapack is loaded. No /latest fetch.
public struct CardCatalog: Equatable, Sendable {
    private var byDbf: [Int: CardInfo]
    private var byCardId: [String: CardInfo]

    public static let empty = CardCatalog(cards: [])

    public init(cards: [CardInfo]) {
        var dbf: [Int: CardInfo] = [:]
        var ids: [String: CardInfo] = [:]
        for card in cards {
            dbf[card.dbfId] = card
            ids[card.cardId] = card
        }
        byDbf = dbf
        byCardId = ids
    }

    public var isEmpty: Bool { byDbf.isEmpty }

    public func info(dbfId: Int) -> CardInfo? { byDbf[dbfId] }

    public func info(cardId: String) -> CardInfo? { byCardId[cardId] }

    public func dbfId(for cardId: String) -> Int? { byCardId[cardId]?.dbfId }

    public func label(dbfId: Int) -> String {
        byDbf[dbfId]?.name ?? "#\(dbfId)"
    }

    public func label(cardId: String) -> String {
        if let info = byCardId[cardId] { return info.name }
        return cardId
    }
}
