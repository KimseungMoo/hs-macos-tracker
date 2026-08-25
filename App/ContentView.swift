import HSMacOSTrackerLib
import SwiftUI

struct ContentView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        Form {
            Section("Environment") {
                LabeledContent("Log directory") {
                    Text(model.logDirectoryLabel)
                        .textSelection(.enabled)
                }
                LabeledContent("Game build") {
                    Text(model.gameBuildLabel)
                }
                LabeledContent("Screen capture") {
                    Text(model.screenCaptureLabel)
                }
                LabeledContent("HS window") {
                    Text(model.gameWindowLabel)
                }
            }

            Section("Deck") {
                TextField("Deck code", text: $model.deckstringText, axis: .vertical)
                    .lineLimit(2...4)
                    .textFieldStyle(.roundedBorder)
                Button("Import deck") {
                    model.importDeck()
                }
                if let importError = model.importError {
                    Text(importError)
                        .foregroundStyle(.red)
                }
                TextField("I am player 1 or 2 (blank = infer only)", text: $model.friendlySeatText)
                    .onSubmit { model.applyFriendlySeat() }
                Button("Set seat") {
                    model.applyFriendlySeat()
                }
            }

            Section("Arena") {
                if !model.featureFlags.arenaEnabled {
                    Text("Arena off")
                        .foregroundStyle(.secondary)
                } else {
                    LabeledContent("Phase") {
                        Text(model.arenaPhase.rawValue)
                    }
                    Text("1픽: 전설 클릭 → 버킷 이름 미리보기. 긴 이름은 잘림. 호버해서 풀네임 확인.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("버킷: Legendary 5 | Extra 2 minion | Extra 3 removal  (… 잘린 이름 금지)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("이후 픽: Fireball 4 removal")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ForEach(0..<3, id: \.self) { index in
                        TextField("Offer \(index + 1)", text: $model.arenaOffer[index])
                    }
                    TextField("Picked so far, one per line (1픽 후 버킷 전부)", text: $model.arenaPickedText, axis: .vertical)
                        .lineLimit(3...8)
                    Button("Recommend pick") {
                        model.recommendArenaPick()
                    }
                    if let error = model.arenaParseError {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                    if let advice = model.arenaAdvice {
                        Text("Pick: \(advice.pick.name) (\(advice.scores[advice.pick.name] ?? 0))")
                        Text("Alt: \(advice.runnerUp.name) (\(advice.scores[advice.runnerUp.name] ?? 0))")
                        Text(advice.reasons.joined(separator: " · "))
                            .font(.caption)
                        Text("confidence \(advice.confidence)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Match") {
                LabeledContent("Turn") {
                    Text(model.publicView.turn.map(String.init) ?? "unknown")
                }
                LabeledContent("Mana") {
                    Text(manaLabel(model.publicView))
                }
                remainingBlock
                publicOpponentBlock
                boardBlock(title: "My board", entities: model.publicView.friendlyBoard)
                boardBlock(title: "Opponent board", entities: model.publicView.opponentBoard)
            }

            Section("Advice") {
                if !model.featureFlags.adviceEnabled {
                    Text("Advice off")
                        .foregroundStyle(.secondary)
                } else if model.adviceLines.isEmpty {
                    Text("No reminders yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(model.adviceLines) { line in
                        Text(line.text)
                    }
                }
            }

            Section("Feature flags") {
                Toggle("Tracker", isOn: $model.featureFlags.trackerEnabled)
                Toggle("Arena", isOn: $model.featureFlags.arenaEnabled)
                Toggle("Advice", isOn: $model.featureFlags.adviceEnabled)
                    .onChange(of: model.featureFlags.adviceEnabled) { _, _ in
                        model.refreshAdvice()
                    }
                Toggle("Prescriptive advice", isOn: $model.featureFlags.advicePrescriptive)
                    .disabled(true)
                Text("Tracker: \(TrackerFeature.status)")
                Text("Arena: \(ArenaFeature.status)")
                Text("Advice: \(AdviceFeature.status)")
            }

            Section("Overlay") {
                Toggle("Show click-through overlay", isOn: $model.overlayVisible)
            }

            Section("Recent log lines") {
                if model.tailService.recentLines.isEmpty {
                    Text("No tailed lines yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(model.tailService.recentLines.enumerated()), id: \.offset) { _, line in
                        Text(line)
                            .font(.caption)
                            .textSelection(.enabled)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 560, minHeight: 520)
    }

    @ViewBuilder
    private var remainingBlock: some View {
        if !model.featureFlags.trackerEnabled {
            Text("Tracker off")
                .foregroundStyle(.secondary)
        } else if !model.publicView.remainingKnown {
            Text("Remaining: unknown")
        } else if model.publicView.remainingRows.isEmpty {
            Text("Remaining: empty")
        } else {
            ForEach(model.publicView.remainingRows) { row in
                LabeledContent("\(row.name) ×\(row.count)") {
                    Text(oddsLabel(row.nextDraw))
                }
            }
        }
    }

    @ViewBuilder
    private var publicOpponentBlock: some View {
        if model.publicView.opponentPublic.isEmpty {
            Text("Opponent public: none")
                .foregroundStyle(.secondary)
        } else {
            ForEach(Array(model.publicView.opponentPublic.enumerated()), id: \.offset) { _, card in
                Text(publicLabel(card))
            }
        }
    }

    private func boardBlock(title: String, entities: [BoardEntity]) -> some View {
        LabeledContent(title) {
            if entities.isEmpty {
                Text("none")
                    .foregroundStyle(.secondary)
            } else {
                Text(entities.map { boardLabel($0) }.joined(separator: ", "))
            }
        }
    }

    private func manaLabel(_ view: PublicMatchView) -> String {
        switch (view.mana, view.manaUsed) {
        case (nil, nil): return "unknown"
        case let (mana?, used?): return "\(mana - used)/\(mana)"
        case let (mana?, nil): return "\(mana)"
        case let (nil, used?): return "used \(used)"
        }
    }

    private func oddsLabel(_ value: Double?) -> String {
        guard let value else { return "—" }
        return String(format: "%.1f%%", value * 100)
    }

    private func publicLabel(_ card: PublicCard) -> String {
        if let dbfId = card.dbfId { return model.catalog.label(dbfId: dbfId) }
        if let cardId = card.cardId { return model.catalog.label(cardId: cardId) }
        return "unknown"
    }

    private func boardLabel(_ entity: BoardEntity) -> String {
        if let dbfId = entity.dbfId { return model.catalog.label(dbfId: dbfId) }
        if let cardId = entity.cardId { return model.catalog.label(cardId: cardId) }
        return "#\(entity.id)"
    }
}

struct SettingsView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        Form {
            Section("About") {
                Text("Tracker, arena buckets, in-play reminders. Prescriptive off.")
                Text("Card catalog: \(model.catalog.isEmpty ? "empty (ids only)" : "loaded")")
            }
            Section("Logs") {
                Text("Reads Power.log, Arena.log, LoadingScreen.log without delete or truncate.")
                Button("Refresh discovery") {
                    model.refreshEnvironment()
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 420)
    }
}
