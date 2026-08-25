import XCTest
@testable import HSMacOSTrackerLib

final class ArenaCardTests: XCTestCase {
    func testParseNameCostTags() {
        let card = ArenaCard.parse("Netherspite Historian 2 minion,dragon")
        XCTAssertEqual(card?.name, "Netherspite Historian")
        XCTAssertEqual(card?.cost, 2)
        XCTAssertEqual(card?.tags, [.minion, .dragon])
    }

    func testParseRequiresCost() {
        XCTAssertNil(ArenaCard.parse("Fireball"))
        XCTAssertNil(ArenaCard.parse(""))
    }

    func testParseLegendaryBucket() {
        let offer = ArenaOffer.parse("Manastorm 5 minion | Duo 2 minion | Bolt 3 removal")
        XCTAssertEqual(offer?.face.name, "Manastorm")
        XCTAssertEqual(offer?.bucket.map(\.name), ["Duo", "Bolt"])
        XCTAssertEqual(offer?.pack.count, 3)
    }

    func testBucketFailClosedOnEmptySegment() {
        XCTAssertNil(ArenaOffer.parse("Manastorm 5 | | Bolt 3"))
    }

    func testTruncatedPreviewNameIsNotHighConfidence() {
        XCTAssertTrue(ArenaCard.isTruncatedName("Netherspite Histori..."))
        XCTAssertTrue(ArenaCard.isTruncatedName("황천의 원령 역사…"))
        XCTAssertNil(ArenaCard.parse("Netherspite Histori... 2 minion"))
        XCTAssertNil(ArenaOffer.parse("Manastorm 5 | Netherspite Histori... 2 minion"))
        XCTAssertFalse(ArenaCard.isTruncatedName("Netherspite Historian"))
    }
}

final class ArenaDraftDetectorTests: XCTestCase {
    func testDraftAndRedraftAndIdle() {
        var phase = ArenaPhase.unknown
        phase = ArenaDraftDetector.detect(from: "HUB -> DRAFT", current: phase)
        XCTAssertEqual(phase, .draft)
        phase = ArenaDraftDetector.detect(from: "Client-Redraft started", current: phase)
        XCTAssertEqual(phase, .redraft)
        phase = ArenaDraftDetector.detect(from: "nextMode=GAMEPLAY", current: phase)
        XCTAssertEqual(phase, .idle)
    }

    func testDoesNotGuessOffer() {
        let phase = ArenaDraftDetector.detect(from: "noise", current: .unknown)
        XCTAssertEqual(phase, .unknown)
    }
}

final class ArenaScorerTests: XCTestCase {
    func testNeedsExactlyThree() {
        let a = ArenaCard(name: "A", cost: 2)
        XCTAssertNil(ArenaScorer.advise(picked: [], offer: [a, a]))
    }

    func testCurveHoleBeatsLate() {
        let picked = [
            ArenaCard(name: "TwoA", cost: 2, tags: [.minion]),
            ArenaCard(name: "TwoB", cost: 2, tags: [.minion]),
            ArenaCard(name: "Six", cost: 6, tags: [.minion]),
        ]
        let offer = [
            ArenaCard(name: "Historian", cost: 2, tags: [.minion]),
            ArenaCard(name: "General", cost: 10, tags: [.minion]),
            ArenaCard(name: "Bolt", cost: 3, tags: [.removal, .spell]),
        ]
        let advice = ArenaScorer.advise(picked: picked, offer: offer)
        XCTAssertEqual(advice?.pick.name, "Bolt")
        XCTAssertEqual(advice?.confidence, "high")
        XCTAssertEqual(advice?.runnerUp.name, "Historian")
    }

    func testDuplicatePenalty() {
        let picked = [
            ArenaCard(name: "Fireball", cost: 4, tags: [.removal, .spell]),
            ArenaCard(name: "Fireball", cost: 4, tags: [.removal, .spell]),
        ]
        let offer = [
            ArenaCard(name: "Fireball", cost: 4, tags: [.removal, .spell]),
            ArenaCard(name: "Book", cost: 2, tags: [.draw, .minion]),
            ArenaCard(name: "Wolf", cost: 3, tags: [.minion, .beast]),
        ]
        let advice = ArenaScorer.advise(picked: picked, offer: offer)
        XCTAssertNotEqual(advice?.pick.name, "Fireball")
        XCTAssertLessThan(advice?.scores["Fireball"] ?? 0, advice?.scores["Book"] ?? 0)
    }

    func testSynergyOnlyAfterTwo() {
        let oneBeast = [
            ArenaCard(name: "Pup", cost: 5, tags: [.beast]),
            ArenaCard(name: "Rock", cost: 5),
        ]
        let twoBeasts = [
            ArenaCard(name: "Pup", cost: 5, tags: [.beast]),
            ArenaCard(name: "Hound", cost: 5, tags: [.beast]),
        ]
        let wolf = ArenaCard(name: "Wolf", cost: 5, tags: [.beast])
        XCTAssertEqual(ArenaScorer.score(wolf, picked: oneBeast).0, 50)
        XCTAssertEqual(ArenaScorer.score(wolf, picked: twoBeasts).0, 56)
    }

    func testFirstPickUsesBucketAverage() {
        let weakFace = ArenaOffer(
            face: ArenaCard(name: "BigLegend", cost: 9, tags: [.minion]),
            bucket: [
                ArenaCard(name: "PadA", cost: 8, tags: [.minion]),
                ArenaCard(name: "PadB", cost: 9, tags: [.minion]),
            ]
        )
        let strongPack = ArenaOffer(
            face: ArenaCard(name: "OkayLegend", cost: 6, tags: [.minion]),
            bucket: [
                ArenaCard(name: "TwoDrop", cost: 2, tags: [.minion]),
                ArenaCard(name: "Removal", cost: 3, tags: [.removal, .spell]),
            ]
        )
        let mid = ArenaOffer(
            face: ArenaCard(name: "MidLegend", cost: 5, tags: [.minion]),
            bucket: [
                ArenaCard(name: "MidA", cost: 5, tags: [.minion]),
                ArenaCard(name: "MidB", cost: 5, tags: [.minion]),
            ]
        )
        let advice = ArenaScorer.advise(picked: [], offers: [weakFace, strongPack, mid])
        XCTAssertEqual(advice?.pick.name, "OkayLegend")
        XCTAssertTrue(advice?.reasons.contains(where: { $0.contains("bucket avg") }) == true)
    }

    func testMixedBucketsOnFirstPickFailClosed() {
        let withBucket = ArenaOffer(
            face: ArenaCard(name: "L1", cost: 5),
            bucket: [ArenaCard(name: "A", cost: 2)]
        )
        let faceOnly = ArenaOffer(face: ArenaCard(name: "L2", cost: 5), bucket: [])
        let other = ArenaOffer(face: ArenaCard(name: "L3", cost: 5), bucket: [])
        XCTAssertNil(ArenaScorer.advise(picked: [], offers: [withBucket, faceOnly, other]))
    }

    func testNoOfferOddsInAdvice() {
        let offer = [
            ArenaCard(name: "A", cost: 2),
            ArenaCard(name: "B", cost: 3),
            ArenaCard(name: "C", cost: 4),
        ]
        let advice = ArenaScorer.advise(picked: [], offer: offer)
        let joined = advice?.reasons.joined() ?? ""
        XCTAssertFalse(joined.contains("pool"))
        XCTAssertFalse(joined.contains("odds"))
    }
}
