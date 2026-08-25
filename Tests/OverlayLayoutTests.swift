import XCTest
@testable import HSMacOSTrackerLib

final class OverlayLayoutTests: XCTestCase {
    func testQuartzToAppKitOnPrimary() {
        let quartz = CGRect(x: 100, y: 50, width: 200, height: 80)
        let app = OverlayLayout.appKitRect(quartz: quartz, primaryHeight: 1000)
        XCTAssertEqual(app.origin.x, 100)
        XCTAssertEqual(app.origin.y, 870)
        XCTAssertEqual(app.size, quartz.size)
    }

    func testDockPrefersRightThenClamps() {
        let game = CGRect(x: 100, y: 200, width: 800, height: 600)
        let screen = CGRect(x: 0, y: 0, width: 1400, height: 900)
        let frame = OverlayLayout.dock(game: game, overlaySize: CGSize(width: 300, height: 360), screen: screen)
        XCTAssertEqual(frame.minX, 908)
        XCTAssertEqual(frame.maxY, 800)
    }

    func testDockFallsBackLeftWhenNoRightSpace() {
        let game = CGRect(x: 900, y: 200, width: 1000, height: 600)
        let screen = CGRect(x: 0, y: 0, width: 2000, height: 900)
        let frame = OverlayLayout.dock(game: game, overlaySize: CGSize(width: 300, height: 360), screen: screen)
        XCTAssertEqual(frame.minX, 592)
        XCTAssertLessThan(frame.maxX, game.minX)
    }

    func testScreenContainingExternalMonitor() {
        let builtIn = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let external = CGRect(x: 1440, y: 0, width: 1920, height: 1080)
        let found = OverlayLayout.screenContaining(
            point: CGPoint(x: 2000, y: 100),
            screens: [builtIn, external],
            fallback: builtIn
        )
        XCTAssertEqual(found, external)
    }
}

final class GameWindowLocatorTests: XCTestCase {
    func testPicksLargestHearthstoneWindow() {
        let small: [String: Any] = [
            kCGWindowOwnerName as String: "Hearthstone",
            kCGWindowLayer as String: 0,
            kCGWindowBounds as String: ["X": 0, "Y": 0, "Width": 500, "Height": 400],
        ]
        let large: [String: Any] = [
            kCGWindowOwnerName as String: "Hearthstone",
            kCGWindowLayer as String: 0,
            kCGWindowBounds as String: ["X": 10, "Y": 20, "Width": 1280, "Height": 720],
        ]
        let other: [String: Any] = [
            kCGWindowOwnerName as String: "Safari",
            kCGWindowLayer as String: 0,
            kCGWindowBounds as String: ["X": 0, "Y": 0, "Width": 2000, "Height": 1200],
        ]
        let found = GameWindowLocator.locate(windows: [small, large, other])
        XCTAssertEqual(found?.quartzBounds.width, 1280)
    }

    func testUnknownWhenMissing() {
        XCTAssertNil(GameWindowLocator.locate(windows: [[
            kCGWindowOwnerName as String: "Finder",
            kCGWindowLayer as String: 0,
            kCGWindowBounds as String: ["X": 0, "Y": 0, "Width": 800, "Height": 600],
        ]]))
    }
}
