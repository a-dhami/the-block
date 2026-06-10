import Testing
import Foundation
@testable import OpenlaneInterview

@MainActor
struct OpenlaneInterviewTests {

    @Test func mockVehicleAPIClientFetchesBundledVehicles() async throws {
        let apiClient = MockVehicleAPIClient()

        let vehicles = try await apiClient.fetchVehicles()

        #expect(vehicles.count == 200)
        #expect(vehicles.first?.lot == "A-0001")
        #expect(vehicles.first?.make == "Mazda")
        #expect(vehicles.first?.currentBid == 21000)
        #expect(vehicles.contains { $0.currentBid == nil })
    }

    @Test func vehicleRepositoryCachesVehicles() async throws {
        let vehicle = Vehicle.fixture(id: "vehicle-1")
        let apiClient = FakeVehicleAPIClient(vehicles: [vehicle])
        let repository = VehicleRepository(apiClient: apiClient)

        let vehicles = try await repository.fetchVehicles()
        _ = try await repository.fetchVehicles()

        #expect(vehicles == [vehicle])
        #expect(apiClient.fetchCount == 1)
    }

    @Test func inventoryViewModelSearchesAndFiltersVehicles() async {
        let mazda = Vehicle.fixture(
            id: "mazda-live",
            make: "Mazda",
            model: "CX-5",
            city: "Mississauga",
            conditionGrade: 4.0,
            currentBid: 21000,
            bidCount: 11
        )
        let ford = Vehicle.fixture(
            id: "ford-ended",
            make: "Ford",
            model: "Escape",
            city: "Toronto",
            conditionGrade: 2.8,
            currentBid: nil,
            bidCount: 0
        )
        let viewModel = InventoryViewModel(
            repository: FakeVehicleRepository(vehicles: [mazda, ford])
        )

        await viewModel.fetchVehicles()
        viewModel.searchText = "mississauga"
        viewModel.filter.selectedMakes = ["Mazda"]

        #expect(viewModel.filteredVehicles == [mazda])
    }

    @Test func inventoryRefreshReflectsBidsPlacedElsewhere() async {
        let vehicle = Vehicle.fixture(id: "bid-target", startingBid: 20000)
        let repository = VehicleRepository(apiClient: FakeVehicleAPIClient(vehicles: [vehicle]))
        let viewModel = InventoryViewModel(repository: repository)

        await viewModel.fetchVehicles()
        _ = try? await repository.placeBid(vehicleId: vehicle.id, amount: 21000)
        await viewModel.refresh()

        #expect(viewModel.vehicles.first?.currentBid == 21000)
    }

    @Test func vehicleFilterMatchesMultipleCriteria() {
        let liveSuv = Vehicle.fixture(
            id: "live-suv",
            make: "Mazda",
            bodyStyle: "SUV",
            fuelType: "gasoline",
            year: 2025,
            conditionGrade: 4.1,
            currentBid: 22000,
            bidCount: 3
        )
        let lowGradeTruck = Vehicle.fixture(
            id: "low-grade-truck",
            make: "Ram",
            bodyStyle: "truck",
            fuelType: "diesel",
            year: 2019,
            conditionGrade: 2.7
        )
        let filter = VehicleFilter(
            selectedMakes: ["Mazda"],
            selectedBodyStyles: ["SUV"]
        )

        #expect(filter.apply(to: [lowGradeTruck, liveSuv]) == [liveSuv])
    }

    @Test func vehicleSortUsesStableTieBreaker() {
        let olderVehicle = Vehicle.fixture(id: "vehicle-a", year: 2024, startingBid: 20000)
        let newerVehicle = Vehicle.fixture(id: "vehicle-b", year: 2024, startingBid: 20000)
        let sort = VehicleSort(field: .year, order: .descending)

        let sortedVehicles = sort.apply(to: [newerVehicle, olderVehicle])

        #expect(sortedVehicles.map(\.id) == ["vehicle-a", "vehicle-b"])
    }

