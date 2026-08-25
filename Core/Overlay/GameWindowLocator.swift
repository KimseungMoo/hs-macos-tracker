import CoreGraphics
import Foundation

public struct GameWindow: Equatable, Sendable {
    public var owner: String
    public var quartzBounds: CGRect

    public init(owner: String, quartzBounds: CGRect) {
        self.owner = owner
        self.quartzBounds = quartzBounds
    }
}

/// On-screen Hearthstone window only. No Accessibility. Missing window → nil (no guess).
public enum GameWindowLocator {
    public static let ownerNeedles = ["Hearthstone"]

    public static func locate() -> GameWindow? {
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let info = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return nil
        }
        return locate(windows: info)
    }

    public static func locate(windows: [[String: Any]]) -> GameWindow? {
        let matches = windows.compactMap { window -> GameWindow? in
            guard let owner = window[kCGWindowOwnerName as String] as? String,
                  ownerNeedles.contains(where: { owner.localizedCaseInsensitiveContains($0) })
            else { return nil }
            let layer = window[kCGWindowLayer as String] as? Int ?? 0
            guard layer == 0 else { return nil }
            guard let bounds = quartzBounds(window[kCGWindowBounds as String]) else { return nil }
            guard bounds.width >= 400, bounds.height >= 300 else { return nil }
            return GameWindow(owner: owner, quartzBounds: bounds)
        }
        return matches.max { lhs, rhs in
            lhs.quartzBounds.width * lhs.quartzBounds.height
                < rhs.quartzBounds.width * rhs.quartzBounds.height
        }
    }

    private static func quartzBounds(_ raw: Any?) -> CGRect? {
        guard let dict = raw as? [String: Any] else { return nil }
        guard let x = number(dict["X"]), let y = number(dict["Y"]),
              let w = number(dict["Width"]), let h = number(dict["Height"])
        else { return nil }
        return CGRect(x: x, y: y, width: w, height: h)
    }

    private static func number(_ raw: Any?) -> CGFloat? {
        if let value = raw as? CGFloat { return value }
        if let value = raw as? Double { return CGFloat(value) }
        if let value = raw as? Int { return CGFloat(value) }
        if let value = raw as? NSNumber { return CGFloat(truncating: value) }
        return nil
    }
}
