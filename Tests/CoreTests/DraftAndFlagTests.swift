import GameState
import LogReader
import Testing

struct DraftAndFlagTests {
    @Test func manualThreeCardsAreHighConfidence() throws {
        let state = try GameState().applyingManualDraft(["어둠망토 성소", "미제 사건", "죽음의 혈통"])
        #expect(state.draft.offered.count == 3)
        #expect(state.draft.offered.allSatisfy { $0.source == .manual && $0.confidence == .high })
    }

    @Test func manualRejectsWrongCount() {
        #expect(throws: DraftInputError.needThreeCards) {
            try DraftInput.manual(["only", "two"])
        }
    }

    @Test func arenaLogOffersStayLowConfidence() {
        let lines = [
            "D 00:00:01.0 DraftManager.OnChoicesAndContents() - cardid=REV_840",
            "D 00:00:01.1 DraftManager.OnChoicesAndContents() - cardid=KAR_062",
        ]
        let state = SpikePipeline.ingest(lines: lines, source: .arena)
        #expect(state.draft.offered.map(\.nameOrID) == ["REV_840", "KAR_062"])
        #expect(state.draft.offered.allSatisfy { $0.confidence == .low })
    }

    @Test func loadingScreenPinsBuild() {
        let state = SpikePipeline.ingest(
            lines: ["D 00:00:01.0 LoadingScreen.OnSceneLoaded() - build=216414"],
            source: .loadingScreen
        )
        #expect(state.build == .pinned("216414"))
    }

    @Test func releaseFlagsStayOff() {
        #expect(FeatureFlags.arenaRecommendations == false)
        #expect(FeatureFlags.prescriptiveAdvice == false)
    }
}
