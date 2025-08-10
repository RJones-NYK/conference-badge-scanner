import Foundation

/// Container for OCR output used by the conversations flow.
/// - rawText: The concatenated text recognized from the whole image or merged from regions
/// - mappedByField: Optional more-structured extraction keyed by BadgeField when template regions were used
struct ScanExtraction {
    let rawText: String
    let mappedByField: [BadgeField: String]?
}



