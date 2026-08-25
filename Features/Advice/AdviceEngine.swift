import Foundation

public struct AdviceLine: Equatable, Sendable, Identifiable {
    public var id: String
    public var text: String

    public init(id: String, text: String) {
        self.id = id
        self.text = text
    }
}

/// Deterministic reminders from public state + own remaining deck. No "play this card".
public enum AdviceEngine {
    public static func lines(
        from view: PublicMatchView,
        opponentHeroHealth: Int? = nil,
        friendlyFaceDamage: Int? = nil
    ) -> [AdviceLine] {
        var lines: [AdviceLine] = []

        if let leftover = unusedMana(mana: view.mana, used: view.manaUsed), leftover > 0 {
            lines.append(AdviceLine(id: "mana", text: "unused mana \(leftover)"))
        }

        if !view.opponentBoard.isEmpty {
            lines.append(
                AdviceLine(id: "threats", text: "public threats \(view.opponentBoard.count) on board")
            )
            lines.append(AdviceLine(id: "removal", text: "removal reminder (public board)"))
        }

        if let lethal = lethal(friendlyFaceDamage: friendlyFaceDamage, opponentHealth: opponentHeroHealth) {
            lines.append(AdviceLine(id: "lethal", text: lethal))
        }

        if view.remainingKnown {
            let top = view.remainingRows
                .sorted { ($0.nextDraw ?? 0) > ($1.nextDraw ?? 0) }
                .prefix(3)
            for row in top {
                guard let odds = row.nextDraw else { continue }
                lines.append(
                    AdviceLine(
                        id: "draw-\(row.dbfId)",
                        text: "next draw \(row.name) \(Int((odds * 100).rounded()))%"
                    )
                )
            }
        }

        return lines
    }

    public static func unusedMana(mana: Int?, used: Int?) -> Int? {
        guard let mana, let used, mana >= used, used >= 0 else { return nil }
        return mana - used
    }

    /// Face damage vs known opponent health. Missing numbers → no guess.
    public static func lethal(friendlyFaceDamage: Int?, opponentHealth: Int?) -> String? {
        guard let damage = friendlyFaceDamage, let health = opponentHealth, damage > 0, health > 0 else {
            return nil
        }
        if damage >= health {
            return "lethal possible (\(damage) >= \(health))"
        }
        return nil
    }
}
