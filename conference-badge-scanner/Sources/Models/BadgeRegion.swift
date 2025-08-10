import Foundation
import SwiftData

@Model
final class BadgeRegion {
    var fieldKey: String
    var x: Double
    var y: Double
    var width: Double
    var height: Double

    init(fieldKey: String, x: Double, y: Double, width: Double, height: Double) {
        self.fieldKey = fieldKey
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    convenience init(fieldKey: String, rect: NormalizedRect) {
        self.init(fieldKey: fieldKey, x: rect.x, y: rect.y, width: rect.width, height: rect.height)
    }

    var normalizedRect: NormalizedRect {
        NormalizedRect(x: x, y: y, width: width, height: height)
    }
}