    @Test func vehicleSortOrdersByCurrentBid() {
        let lowBid = Vehicle.fixture(id: "low", currentBid: 15000, bidCount: 1)
        let highBid = Vehicle.fixture(id: "high", currentBid: 28000, bidCount: 4)
        let sort = VehicleSort(field: .currentBid, order: .descending)

        let sortedVehicles = sort.apply(to: [lowBid, highBid])

        #expect(sortedVehicles.map(\.id) == ["high", "low"])
    }

    @Test func vehicleSortKeepsEndedAuctionsLast() {
        let calendar = Calendar.current
        let now = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: Date())!
        func anchorDay(offset: Int, hour: Int) -> Date {
            let day = calendar.date(byAdding: .day, value: offset, to: Vehicle.auctionAnchorDay)!
            return calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day)!
        }

        // Ended has the earliest start, so ascending timing would normally lead with it.
        let ended = Vehicle.fixture(id: "ended", auctionStart: anchorDay(offset: -1, hour: 9))
        let live = Vehicle.fixture(id: "live", auctionStart: anchorDay(offset: 0, hour: 11), currentBid: 15000, bidCount: 2)
        let upcoming = Vehicle.fixture(id: "upcoming", auctionStart: anchorDay(offset: 1, hour: 9))
        let sort = VehicleSort(field: .auctionTiming, order: .ascending)

        let sorted = sort.apply(to: [ended, live, upcoming], now: now)

        #expect(sorted.map(\.id) == ["live", "upcoming", "ended"])
    }

    @Test func auctionStatusFollowsTimeOfDayWindow() {
        let calendar = Calendar.current
        let now = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: Date())!
        // Auctions on the anchor day map onto today at their original hour.
        func anchorDayAt(_ hour: Int) -> Date {
            calendar.date(bySettingHour: hour, minute: 0, second: 0, of: Vehicle.auctionAnchorDay)!
        }

        let upcoming = Vehicle.fixture(auctionStart: anchorDayAt(18)) // starts later today
        let live = Vehicle.fixture(auctionStart: anchorDayAt(14))     // started an hour ago
        let ended = Vehicle.fixture(auctionStart: anchorDayAt(9))     // started this morning

        #expect(upcoming.auctionStatus(now: now).isUpcoming)
        #expect(live.auctionStatus(now: now) == .live)
        #expect(ended.auctionStatus(now: now) == .ended)
    }

    @Test func auctionStatusSpreadsAcrossDaysFromAnchor() {
        let calendar = Calendar.current
        let now = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: Date())!
        func anchorDay(offset: Int, hour: Int) -> Date {
            let day = calendar.date(byAdding: .day, value: offset, to: Vehicle.auctionAnchorDay)!
            return calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day)!
        }

        // A day before the anchor lands fully in the past, so it's Ended whatever the hour.
        let dayBefore = Vehicle.fixture(auctionStart: anchorDay(offset: -1, hour: 23))
        // A day after the anchor lands in the future, so it's Upcoming whatever the hour.
        let dayAfter = Vehicle.fixture(auctionStart: anchorDay(offset: 1, hour: 1))

        #expect(dayBefore.auctionStatus(now: now) == .ended)
        #expect(dayAfter.auctionStatus(now: now).isUpcoming)
    }

    @Test func auctionStatusIgnoresBidsAndUsesTheLiveWindow() {
        let calendar = Calendar.current
        let now = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: Vehicle.auctionAnchorDay)!
        func anchorDayAt(_ hour: Int) -> Date {
            calendar.date(bySettingHour: hour, minute: 0, second: 0, of: Vehicle.auctionAnchorDay)!
        }

        // Bids don't decide status: a started auction is Live only within its window,
        // then Ended, even with active bids in the data.
        let liveWithinWindow = Vehicle.fixture(auctionStart: anchorDayAt(11), currentBid: 25000, bidCount: 7)
        let endedPastWindow = Vehicle.fixture(auctionStart: anchorDayAt(9), currentBid: 25000, bidCount: 7)

        #expect(liveWithinWindow.auctionStatus(now: now) == .live)
        #expect(endedPastWindow.auctionStatus(now: now) == .ended)
    }

    @Test func auctionStatusTreatsFutureBidVehiclesAsUpcoming() {
        // Regression: a bid in the data must not force a future-dated auction to Live.
        let calendar = Calendar.current
        let now = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: Date())!
        let futureDay = calendar.date(byAdding: .day, value: 1, to: Vehicle.auctionAnchorDay)!
        let futureStart = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: futureDay)!
        let bidVehicle = Vehicle.fixture(auctionStart: futureStart, currentBid: 25000, bidCount: 7)

        #expect(bidVehicle.auctionStatus(now: now).isUpcoming)
    }

    @Test func vehicleDetailViewModelHidesLiveBidDataForUpcomingAuctions() {
        let calendar = Calendar.current
        let futureDay = calendar.date(byAdding: .day, value: 1, to: Vehicle.auctionAnchorDay)!
        let futureStart = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: futureDay)!
        // Carries stray bid data but hasn't opened, so it should read as the opening price.
        let vehicle = Vehicle.fixture(
            auctionStart: futureStart,
            startingBid: 18000,
            currentBid: 22000,
            bidCount: 4
        )
        let viewModel = VehicleDetailViewModel(
            vehicle: vehicle,
            repository: FakeVehicleRepository(vehicles: [vehicle])
        )

        let titles = viewModel.auctionRows.map(\.title)
        #expect(!titles.contains("Current bid"))
        #expect(!titles.contains("Bid count"))
        #expect(titles.contains("Starting bid"))
        #expect(viewModel.bidLabel == "Starting bid")
        #expect(viewModel.activeBidText == 18000.priceText)
    }

    @Test func vehicleDetailViewModelPlacesDefaultBidOptimistically() {
        let vehicle = Vehicle.fixture(id: "bid-target", startingBid: 20000)
        let repository = FakeVehicleRepository(vehicles: [vehicle])
        let viewModel = VehicleDetailViewModel(vehicle: vehicle, repository: repository)

        viewModel.placeBid()

        #expect(viewModel.vehicle.currentBid == 20050)
        #expect(viewModel.vehicle.bidCount == 1)
        #expect(viewModel.bidIncrementText.isEmpty)
    }

    @Test func vehicleDetailViewModelAdoptsServerStateAfterConfirming() async {
        let vehicle = Vehicle.fixture(id: "bid-target", startingBid: 20000)
        // The server reports a higher bid and count than our optimistic guess,
        // e.g. another buyer bid in the meantime. The view model should adopt it.
        var serverVehicle = vehicle
        serverVehicle.currentBid = 22000
        serverVehicle.bidCount = 5
        let viewModel = VehicleDetailViewModel(
            vehicle: vehicle,
            repository: StubBidRepository(result: serverVehicle)
        )

        viewModel.placeBid()
        #expect(viewModel.vehicle.currentBid == 20050) // optimistic

        await viewModel.confirmBid(20050)
        #expect(viewModel.vehicle.currentBid == 22000) // reconciled with the server
        #expect(viewModel.vehicle.bidCount == 5)
    }

    @Test func vehicleDetailViewModelSanitizesCustomBidIncrement() {
        let vehicle = Vehicle.fixture(id: "custom-bid-target", startingBid: 20000)
        let repository = FakeVehicleRepository(vehicles: [vehicle])
        let viewModel = VehicleDetailViewModel(vehicle: vehicle, repository: repository)

        viewModel.bidIncrementText = "$1,250abc"
        viewModel.placeBid()

        #expect(viewModel.vehicle.currentBid == 21250)
        #expect(viewModel.bidIncrementText.isEmpty)
    }

    @Test func vehicleDetailViewModelReportsReserveStatus() {
        let belowReserve = Vehicle.fixture(reservePrice: 29000, currentBid: 21000, bidCount: 5)
        let metReserve = Vehicle.fixture(reservePrice: 29000, currentBid: 30000, bidCount: 9)
        let repository = FakeVehicleRepository(vehicles: [belowReserve, metReserve])

        let belowViewModel = VehicleDetailViewModel(vehicle: belowReserve, repository: repository)
        let metViewModel = VehicleDetailViewModel(vehicle: metReserve, repository: repository)

        #expect(belowViewModel.auctionRows.contains { $0.title == "Reserve" && $0.value == "Not met" })
        #expect(metViewModel.auctionRows.contains { $0.title == "Reserve" && $0.value == "Met" })
    }

    @Test func renderableImageURLAddsExtensionForPlaceholdImages() throws {
        let url = try #require(URL(string: "https://placehold.co/900x600?text=Supra"))

        #expect(url.renderableImageURL.absoluteString == "https://placehold.co/900x600.png?text=Supra")
    }

}

