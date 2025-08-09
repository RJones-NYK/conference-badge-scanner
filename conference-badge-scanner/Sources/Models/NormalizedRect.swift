import Foundation

/// A rectangle expressed in normalized coordinates relative to an image/view.
/// - Coordinates are normalized in the range [0, 1].
/// - Origin is at the top-left, matching SwiftUI view coordinate space.
struct NormalizedRect: Codable, Equatable {
    var x: Double
    var y: Double
    var width: Double
    var height: Double

    init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    static let zero = NormalizedRect(x: 0, y: 0, width: 0, height: 0)
}


