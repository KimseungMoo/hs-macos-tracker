import Foundation
import GameState

public enum DeckstringError: Error, Equatable, Sendable {
    case invalidBase64
    case truncated
    case unsupportedVersion
}

public enum Deckstring {
    public static func decode(_ code: String) throws -> [DeckCard] {
        guard let data = Data(base64Encoded: pad(code), options: .ignoreUnknownCharacters) else {
            throw DeckstringError.invalidBase64
        }
        var reader = ByteReader(bytes: [UInt8](data))
        _ = try reader.varint()
        let version = try reader.varint()
        guard version == 1 else { throw DeckstringError.unsupportedVersion }
        _ = try reader.varint()
        let heroCount = try reader.varint()
        for _ in 0..<heroCount {
            _ = try reader.varint()
        }

        var cards: [DeckCard] = []
        let ones = try reader.varint()
        for _ in 0..<ones {
            cards.append(DeckCard(dbfId: try reader.varint(), count: 1))
        }
        let twos = try reader.varint()
        for _ in 0..<twos {
            cards.append(DeckCard(dbfId: try reader.varint(), count: 2))
        }
        let many = try reader.varint()
        for _ in 0..<many {
            let dbfId = try reader.varint()
            let count = try reader.varint()
            cards.append(DeckCard(dbfId: dbfId, count: count))
        }
        return cards
    }

    public static func encode(_ cards: [DeckCard], heroDbfId: Int, format: Int = 1) -> String {
        var writer = ByteWriter()
        writer.varint(0)
        writer.varint(1)
        writer.varint(format)
        writer.varint(1)
        writer.varint(heroDbfId)

        let ones = cards.filter { $0.count == 1 }.map(\.dbfId)
        let twos = cards.filter { $0.count == 2 }.map(\.dbfId)
        let many = cards.filter { $0.count != 1 && $0.count != 2 }
        writer.varint(ones.count)
        ones.forEach { writer.varint($0) }
        writer.varint(twos.count)
        twos.forEach { writer.varint($0) }
        writer.varint(many.count)
        for card in many {
            writer.varint(card.dbfId)
            writer.varint(card.count)
        }
        return Data(writer.bytes).base64EncodedString()
    }

    public static func resolve(_ cards: [DeckCard], catalog: CardCatalog) -> [DeckCard] {
        cards.map { card in
            var next = card
            if next.cardID == nil {
                next.cardID = catalog.card(dbfId: next.dbfId)?.id
            }
            return next
        }
    }

    private static func pad(_ code: String) -> String {
        let trimmed = code.filter { !$0.isWhitespace }
        let pad = (4 - trimmed.count % 4) % 4
        return trimmed + String(repeating: "=", count: pad)
    }
}

struct ByteReader {
    var bytes: [UInt8]
    var index = 0

    mutating func varint() throws -> Int {
        var result = 0
        var shift = 0
        while true {
            guard index < bytes.count else { throw DeckstringError.truncated }
            let byte = bytes[index]
            index += 1
            result |= Int(byte & 0x7F) << shift
            if byte & 0x80 == 0 { return result }
            shift += 7
            if shift > 28 { throw DeckstringError.truncated }
        }
    }
}

struct ByteWriter {
    var bytes: [UInt8] = []

    mutating func varint(_ value: Int) {
        var value = value
        while value > 0x7F {
            bytes.append(UInt8((value & 0x7F) | 0x80))
            value >>= 7
        }
        bytes.append(UInt8(value & 0x7F))
    }
}
