import CoreGraphics
import Foundation

public enum ScreenCaptureGate {
    /// Thin fail-closed gate for step-2 OCR. No capture stream in the spike.
    public static func canCapture() -> Bool {
        CGPreflightScreenCaptureAccess()
    }

    public static func statusLabel() -> String {
        canCapture() ? "granted" : "denied (manual input only)"
    }
}
