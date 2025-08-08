import Foundation

struct ParsedAttendee {
    var fullName: String? = nil
    var title: String? = nil
    var company: String? = nil
    var email: String? = nil
    var phone: String? = nil
    var website: String? = nil
    var linkedinURL: String? = nil
}

enum TextParsingService {
    static func parse(from raw: String) -> ParsedAttendee {
        var result = ParsedAttendee()
        let lines = raw
            .replacingOccurrences(of: "•", with: " ")
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if let candidate = lines.first(where: { !$0.contains("@") && $0.split(separator: " ").count >= 2 }) {
            result.fullName = candidate
        }

        let detectorTypes: NSTextCheckingResult.CheckingType = [.link, .phoneNumber]
        if let detector = try? NSDataDetector(types: detectorTypes.rawValue) {
            let matches = detector.matches(in: raw, options: [], range: NSRange(raw.startIndex..., in: raw))
            for match in matches {
                switch match.resultType {
                case .link:
                    if let url = match.url {
                        if url.absoluteString.lowercased().contains("linkedin") {
                            result.linkedinURL = url.absoluteString
                        } else if url.scheme?.hasPrefix("http") == true {
                            result.website = result.website ?? url.absoluteString
                        } else if url.scheme == "mailto" {
                            let full = url.absoluteString
                            let email = full.replacingOccurrences(of: "mailto:", with: "")
                            result.email = email
                        }
                    }
                case .phoneNumber:
                    if let number = match.phoneNumber { result.phone = number }
                default: break
                }
            }
        }

        if result.email == nil {
            if let email = raw.components(separatedBy: .whitespacesAndNewlines).first(where: { $0.contains("@") }) {
                result.email = email.trimmingCharacters(in: CharacterSet(charactersIn: ".,;()[]{}<>"))
            }
        }

        if let nameIdx = lines.firstIndex(where: { $0 == result.fullName }) {
            let after = lines.dropFirst(nameIdx + 1).prefix(2)
            if after.count >= 1 { result.title = after.first }
            if after.count >= 2 { result.company = after.dropFirst().first }
        }

        return result
    }
}


