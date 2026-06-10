import Foundation

private enum MockVehicleAPIClientError: LocalizedError {
    case missingVehicles
    case vehicleNotFound(String)

    var errorDescription: String? {
        switch self {
        case .missingVehicles:
            "Could not load vehicles."
        case .vehicleNotFound(let id):
            "No vehicle found with id \(id)."
        }
    }
}

@MainActor
final class MockVehicleAPIClient: VehicleAPIClientProtocol {
    private let fileName: String
    private let bundle: Bundle
    private let decoder: JSONDecoder
    private var loadedVehicles: [Vehicle]?

    init(
        fileName: String = "vehicles",
        bundle: Bundle = .main,
        decoder: JSONDecoder? = nil
    ) {
        self.fileName = fileName
        self.bundle = bundle
        self.decoder = decoder ?? .vehicleDecoder
    }

    func fetchVehicles() async throws -> [Vehicle] {
        if let loadedVehicles {
            return loadedVehicles
        }

        guard let url = resourceURL else {
            throw MockVehicleAPIClientError.missingVehicles
        }

        let data = try Data(contentsOf: url)
        let vehicles = try decoder.decode([Vehicle].self, from: data)
        loadedVehicles = vehicles
        return vehicles
    }

    func placeBid(vehicleId: String, amount: Int) async throws -> Vehicle {
        var vehicles = try await fetchVehicles()
        guard let index = vehicles.firstIndex(where: { $0.id == vehicleId }) else {
            throw MockVehicleAPIClientError.vehicleNotFound(vehicleId)
        }

        let updated = vehicles[index].withUpdatedBid(amount)
        vehicles[index] = updated
        loadedVehicles = vehicles
        return updated
    }

    private var resourceURL: URL? {
        bundle.url(forResource: fileName, withExtension: "json")
            ?? bundle.url(forResource: fileName, withExtension: "json", subdirectory: "Resources")
    }
}

private extension JSONDecoder {
    static var vehicleDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .formatted(.vehicleAuctionDateFormatter)
        return decoder
    }
}

private extension DateFormatter {
    static var vehicleAuctionDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter
    }
}
