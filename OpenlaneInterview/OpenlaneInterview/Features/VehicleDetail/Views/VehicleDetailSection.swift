import SwiftUI

private enum VehicleDetailSectionLayout {
    static let titleSpacing: CGFloat = 12
    static let rowSpacing: CGFloat = 10
    static let rowSpacerMinLength: CGFloat = 16
}

struct VehicleDetailSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: VehicleDetailSectionLayout.titleSpacing) {
            Text(title)
                .font(.headline)

            VStack(alignment: .leading, spacing: VehicleDetailSectionLayout.rowSpacing) {
                content()
            }
        }
    }
}

struct VehicleDetailRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .foregroundStyle(.secondary)

            Spacer(minLength: VehicleDetailSectionLayout.rowSpacerMinLength)

            Text(value)
                .multilineTextAlignment(.trailing)
        }
        .font(.body)
    }
}

#if DEBUG
#Preview {
    VehicleDetailSection(title: "Specs") {
        VehicleDetailRow(title: "VIN", value: "PREVIEWVIN1234567")
        VehicleDetailRow(title: "Odometer", value: "24,500 km")
        VehicleDetailRow(title: "Engine", value: "3.5L V6")
    }
    .padding()
}
#endif
