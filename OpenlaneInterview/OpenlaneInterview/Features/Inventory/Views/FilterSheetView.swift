import SwiftUI

struct FilterSheetView: View {
    @Binding var filter: VehicleFilter
    let availableMakes: [String]
    let availableBodyStyles: [String]

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                multiSelectSection("Make", items: availableMakes, selection: $filter.selectedMakes)

                multiSelectSection(
                    "Body Style",
                    items: availableBodyStyles,
                    selection: $filter.selectedBodyStyles,
                    displayName: formattedLabel
                )
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Clear") { filter.reset() }
                        .disabled(!filter.isActive)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    @ViewBuilder
    private func multiSelectSection(
        _ title: String,
        items: [String],
        selection: Binding<Set<String>>,
        displayName: @escaping (String) -> String = { $0 }
    ) -> some View {
        if !items.isEmpty {
            Section(title) {
                ForEach(items, id: \.self) { item in
                    Toggle(
                        displayName(item),
                        isOn: Binding(
                            get: { selection.wrappedValue.contains(item) },
                            set: { isSelected in
                                if isSelected {
                                    selection.wrappedValue.insert(item)
                                } else {
                                    selection.wrappedValue.remove(item)
                                }
                            }
                        )
                    )
                }
            }
        }
    }

    private func formattedLabel(_ value: String) -> String {
        guard !value.isEmpty, value.contains(where: \.isLowercase) else {
            return value
        }
        return value.prefix(1).uppercased() + value.dropFirst()
    }
}

#if DEBUG
#Preview {
    FilterSheetView(
        filter: .constant(VehicleFilter()),
        availableMakes: ["Toyota", "Ford", "Tesla"],
        availableBodyStyles: ["truck", "SUV", "sedan"]
    )
}
#endif
