import SwiftUI

struct VehicleDetailHeader: View {
    static let compactHeight: CGFloat = 72

    let imageURLs: [URL]
    let firstImageURL: URL?
    let title: String
    let trimLotText: String
    let bidText: String
    let bidLabel: String
    let isCollapsed: Bool
    let onCollapse: () -> Void
    let onExpand: () -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            expandedHeader
                .opacity(isCollapsed ? 0 : 1)
                .allowsHitTesting(!isCollapsed)
            compactHeader
                .opacity(isCollapsed ? 1 : 0)
                .allowsHitTesting(isCollapsed)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var expandedHeader: some View {
        ZStack(alignment: .bottomLeading) {
            imageCarousel
            expandedText
        }
        .overlay(alignment: .topTrailing) {
            collapseButton
        }
        .background(Color(.secondarySystemBackground))
    }

    private var imageCarousel: some View {
        Group {
            if imageURLs.isEmpty {
                CachedAsyncImage(url: nil, failureIconSize: 44)
            } else {
                TabView {
                    ForEach(imageURLs, id: \.self) { url in
                        CachedAsyncImage(url: url, failureIconSize: 44)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .tabViewStyle(.page)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var expandedText: some View {
        VStack(alignment: .leading, spacing: Layout.expandedTextSpacing) {
            Text(title)
                .font(.system(size: Layout.expandedTitleSize, weight: .semibold))
                .lineLimit(2)

            HStack(alignment: .lastTextBaseline) {
                Text(bidText)
                    .font(.system(size: Layout.expandedBidSize, weight: .bold))
                    .accessibilityIdentifier("detail-current-bid")
                Text(bidLabel)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.82))
            }

            Text(trimLotText)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, Layout.edgePadding)
        .padding(.bottom, Layout.expandedBottomPadding)
        .allowsHitTesting(false)
    }

    private var compactHeader: some View {
        HStack(spacing: Layout.compactSpacing) {
            compactImage
            compactTextStack
        }
        .frame(height: Self.compactHeight)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Layout.edgePadding)
        .background(Color(.systemBackground))
        .overlay(alignment: .topTrailing) {
            expandButton
        }
    }

    private var compactImage: some View {
        let size = Self.compactHeight - Layout.compactImageInset * 2
        return Group {
            if let firstImageURL {
                CachedAsyncImage(url: firstImageURL, contentMode: .fit, failureIconSize: 20)
            } else {
                CachedAsyncImage(url: nil, failureIconSize: 20)
            }
        }
        .frame(width: size, height: size)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Layout.compactImageCornerRadius))
    }

    private var compactTextStack: some View {
        VStack(alignment: .leading, spacing: Layout.compactTextSpacing) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
            Text(bidText)
                .font(.headline.weight(.bold))
                .lineLimit(1)
            Text(trimLotText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.trailing, Layout.iconSize)
    }

    private var collapseButton: some View {
        HeaderIconButton(systemName: "chevron.up", color: .white, action: onCollapse)
            .background(.ultraThinMaterial, in: Circle())
            .padding(.top, Layout.buttonPadding)
            .padding(.trailing, Layout.edgePadding)
    }

    private var expandButton: some View {
        HeaderIconButton(systemName: "chevron.down", color: .primary, action: onExpand)
            .background(Color(.secondarySystemBackground), in: Circle())
            .padding(.top, Layout.buttonPadding)
            .padding(.trailing, Layout.edgePadding)
    }
}

private enum Layout {
    static let edgePadding: CGFloat = 20
    static let buttonPadding: CGFloat = 12
    static let iconSize: CGFloat = 40
    static let iconFontSize: CGFloat = 15

    static let compactSpacing: CGFloat = 12
    static let compactTextSpacing: CGFloat = 3
    static let compactImageInset: CGFloat = 2
    static let compactImageCornerRadius: CGFloat = 6

    static let expandedTitleSize: CGFloat = 28
    static let expandedBidSize: CGFloat = 22
    static let expandedTextSpacing: CGFloat = 6
    static let expandedBottomPadding: CGFloat = 22
}

private struct HeaderIconButton: View {
    let systemName: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: Layout.iconFontSize, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: Layout.iconSize, height: Layout.iconSize)
        }
        .buttonStyle(.plain)
    }
}

#if DEBUG
#Preview("Expanded") {
    VehicleDetailHeader(
        imageURLs: [],
        firstImageURL: nil,
        title: "2025 Toyota Tacoma",
        trimLotText: "TRD Sport - A-0001",
        bidText: "$16,500",
        bidLabel: "Current bid",
        isCollapsed: false,
        onCollapse: {},
        onExpand: {}
    )
    .frame(height: 320)
}

#Preview("Compact") {
    VehicleDetailHeader(
        imageURLs: [],
        firstImageURL: nil,
        title: "2025 Toyota Tacoma",
        trimLotText: "TRD Sport - A-0001",
        bidText: "$16,500",
        bidLabel: "Current bid",
        isCollapsed: true,
        onCollapse: {},
        onExpand: {}
    )
    .frame(height: VehicleDetailHeader.compactHeight)
}
#endif
