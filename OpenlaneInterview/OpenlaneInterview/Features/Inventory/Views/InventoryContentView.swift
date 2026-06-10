import SwiftUI

struct InventoryContentView: View {
    let vehicles: [Vehicle]
    let isLoading: Bool
    let errorMessage: String?
    let searchText: String
    let filterIsActive: Bool
    let onSelectVehicle: (Vehicle) -> Void

    var body: some View {
        if isLoading {
            ProgressView("Loading vehicles")
        } else if let errorMessage {
            ContentUnavailableView(
                "Unable to Load Vehicles",
                systemImage: "exclamationmark.triangle",
                description: Text(errorMessage)
            )
        } else if vehicles.isEmpty {
            emptyView
        } else {
            VehicleListView(
                vehicles: vehicles,
                onSelectVehicle: onSelectVehicle
            )
        }
    }

    @ViewBuilder
    private var emptyView: some View {
        if !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            ContentUnavailableView.search(text: searchText)
        } else if filterIsActive {
            ContentUnavailableView(
                "No Matching Vehicles",
                systemImage: "car.fill",
                description: Text("Try adjusting your filters.")
            )
        } else {
            ContentUnavailableView("No Vehicles", systemImage: "car.fill")
        }
    }
}

#if DEBUG
#Preview("Loaded") {
    InventoryContentView(
        vehicles: [.preview],
        isLoading: false,
        errorMessage: nil,
        searchText: "",
        filterIsActive: false,
        onSelectVehicle: { _ in }
    )
}

#Preview("Empty") {
    InventoryContentView(
        vehicles: [],
        isLoading: false,
        errorMessage: nil,
        searchText: "",
        filterIsActive: false,
        onSelectVehicle: { _ in }
    )
}
#endif
