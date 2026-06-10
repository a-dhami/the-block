import Combine

final class NavigationRouter: ObservableObject {
    @Published var path: [AppRoute] = []

    func showVehicleDetail(_ vehicle: Vehicle) {
        path.append(.vehicleDetail(vehicle))
    }
}
