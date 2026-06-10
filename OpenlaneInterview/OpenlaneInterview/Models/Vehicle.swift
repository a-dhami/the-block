import Foundation

struct Vehicle: Decodable, Identifiable, Hashable {
    let id: String
    let vin: String
    let year: Int
    let make: String
    let model: String
    let trim: String
    let bodyStyle: String
    let exteriorColor: String
    let interiorColor: String
    let engine: String
    let transmission: String
    let drivetrain: String
    let odometerKm: Int
    let fuelType: String
    let conditionGrade: Double
    let conditionReport: String
    let damageNotes: [String]
    let titleStatus: String
    let province: String
    let city: String
    let auctionStart: Date
    let startingBid: Int
    let reservePrice: Int?
    let buyNowPrice: Int?
    let images: [URL]
    let sellingDealership: String
    let lot: String
    var currentBid: Int?
    var bidCount: Int

    func withUpdatedBid(_ amount: Int) -> Vehicle {
        var updated = self
        updated.currentBid = amount
        updated.bidCount += 1
        return updated
    }
}
