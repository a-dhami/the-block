import Foundation

extension Int {
    var priceText: String {
        "$" + formatted(.number.grouping(.automatic))
    }
}
