import SwiftUI

struct VehicleRowView: View {
    let vehicle: Vehicle

    private enum Layout {
        static let thumbnailSize: CGFloat = 100
        static let thumbnailCornerRadius: CGFloat = 4
        static let spacing: CGFloat = 12
    }

    var body: some View {
        HStack(alignment: .center, spacing: Layout.spacing) {
            CachedAsyncImage(url: vehicle.thumbnailURL)
                .frame(width: Layout.thumbnailSize, height: Layout.thumbnailSize)
                .clipShape(RoundedRectangle(cornerRadius: Layout.thumbnailCornerRadius))
                .overlay(alignment: .topLeading) {
                    auctionStatusBadge
                        .padding(2)
                }
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(vehicle.title)
                        .font(.headline)
                    Spacer()
                }
                Text("\(vehicle.odometerKm.formatted()) km")
                    .font(.footnote)
                Text(vehicle.description)
                    .font(.footnote)
                Text(vehicle.subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(vehicle.displayBid().priceText)
                    .fontWeight(.semibold)
                    .font(.subheadline)
                Spacer()
            }
        }
        .frame(height: Layout.thumbnailSize)
        .padding(.vertical, 4)
    }

    private var auctionStatusBadge: some View {
        let status = vehicle.auctionStatus()
        let color: Color
        switch status {
        case .live:     color = .green
        case .upcoming: color = .blue
        case .ended:    color = .red
        }
        return Text(status.label)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(color)
            .foregroundStyle(.white)
            .clipShape(
                RoundedRectangle(cornerRadius: 4)
            )
            .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
    }
}

private extension Vehicle {
    var title: String { "\(year) \(make) \(model)" }
    var subtitle: String { "\(trim) - \(city), \(province)" }
    var description: String { "\(conditionGrade)/5 - \(titleStatus.capitalized) - \(exteriorColor.capitalized)" }
    var thumbnailURL: URL? { images.first?.renderableImageURL }
}

#if DEBUG
#Preview {
    VehicleRowView(vehicle: .preview)
        .padding(.horizontal)
}
#endif
