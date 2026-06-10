import Foundation
import Combine

@MainActor
final class InventoryViewModel: ObservableObject {
    @Published private(set) var vehicles: [Vehicle] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var filter = VehicleFilter()
    @Published var sort = VehicleSort()

    private let repository: VehicleRepositoryProtocol

    convenience init() {
        self.init(repository: VehicleRepository.shared)
    }

    init(repository: VehicleRepositoryProtocol) {
        self.repository = repository
    }

    var filteredVehicles: [Vehicle] {
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        let searched = query.isEmpty ? vehicles : vehicles.filter { $0.matchesSearch(query) }
        let filtered = filter.apply(to: searched)
        return sort.apply(to: filtered)
    }

    var availableMakes: [String] {
        Array(Set(vehicles.map(\.make))).sorted()
    }

    var availableBodyStyles: [String] {
        Array(Set(vehicles.map(\.bodyStyle))).sorted { $0.lowercased() < $1.lowercased() }
    }

    func fetchVehicles() async {
        isLoading = true
        errorMessage = nil

        do {
            vehicles = try await repository.fetchVehicles()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func refresh() async {
        if let updated = try? await repository.fetchVehicles() {
            vehicles = updated
        }
    }
}

private extension Vehicle {
    func matchesSearch(_ query: String) -> Bool {
        make.lowercased().contains(query) ||
        model.lowercased().contains(query) ||
        trim.lowercased().contains(query) ||
        String(year).contains(query) ||
        sellingDealership.lowercased().contains(query) ||
        city.lowercased().contains(query) ||
        lot.lowercased().contains(query)
    }
}