private final class FakeVehicleAPIClient: VehicleAPIClientProtocol {
    private var vehicles: [Vehicle]
    private(set) var fetchCount = 0

    init(vehicles: [Vehicle]) {
        self.vehicles = vehicles
    }

    func fetchVehicles() async throws -> [Vehicle] {
        fetchCount += 1
        return vehicles
    }

    func placeBid(vehicleId: String, amount: Int) async throws -> Vehicle {
        guard let index = vehicles.firstIndex(where: { $0.id == vehicleId }) else {
            throw TestVehicleError.vehicleNotFound(vehicleId)
        }

        let updated = vehicles[index].withUpdatedBid(amount)
        vehicles[index] = updated
        return updated
    }
}

private final class FakeVehicleRepository: VehicleRepositoryProtocol {
    private var vehicles: [Vehicle]

    init(vehicles: [Vehicle]) {
        self.vehicles = vehicles
    }

    func fetchVehicles() async throws -> [Vehicle] {
        vehicles
    }

    func placeBid(vehicleId: String, amount: Int) async throws -> Vehicle {
        guard let index = vehicles.firstIndex(where: { $0.id == vehicleId }) else {
            throw TestVehicleError.vehicleNotFound(vehicleId)
        }

        let updated = vehicles[index].withUpdatedBid(amount)
        vehicles[index] = updated
        return updated
    }
}

