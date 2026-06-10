@MainActor
final class VehicleRepository: VehicleRepositoryProtocol {
    static let shared = VehicleRepository()

    private let apiClient: VehicleAPIClientProtocol
    private var cachedVehicles: [Vehicle]?

    init() {
        self.apiClient = MockVehicleAPIClient()
    }

    init(apiClient: VehicleAPIClientProtocol) {
        self.apiClient = apiClient
    }

    func fetchVehicles() async throws -> [Vehicle] {
        if let cachedVehicles {
            return cachedVehicles
        }

        let vehicles = try await apiClient.fetchVehicles()
        cachedVehicles = vehicles
        return vehicles
    }

    func placeBid(vehicleId: String, amount: Int) async throws -> Vehicle {
        let updated = try await apiClient.placeBid(vehicleId: vehicleId, amount: amount)
        if let index = cachedVehicles?.firstIndex(where: { $0.id == vehicleId }) {
            cachedVehicles?[index] = updated
        }
        return updated
    }
}
