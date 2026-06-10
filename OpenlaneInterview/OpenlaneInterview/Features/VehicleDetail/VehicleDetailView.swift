import SwiftUI

struct VehicleDetailView: View {
    @StateObject private var viewModel: VehicleDetailViewModel
    @FocusState private var isBidInputFocused: Bool
    @State private var isHeaderCollapsed = false

    private enum Layout {
        static let horizontalPadding: CGFloat = 20
        static let detailsTopPadding: CGFloat = 24
        static let detailsBottomPadding: CGFloat = 32
        static let sectionSpacing: CGFloat = 24
        static let smallTopPadding: CGFloat = 4
        static let noteSpacing: CGFloat = 10
    }

    init(vehicle: Vehicle) {
        _viewModel = StateObject(wrappedValue: VehicleDetailViewModel(vehicle: vehicle))
    }

    var body: some View {
        GeometryReader { proxy in
            let expandedHeaderHeight = proxy.size.height * 0.5

            VStack(spacing: 0) {
                header(expandedHeight: expandedHeaderHeight)
                detailsScrollView
                ClockedView { date in
                    if viewModel.isLive(now: date) {
                        biddingFooter
                    }
                }
            }
            .background(Color(.systemBackground))
        }
        .navigationTitle(viewModel.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func header(expandedHeight: CGFloat) -> some View {
        VehicleDetailHeader(
            imageURLs: viewModel.imageURLs,
            firstImageURL: viewModel.firstImageURL,
            title: viewModel.vehicleTitle,
            trimLotText: viewModel.trimLotText,
            bidText: viewModel.activeBidText,
            bidLabel: viewModel.bidLabel,
            isCollapsed: isHeaderCollapsed,
            onCollapse: collapseHeader,
            onExpand: expandHeader
        )
        .contentShape(Rectangle())
        .onTapGesture {
            dismissBidInput()
        }
        .frame(height: isHeaderCollapsed ? VehicleDetailHeader.compactHeight : expandedHeight, alignment: .top)
        .clipped()
    }

    private var detailsScrollView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
                VehicleDetailSection(title: "Auction") {
                    ClockedView { date in
                        VehicleDetailRow(
                            title: "Status",
                            value: viewModel.auctionStatusLabel(now: date)
                        )
                    }
                    detailRows(viewModel.auctionRows)
                }

                VehicleDetailSection(title: "Specs") {
                    detailRows(viewModel.specRows)
                }

                conditionSection
                sellerSection
            }
            .padding(.horizontal, Layout.horizontalPadding)
            .padding(.top, Layout.detailsTopPadding)
            .padding(.bottom, Layout.detailsBottomPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                dismissBidInput()
            }
        }
    }

    private var conditionSection: some View {
        VehicleDetailSection(title: "Condition") {
            detailRows(viewModel.conditionRows)

            Text(viewModel.conditionReport)
                .padding(.top, Layout.smallTopPadding)

            if !viewModel.damageNotes.isEmpty {
                VStack(alignment: .leading, spacing: Layout.noteSpacing) {
                    Text("Damage Notes")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    ForEach(viewModel.damageNotes, id: \.self) { note in
                        Text(note)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, Layout.smallTopPadding)
            }
        }
    }

    private var sellerSection: some View {
        VehicleDetailSection(title: "Seller") {
            Text(viewModel.sellingDealership)
            Text(viewModel.sellerLocation)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var biddingFooter: some View {
        BiddingFooter(
            bidLabel: viewModel.footerBidLabel,
            bidText: viewModel.footerBidText,
            buttonTitle: viewModel.bidButtonTitle,
            bidIncrementText: $viewModel.bidIncrementText,
            isBidInputFocused: $isBidInputFocused,
            canPlaceBid: viewModel.canPlaceBid,
            onBid: placeBid
        )
    }

    @ViewBuilder
    private func detailRows(_ rows: [VehicleDetailRowData]) -> some View {
        ForEach(rows) { row in
            VehicleDetailRow(title: row.title, value: row.value)
        }
    }

    private func placeBid() {
        viewModel.placeBid()
        dismissBidInput()
    }

    private func collapseHeader() {
        dismissBidInput()

        withAnimation(.spring(response: 0.34, dampingFraction: 0.84)) {
            isHeaderCollapsed = true
        }
    }

    private func expandHeader() {
        dismissBidInput()

        withAnimation(.spring(response: 0.34, dampingFraction: 0.84)) {
            isHeaderCollapsed = false
        }
    }

    private func dismissBidInput() {
        isBidInputFocused = false
    }
}

private struct ClockedView<Content: View>: View {
    @ViewBuilder let content: (Date) -> Content

    var body: some View {
        if ProcessInfo.processInfo.arguments.contains("-uitesting") {
            content(AppDate.now)
        } else {
            TimelineView(.periodic(from: .now, by: 60)) { timeline in
                content(timeline.date)
            }
        }
    }
}
