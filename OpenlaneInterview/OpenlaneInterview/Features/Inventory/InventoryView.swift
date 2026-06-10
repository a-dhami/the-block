import SwiftUI

struct InventoryView: View {
    @StateObject private var viewModel = InventoryViewModel()
    @EnvironmentObject private var router: NavigationRouter
    @State private var isFilterPresented = false

    var body: some View {
        InventoryContentView(
            vehicles: viewModel.filteredVehicles,
            isLoading: viewModel.isLoading,
            errorMessage: viewModel.errorMessage,
            searchText: viewModel.searchText,
            filterIsActive: viewModel.filter.isActive,
            onSelectVehicle: router.showVehicleDetail
        )
        .navigationTitle("Vehicles")
        .searchable(text: $viewModel.searchText, prompt: "Make, model, dealer…")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isFilterPresented = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .overlay(alignment: .topTrailing) {
                            if viewModel.filter.isActive {
                                Circle()
                                    .fill(Color.accentColor)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 4, y: -4)
                            }
                        }
                }
                .accessibilityLabel("Filters")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Picker("Sort by", selection: $viewModel.sort.field) {
                        ForEach(VehicleSort.Field.allCases, id: \.self) { field in
                            Text(field.label).tag(field)
                        }
                    }
                    Picker("Order", selection: $viewModel.sort.order) {
                        ForEach(VehicleSort.Order.allCases, id: \.self) { order in
                            Label(order.label, systemImage: order.systemImage).tag(order)
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                }
                .accessibilityLabel("Sort")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Text("\(viewModel.filteredVehicles.count)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .sheet(isPresented: $isFilterPresented) {
            FilterSheetView(
                filter: $viewModel.filter,
                availableMakes: viewModel.availableMakes,
                availableBodyStyles: viewModel.availableBodyStyles
            )
        }
        .task {
            await viewModel.fetchVehicles()
        }
        .onChange(of: router.path) { _, path in
            // Returning to the list: pull in any bid placed on a detail screen.
            if path.isEmpty {
                Task { await viewModel.refresh() }
            }
        }
    }
}

#if DEBUG
#Preview {
    @Previewable @StateObject var router = NavigationRouter()
    InventoryView()
        .environmentObject(router)
}
#endif
