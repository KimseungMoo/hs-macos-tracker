import Foundation

public struct ImportedDeck: Equatable, Sendable {
    public var format: Int
    public var heroes: [Int]
    public var counts: [Int: Int]

    public init(format: Int, heroes: [Int], counts: [Int: Int]) {
        self.format = format
        self.heroes = heroes
        self.counts = counts
    }

    public var totalCards: Int {
        counts.values.reduce(0, +)
    }
}

public enum Deckstring {
    public enum Error: Swift.Error, Equatable {
        case invalid
    }

    public static func decode(_ text: String) throws -> ImportedDeck {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = Data(base64Encoded: trimmed) else { throw Error.invalid }
        var reader = ByteReader(bytes: [UInt8](data))
        guard reader.byte() == 0 else { throw Error.invalid }
        _ = try reader.varint()
        let format = try reader.varint()
        let heroes = try reader.idList()
        var counts: [Int: Int] = [:]
        for (id, _) in try reader.idList().map({ ($0, 1) }) {
            counts[id, default: 0] += 1
        }
        for id in try reader.idList() {
            counts[id, default: 0] += 2
        }
        let nCopies = try reader.varint()
        for _ in 0..<nCopies {
            let id = try reader.varint()
            let n = try reader.varint()
            guard n > 0 else { throw Error.invalid }
            counts[id, default: 0] += n
        }
        return ImportedDeck(format: format, heroes: heroes, counts: counts)
    }

    public static func encode(_ deck: ImportedDeck) -> String {
        var ones: [Int] = []
        var twos: [Int] = []
        var ns: [(Int, Int)] = []
        for (id, count) in deck.counts.sorted(by: { $0.key < $1.key }) {
            switch count {
            case 1: ones.append(id)
            case 2: twos.append(id)
            default: ns.append((id, count))
            }
        }
        var w = ByteWriter()
        w.byte(0)
        w.varint(1)
        w.varint(deck.format)
        w.idList(deck.heroes)
        w.idList(ones)
        w.idList(twos)
        w.varint(ns.count)
        for (id, n) in ns {
            w.varint(id)
            w.varint(n)
        }
        return Data(w.bytes).base64EncodedString()
    }
}

private struct ByteReader {
    let bytes: [UInt8]
    var index = 0

    mutating func byte() -> UInt8? {
        guard index < bytes.count else { return nil }
        defer { index += 1 }
        return bytes[index]
    }

    mutating func varint() throws -> Int {
        var result = 0
        var shift = 0
        while true {
            guard let raw = byte() else { throw Deckstring.Error.invalid }
            result |= Int(raw & 0x7F) << shift
            if raw & 0x80 == 0 { return result }
            shift += 7
            if shift > 35 { throw Deckstring.Error.invalid }
        }
    }

    mutating func idList() throws -> [Int] {
        let count = try varint()
        var ids: [Int] = []
        ids.reserveCapacity(count)
        for _ in 0..<count {
            ids.append(try varint())
        }
        return ids
    }
}

private struct ByteWriter {
    var bytes: [UInt8] = []

    mutating func byte(_ value: UInt8) {
        bytes.append(value)
    }

    mutating func varint(_ value: Int) {
        var v = value
        while v > 0x7F {
            bytes.append(UInt8(v & 0x7F) | 0x80)
            v >>= 7
        }
        bytes.append(UInt8(v & 0x7F))
    }

    mutating func idList(_ ids: [Int]) {
        varint(ids.count)
        for id in ids { varint(id) }
    }
}
