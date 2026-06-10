import Foundation

// The app's notion of "now." Pinned to a fixed instant during UI testing so that
// time-dependent state (auction status, the live window) is deterministic; otherwise
// it's the real system clock.
enum AppDate {
    static var now: Date {
        isUITesting ? uiTestNow : Date()
    }

    private static let isUITesting = ProcessInfo.processInfo.arguments.contains("-uitesting")

    // Mid-afternoon on the anchor day, so auctions scheduled earlier that day read as
    // Live and there's a clear before/after for the bidding flow.
    private static let uiTestNow: Date = Calendar.current.date(
        bySettingHour: 15, minute: 0, second: 0, of: Vehicle.auctionAnchorDay
    ) ?? Date()
}
