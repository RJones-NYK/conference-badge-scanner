import Foundation

enum BadgeField: String, CaseIterable, Identifiable, Codable {
    case title
    case name
    case role
    case company
    case status
    case email
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .title: return "Title"
        case .name: return "Name"
        case .role: return "Role"
        case .company: return "Company"
        case .status: return "Status"
        case .email: return "Email"
        case .other: return "Other"
        }
    }

    static var defaultSelection: [BadgeField] {
        return [.name, .company, .email]
    }

    static var defaultKeys: [String] { defaultSelection.map { $0.rawValue } }
}


