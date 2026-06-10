import Combine
import Foundation

@MainActor
final class VehicleDetailViewModel: ObservableObject {
    @Published var bidIncrementText = "" {
        didSet {
            sanitizeBidIncrement()
        }
    }
    @Published private(set) var vehicle: Vehicle

    private let repository: VehicleRepositoryProtocol
    private let defaultBidIncrement = 50
    private let maxBidIncrementDigits = 5

    convenience init(vehicle: Vehicle) {
        self.init(vehicle: vehicle, repository: VehicleRepository.shared)
    }

    init(vehicle: Vehicle, repository: VehicleRepositoryProtocol) {
        self.vehicle = vehicle
        self.repository = repository
    }

    var navigationTitle: String {
        "\(vehicle.make) \(vehicle.model)"
    }

    var vehicleTitle: String {
        "\(vehicle.year) \(vehicle.make) \(vehicle.model)"
    }

    var trimLotText: String {
        "\(vehicle.trim) - \(vehicle.lot)"
    }

    var imageURLs: [URL] {
        vehicle.images.map(\.renderableImageURL)
    }

    var firstImageURL: URL? {
        vehicle.images.first?.renderableImageURL
    }

    var activeBidText: String {
        activeBid.priceText
    }

    func auctionStatusLabel(now: Date = AppDate.now) -> String {
        vehicle.auctionStatus(now: now).label
    }

    func isLive(now: Date = AppDate.now) -> Bool {
        vehicle.auctionStatus(now: now).isLive
    }

    // Label for the headline bid figure: an auction that hasn't opened shows its
    // opening price, so we call it the starting bid rather than the current bid.
    var bidLabel: String {
        isUpcoming() ? "Starting bid" : "Current bid"
    }

    var auctionRows: [VehicleDetailRowData] {
        // Before an auction opens there's no live bidding, so show only the opening
        // price, not a "current bid" or bid count that would imply activity.
        var rows: [VehicleDetailRowData]
        if isUpcoming() {
            rows = [
                VehicleDetailRowData(title: "Starting bid", value: vehicle.startingBid.priceText)
            ]
        } else {
            rows = [
                VehicleDetailRowData(title: "Current bid", value: activeBidText),
                VehicleDetailRowData(title: "Starting bid", value: vehicle.startingBid.priceText),
                VehicleDetailRowData(title: "Bid count", value: "\(vehicle.bidCount)")
            ]
        }

        if let reservePrice = vehicle.reservePrice {
            let met = activeBid >= reservePrice
            rows.append(
                VehicleDetailRowData(
                    title: "Reserve",
                    value: met ? "Met" : "Not met"
                )
            )
        }

        if let buyNowPrice = vehicle.buyNowPrice {
            rows.append(VehicleDetailRowData(title: "Buy now", value: buyNowPrice.priceText))
        }

        return rows
    }

    var specRows: [VehicleDetailRowData] {
        [
            VehicleDetailRowData(title: "VIN", value: vehicle.vin),
            VehicleDetailRowData(title: "Odometer", value: "\(vehicle.odometerKm.formatted()) km"),
            VehicleDetailRowData(title: "Engine", value: vehicle.engine),
            VehicleDetailRowData(title: "Transmission", value: vehicle.transmission.capitalized),
            VehicleDetailRowData(title: "Drivetrain", value: vehicle.drivetrain),
            VehicleDetailRowData(title: "Fuel", value: vehicle.fuelType.capitalized),
            VehicleDetailRowData(title: "Exterior", value: vehicle.exteriorColor),
            VehicleDetailRowData(title: "Interior", value: vehicle.interiorColor)
        ]
    }

    var conditionRows: [VehicleDetailRowData] {
        [
            VehicleDetailRowData(
                title: "Grade",
                value: vehicle.conditionGrade.formatted(.number.precision(.fractionLength(1)))
            ),
            VehicleDetailRowData(title: "Title", value: vehicle.titleStatus.capitalized)
        ]
    }

    var conditionReport: String {
        vehicle.conditionReport
    }

    var damageNotes: [String] {
        vehicle.damageNotes
    }

    var sellingDealership: String {
        vehicle.sellingDealership
    }

    var sellerLocation: String {
        "\(vehicle.city), \(vehicle.province)"
    }

    var footerBidLabel: String {
        hasTypedIncrement ? "Bid total" : "Current bid"
    }

    var footerBidText: String {
        guard hasTypedIncrement, let bidAmountToPlace else {
            return activeBidText
        }

        return bidAmountToPlace.priceText
    }

    var bidButtonTitle: String {
        hasTypedIncrement ? "Bid" : "Bid +$50"
    }

    var canPlaceBid: Bool {
        bidAmountToPlace != nil
    }

    func placeBid() {
        guard let bidAmountToPlace, bidAmountToPlace > activeBid else { return }

        vehicle = vehicle.withUpdatedBid(bidAmountToPlace)
        bidIncrementText = ""

        Task { await confirmBid(bidAmountToPlace) }
    }

    func confirmBid(_ amount: Int) async {
        if let updated = try? await repository.placeBid(vehicleId: vehicle.id, amount: amount) {
            vehicle = updated
        }
    }

    private func isUpcoming(now: Date = AppDate.now) -> Bool {
        if case .upcoming = vehicle.auctionStatus(now: now) { return true }
        return false
    }

    private var activeBid: Int {
        vehicle.displayBid()
    }

    private var hasTypedIncrement: Bool {
        !bidIncrementText.isEmpty
    }

    private var customIncrement: Int? {
        guard hasTypedIncrement else { return nil }
        return Int(bidIncrementText).flatMap { $0 > 0 ? $0 : nil }
    }

    private var bidAmountToPlace: Int? {
        if hasTypedIncrement && customIncrement == nil { return nil } // typed but invalid
        return activeBid + (customIncrement ?? defaultBidIncrement)
    }

    private func sanitizeBidIncrement() {
        let digits = String(bidIncrementText.filter(\.isNumber).prefix(maxBidIncrementDigits))

        if digits != bidIncrementText {
            bidIncrementText = digits
        }
    }
}

struct VehicleDetailRowData: Identifiable {
    let title: String
    let value: String

    var id: String { title }
}