private final class StubBidRepository: VehicleRepositoryProtocol {
    private let result: Vehicle

    init(result: Vehicle) {
        self.result = result
    }

    func fetchVehicles() async throws -> [Vehicle] {
        [result]
    }

    func placeBid(vehicleId: String, amount: Int) async throws -> Vehicle {
        result
    }
}

private enum TestVehicleError: Error {
    case vehicleNotFound(String)
}

private let testDatasetEpoch: Date = {
    var components = DateComponents()
    components.year = 2026
    components.month = 3
    components.day = 31
    components.hour = 9
    return Calendar.current.date(from: components) ?? Date()
}()

private extension AuctionStatus {
    var isUpcoming: Bool {
        if case .upcoming = self { return true }
        return false
    }
}

private extension Vehicle {
    static func fixture(
        id: String = "vehicle-1",
        make: String = "Toyota",
        model: String = "RAV4",
        bodyStyle: String = "SUV",
        fuelType: String = "gasoline",
        year: Int = 2024,
        city: String = "Toronto",
        auctionStart: Date = testDatasetEpoch,
        startingBid: Int = 20000,
        reservePrice: Int? = nil,
        conditionGrade: Double = 4.2,
        currentBid: Int? = nil,
        bidCount: Int = 0
    ) -> Vehicle {
        Vehicle(
            id: id,
            vin: "TESTVIN1234567890",
            year: year,
            make: make,
            model: model,
            trim: "XLE",
            bodyStyle: bodyStyle,
            exteriorColor: "Blue",
            interiorColor: "Black",
            engine: "2.5L I4",
            transmission: "automatic",
            drivetrain: "AWD",
            odometerKm: 12000,
            fuelType: fuelType,
            conditionGrade: conditionGrade,
            conditionReport: "Clean condition.",
            damageNotes: [],
            titleStatus: "clean",
            province: "Ontario",
            city: city,
            auctionStart: auctionStart,
            startingBid: startingBid,
            reservePrice: reservePrice,
            buyNowPrice: nil,
            images: [],
            sellingDealership: "Test Dealer",
            lot: "A-TEST",
            currentBid: currentBid,
            bidCount: bidCount
        )
    }
}
