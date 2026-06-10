import SwiftUI

struct BiddingFooter: View {
    let bidLabel: String
    let bidText: String
    let buttonTitle: String
    @Binding var bidIncrementText: String
    var isBidInputFocused: FocusState<Bool>.Binding
    let canPlaceBid: Bool
    let onBid: () -> Void

    private enum Layout {
        static let horizontalPadding: CGFloat = 20
        static let verticalPadding: CGFloat = 12
        static let itemSpacing: CGFloat = 12
        static let labelSpacing: CGFloat = 2
        static let textFieldWidth: CGFloat = 74
        static let buttonLabelWidth: CGFloat = 72
    }

    var body: some View {
        HStack(alignment: .center, spacing: Layout.itemSpacing) {
            VStack(alignment: .leading, spacing: Layout.labelSpacing) {
                Text(bidLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(bidText)
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 2) {
                Text("+")
                    .foregroundStyle(.secondary)
                TextField("", text: $bidIncrementText)
                    .keyboardType(.numberPad)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused(isBidInputFocused)
                    .accessibilityLabel("Bid increment")
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 7)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color(.separator), lineWidth: 0.5)
            }
            .frame(width: Layout.textFieldWidth)

            Button {
                onBid()
            } label: {
                Text(buttonTitle)
                    .frame(width: Layout.buttonLabelWidth)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canPlaceBid)
            .accessibilityIdentifier("place-bid-button")
        }
        .padding(.horizontal, Layout.horizontalPadding)
        .padding(.vertical, Layout.verticalPadding)
        .background(.regularMaterial)
        .overlay(alignment: .top) {
            Divider()
        }
    }
}

#if DEBUG
private struct BiddingFooterPreview: View {
    @State private var bidIncrementText = ""
    @FocusState private var isBidInputFocused: Bool

    var body: some View {
        BiddingFooter(
            bidLabel: "Current bid",
            bidText: "$16,500",
            buttonTitle: "Bid +$50",
            bidIncrementText: $bidIncrementText,
            isBidInputFocused: $isBidInputFocused,
            canPlaceBid: true,
            onBid: {}
        )
    }
}

#Preview {
    BiddingFooterPreview()
}
#endif
