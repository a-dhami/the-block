import Foundation

enum AuctionStatus: Equatable {
    case upcoming(start: Date)
    case live
    case ended
}

extension AuctionStatus {
    var label: String {
        switch self {
        case .live:
            return "Live"
        case .ended:
            return "Ended"
        case .upcoming(let start):
            return countdown(to: start)
        }
    }

    var isLive: Bool {
        if case .live = self { return true }
        return false
    }
}

extension Vehicle {
    // A busy mid-dataset day, mapped onto today: earlier dataset days land in the past
    // (Ended) and later days in the future (Upcoming), so the list shows a full mix of
    // auctions opening and closing as the day goes on. Re-spreads fresh each day.
    static let auctionAnchorDay: Date = {
        var components = DateComponents()
        components.year = 2026
        components.month = 4
        components.day = 3
        return Calendar.current.date(from: components) ?? .distantPast
    }()

    func normalizedAuctionStart(now: Date = AppDate.now) -> Date {
        let calendar = Calendar.current

        // How many whole days is this auction from the anchor day?
        let auctionDay = calendar.startOfDay(for: auctionStart)
        let anchorDay = calendar.startOfDay(for: Self.auctionAnchorDay)
        let dayOffset = calendar.dateComponents([.day], from: anchorDay, to: auctionDay).day ?? 0

        // Apply that same offset to today, then restore the original time of day.
        let shiftedDay = calendar.date(byAdding: .day, value: dayOffset, to: calendar.startOfDay(for: now)) ?? now
        let timeOfDay = calendar.dateComponents([.hour, .minute, .second], from: auctionStart)
        return calendar.date(
            bySettingHour: timeOfDay.hour ?? 0,
            minute: timeOfDay.minute ?? 0,
            second: timeOfDay.second ?? 0,
            of: shiftedDay
        ) ?? shiftedDay
    }

    func auctionStatus(now: Date = AppDate.now) -> AuctionStatus {
        // Status comes purely from the normalized date and a fixed live window.
        // The current_bid and bid_count fields are price and history only. They
        // don't decide whether an auction is open.
        let start = normalizedAuctionStart(now: now)
        let elapsed = now.timeIntervalSince(start)
        switch elapsed {
        case ..<0:                       return .upcoming(start: start)
        case 0..<liveAuctionWindow:      return .live
        default:                         return .ended
        }
    }

    // The bid figure to show for this vehicle. An auction that hasn't opened shows its
    // starting price; otherwise the current bid, falling back to the starting bid.
    func displayBid(now: Date = AppDate.now) -> Int {
        if case .upcoming = auctionStatus(now: now) { return startingBid }
        return currentBid ?? startingBid
    }
}

// How long an auction stays Live after it opens before it's considered Ended.
private let liveAuctionWindow: TimeInterval = 2 * 3600

private func countdown(to date: Date) -> String {
    let interval = max(0, date.timeIntervalSinceNow)
    let days    = Int(interval / 86400)
    let hours   = Int(interval.truncatingRemainder(dividingBy: 86400) / 3600)
    let minutes = Int(interval.truncatingRemainder(dividingBy: 3600) / 60)

    switch days {
    case 1...: return hours  > 0 ? "in \(days)d \(hours)h"  : "in \(days)d"
    case 0 where hours > 0:
               return minutes > 0 ? "in \(hours)h \(minutes)m" : "in \(hours)h"
    default:   return "in \(max(1, minutes))m"
    }
}
