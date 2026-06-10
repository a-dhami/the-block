import SwiftUI

struct VehicleListView: View {
    let vehicles: [Vehicle]
    let onSelectVehicle: (Vehicle) -> Void

    var body: some View {
        List(vehicles) { vehicle in
            Button {
                onSelectVehicle(vehicle)
            } label: {
                VehicleRowView(vehicle: vehicle)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("vehicle-row-\(vehicle.lot)")
        }
    }
}

#if DEBUG
#Preview {
    VehicleListView(vehicles: [.preview], onSelectVehicle: { _ in })
}
#endif
