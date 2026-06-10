import XCTest

final class OpenlaneInterviewUITests: XCTestCase {
    // Lot A-0005 is unique and starts at 14:00 on the anchor day. Under `-uitesting`
    // the app's clock is pinned to 15:00 that day, so this lot is reliably "Live"
    // (within the 2h window) and its bidding footer is visible.
    private let searchTerm = "A-0005"
    private let rowIdentifier = "vehicle-row-A-0005"
    private let vehicleVIN = "86S0EKEB2RV032GYU"
    private let currentBid = "30,500"
    private let bidAfterDefault = "30,550"

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        // Skip network image loading so the app reaches idle and the tests stay fast
        // and offline-safe.
        app.launchArguments = ["-uitesting"]
        app.launch()
        return app
    }

    @MainActor
    func testInventoryLoadsVehicles() throws {
        let app = launchApp()

        let row = vehicleRow(in: app)
        XCTAssertTrue(row.waitForExistence(timeout: 8))
        XCTAssertTrue(row.label.contains(currentBid))
    }

    @MainActor
    func testOpeningVehicleShowsDetail() throws {
        let app = launchApp()

        openVehicle(in: app)

        XCTAssertTrue(app.staticTexts["VIN"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts[vehicleVIN].exists)
    }

    @MainActor
    func testDefaultBidUpdatesVisibleBidAmount() throws {
        let app = launchApp()

        openVehicle(in: app)

        let bidValue = app.staticTexts["detail-current-bid"]
        XCTAssertTrue(bidValue.waitForExistence(timeout: 5))
        XCTAssertTrue(bidValue.label.contains(currentBid))

        app.buttons["place-bid-button"].tap()

        let updatedBid = app.staticTexts.matching(identifier: "detail-current-bid")
            .containing(NSPredicate(format: "label CONTAINS %@", bidAfterDefault))
            .firstMatch
        XCTAssertTrue(updatedBid.waitForExistence(timeout: 3))
    }

    private func search(_ term: String, in app: XCUIApplication) {
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 8))
        searchField.tap()
        searchField.typeText(term)
    }

    private func openVehicle(in app: XCUIApplication) {
        let row = vehicleRow(in: app)
        XCTAssertTrue(row.waitForExistence(timeout: 8))
        row.tap()
    }

    private func vehicleRow(in app: XCUIApplication) -> XCUIElement {
        search(searchTerm, in: app)
        return app.buttons[rowIdentifier]
    }
}
