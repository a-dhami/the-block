#if DEBUG
import Foundation

extension Vehicle {
    static let preview = Vehicle(
        id: "preview-vehicle",
        vin: "PREVIEWVIN1234567",
        year: 2025,
        make: "Toyota",
        model: "Tacoma",
        trim: "TRD Sport",
        bodyStyle: "truck",
        exteriorColor: "Blue",
        interiorColor: "Black",
        engine: "3.5L V6",
        transmission: "automatic",
        drivetrain: "4WD",
        odometerKm: 24500,
        fuelType: "gasoline",
        conditionGrade: 4.1,
        conditionReport: "Clean overall condition with normal wear.",
        damageNotes: ["Small chip on front bumper"],
        titleStatus: "clean",
        province: "ON",
        city: "Toronto",
        auctionStart: Date(),
        startingBid: 16000,
        reservePrice: nil,
        buyNowPrice: 24000,
        images: [],
        sellingDealership: "Openlane Motors",
        lot: "A-0001",
        currentBid: 16500,
        bidCount: 8
    )
}
#endif
