import Foundation

enum AttendeeType: String, CaseIterable, Identifiable, Codable {
    case speaker = "Speaker"
    case attendee = "Attendee"
    case vendor = "Vendor"
    case organiser = "Organiser"
    case other = "Other"

    var id: String { rawValue }
    var displayName: String { rawValue }

    var iconName: String {
        switch self {
        case .speaker: return "megaphone.fill"
        case .attendee: return "person.fill"
        case .vendor: return "bag.fill"
        case .organiser: return "person.3.fill"
        case .other: return "questionmark.circle.fill"
        }
    }
}


