import Foundation

/// Quartz window space (primary top-left, y down) → AppKit (primary bottom-left, y up).
public enum OverlayLayout {
    public static func appKitRect(quartz: CGRect, primaryHeight: CGFloat) -> CGRect {
        CGRect(
            x: quartz.origin.x,
            y: primaryHeight - quartz.origin.y - quartz.height,
            width: quartz.width,
            height: quartz.height
        )
    }

    /// Dock click-through panel to the right of the game window. Fall back to left. Clamp to that screen.
    public static func dock(
        game: CGRect,
        overlaySize: CGSize,
        screen: CGRect,
        gap: CGFloat = 8
    ) -> CGRect {
        var frame = CGRect(
            x: game.maxX + gap,
            y: game.maxY - overlaySize.height,
            width: overlaySize.width,
            height: overlaySize.height
        )
        if frame.maxX > screen.maxX {
            frame.origin.x = game.minX - overlaySize.width - gap
        }
        if frame.minX < screen.minX {
            frame.origin.x = screen.minX + gap
        }
        if frame.minY < screen.minY {
            frame.origin.y = screen.minY + gap
        }
        if frame.maxY > screen.maxY {
            frame.origin.y = screen.maxY - overlaySize.height - gap
        }
        return frame
    }

    public static func screenContaining(point: CGPoint, screens: [CGRect], fallback: CGRect) -> CGRect {
        screens.first { $0.contains(point) } ?? fallback
    }
}
