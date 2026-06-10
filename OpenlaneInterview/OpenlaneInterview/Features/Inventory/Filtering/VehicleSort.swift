import Foundation

struct VehicleSort: Equatable {
    var field: Field = .auctionTiming
    var order: Order = .ascending

    enum Field: CaseIterable, Hashable {
        case auctionTiming, year, currentBid

        var label: String {
            switch self {
            case .auctionTiming: "Auction"
            case .year:          "Year"
            case .currentBid:    "Current Bid"
            }
        }
    }

    enum Order: CaseIterable, Hashable {
        case ascending, descending

        var label: String       { self == .ascending ? "Ascending"  : "Descending" }
        var systemImage: String { self == .ascending ? "arrow.up"   : "arrow.down" }
    }

    func apply(to vehicles: [Vehicle], now: Date = AppDate.now) -> [Vehicle] {
        vehicles.sorted { a, b in
            // Ended auctions always sink to the bottom, regardless of field or order.
            // A buyer can't act on them, so they shouldn't lead the list.
            let aEnded = a.auctionStatus(now: now) == .ended
            let bEnded = b.auctionStatus(now: now) == .ended
            if aEnded != bEnded {
                return !aEnded
            }

            let comparison = compare(a, b, now: now)
            guard comparison != .orderedSame else {
                return a.id < b.id
            }

            return order == .ascending ? comparison == .orderedAscending : comparison == .orderedDescending
        }
    }

    private func compare(_ a: Vehicle, _ b: Vehicle, now: Date) -> ComparisonResult {
        switch field {
        case .auctionTiming:
            return a.normalizedAuctionStart(now: now).compare(b.normalizedAuctionStart(now: now))
        case .year:
            return compare(a.year, b.year)
        case .currentBid:
            return compare(a.currentBid ?? a.startingBid, b.currentBid ?? b.startingBid)
        }
    }

    private func compare<T: Comparable>(_ a: T, _ b: T) -> ComparisonResult {
        if a < b { return .orderedAscending }
        if a > b { return .orderedDescending }
        return .orderedSame
    }
}
