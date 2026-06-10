import SwiftUI

struct ContentView: View {
    @StateObject private var router = NavigationRouter()

    var body: some View {
        NavigationStack(path: $router.path) {
            InventoryView()
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .vehicleDetail(let vehicle):
                        VehicleDetailView(vehicle: vehicle)
                    }
                }
        }
        .environmentObject(router)
    }
}
