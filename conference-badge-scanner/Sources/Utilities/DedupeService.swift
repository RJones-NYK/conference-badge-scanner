import SwiftData

enum DedupeService {
    static func findExistingAttendee(email: String?, phone: String?, context: ModelContext) -> Attendee? {
        // Fallback to in-memory filtering to avoid macro compatibility issues
        guard let all = try? context.fetch(FetchDescriptor<Attendee>()) else { return nil }
        if let email, !email.isEmpty, let foundByEmail = all.first(where: { ($0.email ?? "").caseInsensitiveCompare(email) == .orderedSame }) {
            return foundByEmail
        }
        if let phone, !phone.isEmpty, let foundByPhone = all.first(where: { ($0.phone ?? "") == phone }) {
            return foundByPhone
        }
        return nil
    }
}


