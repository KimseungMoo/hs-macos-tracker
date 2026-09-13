import GameState
import Testing

struct ArenaScoreTests {
    @Test func pickUsesHigherNumber() throws {
        let rec = try ArenaScore.recommendPick([
            card("low", score: 71),
            card("high", score: 92),
            card("mid", score: 80),
        ])
        #expect(rec.pick.cardID == "high")
        #expect(rec.runnerUp.cardID == "mid")
        #expect(rec.pass.cardID == "low")
        #expect(rec.tied.isEmpty)
    }

    @Test func sameLetterStillUsesNumber() throws {
        let rec = try ArenaScore.recommendPick([
            card("a91", score: 91, letter: .a),
            card("a98", score: 98, letter: .a),
            card("a90", score: 90, letter: .a),
        ])
        #expect(rec.pick.cardID == "a98")
        #expect(rec.runnerUp.cardID == "a91")
    }

    @Test func differentLettersStillUseNumber() throws {
        let rec = try ArenaScore.recommendPick([
            card("b89", score: 89, letter: .b),
            card("a90", score: 90, letter: .a),
            card("c70", score: 70, letter: .c),
        ])
        #expect(rec.pick.cardID == "a90")
        #expect(rec.runnerUp.cardID == "b89")
    }

    @Test func numberBeatsConflictingLetter() throws {
        let rec = try ArenaScore.recommendPick([
            card("fakeS", score: 72, letter: .s),
            card("realB", score: 80, letter: .c),
            card("avoid", score: 40, letter: .f),
        ])
        #expect(rec.pick.cardID == "realB")
        #expect(ArenaLetterGrade.fromScore(72) == .c)
    }

    @Test func classScoreBeatsGeneric() throws {
        let rec = try ArenaScore.recommendPick([
            ArenaScoredCard(cardID: "reprint", score: 95, classScore: 60),
            card("ok", score: 80),
            card("meh", score: 70),
        ])
        #expect(rec.pick.cardID == "ok")
        #expect(ArenaScore.effectiveScore(of: rec.pass) == 60)
    }

    @Test func letterOnlyDoesNotRank() {
        #expect(throws: ArenaScoreError.missingScore(cardID: "letter")) {
            try ArenaScore.recommendPick([
                card("letter", letter: .s),
                card("n1", score: 80),
                card("n2", score: 70),
            ])
        }
    }

    @Test func exactTieIsStableAndReported() throws {
        let rec = try ArenaScore.recommendPick([
            card("zeta", score: 88),
            card("alpha", score: 88),
            card("mid", score: 70),
        ])
        #expect(rec.pick.cardID == "alpha")
        #expect(rec.tied.map(\.cardID) == ["zeta"])
    }

    @Test func pickNeedsThreeCards() {
        #expect(throws: ArenaScoreError.needThreeCards) {
            try ArenaScore.recommendPick([card("a", score: 1), card("b", score: 2)])
        }
    }

    @Test func emptyCardIDIsInvalid() {
        #expect(throws: ArenaScoreError.invalidCardID) {
            try ArenaScore.recommendPick([
                card("   ", score: 90),
                card("b", score: 80),
                card("c", score: 70),
            ])
        }
    }

    @Test func deckTakesHighestScoresWithCopyLimits() throws {
        let rec = try ArenaScore.recommendDeck(
            from: [
                card("top", score: 100, copies: 2),
                card("legend", score: 99, copies: 1),
                card("filler", score: 70, copies: 2),
                card("skip", letter: .s),
            ],
            size: 4
        )
        #expect(rec.entries.map { "\($0.card.cardID)x\($0.copies)" } == [
            "topx2", "legendx1", "fillerx1",
        ])
        #expect(rec.cardCount == 4)
        #expect(rec.incomplete == false)
        #expect(rec.minScore == 70)
        #expect(rec.meanScore == 92.25)
    }

    @Test func deckSkipsUnscoredAndFlagsIncomplete() throws {
        let rec = try ArenaScore.recommendDeck(
            from: [card("only", score: 80, copies: 2)],
            size: 30
        )
        #expect(rec.cardCount == 2)
        #expect(rec.incomplete == true)
        #expect(rec.meanScore == 80)
    }

    @Test func deckDedupsKeepingHigherEffectiveScore() throws {
        let rec = try ArenaScore.recommendDeck(
            from: [
                ArenaScoredCard(cardID: "same", score: 90),
                ArenaScoredCard(cardID: "same", score: 90, classScore: 50),
            ],
            size: 2
        )
        #expect(rec.entries.count == 1)
        #expect(ArenaScore.effectiveScore(of: rec.entries[0].card) == 90)
    }

    @Test func emptyOwnedFails() {
        #expect(throws: ArenaScoreError.emptyOwned) {
            try ArenaScore.recommendDeck(from: [card("nope", letter: .a)])
        }
    }

    private func card(
        _ id: String,
        score: Double? = nil,
        letter: ArenaLetterGrade? = nil,
        copies: Int = 2
    ) -> ArenaScoredCard {
        ArenaScoredCard(cardID: id, score: score, letterGrade: letter, maxCopies: copies)
    }
}
