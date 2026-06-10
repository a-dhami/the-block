@MainActor
protocol VehicleRepositoryProtocol {
    func fetchVehicles() async throws -> [Vehicle]
    func placeBid(vehicleId: String, amount: Int) async throws -> Vehicle
}
