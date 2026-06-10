import Foundation

struct VehicleFilter: Equatable {
    var selectedMakes: Set<String> = []
    var selectedBodyStyles: Set<String> = []

    var isActive: Bool {
        !selectedMakes.isEmpty || !selectedBodyStyles.isEmpty
    }

    mutating func reset() {
        self = VehicleFilter()
    }

    func apply(to vehicles: [Vehicle]) -> [Vehicle] {
        guard isActive else { return vehicles }
        return vehicles.filter { vehicle in
            (selectedMakes.isEmpty || selectedMakes.contains(vehicle.make)) &&
            (selectedBodyStyles.isEmpty || selectedBodyStyles.contains(vehicle.bodyStyle))
        }
    }
}
