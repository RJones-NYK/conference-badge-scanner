import Foundation
import SwiftData

@Model
final class Event {
    var name: String
    var startDate: Date
    var endDate: Date?
    var location: String?
    var details: String?
    var website: String?
    // Persist selected badge fields as raw value keys for portability
    var badgeFieldKeys: [String] = BadgeField.defaultKeys
    // Badge template configuration
    var badgeTemplateImageData: Data? = nil
    @Relationship(deleteRule: .cascade) var badgeRegions: [BadgeRegion] = []
    @Relationship(deleteRule: .cascade) var conversations: [Conversation] = []

    init(name: String,
         startDate: Date = Date(),
         endDate: Date? = nil,
         location: String? = nil,
         details: String? = nil,
         website: String? = nil,
          badgeFieldKeys: [String] = BadgeField.defaultKeys,
          badgeTemplateImageData: Data? = nil,
          badgeRegions: [BadgeRegion] = []) {
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.location = location
        self.details = details
        self.website = website
        self.badgeFieldKeys = badgeFieldKeys
        self.badgeTemplateImageData = badgeTemplateImageData
        self.badgeRegions = badgeRegions
    }
}

extension Event {
    var selectedBadgeFields: [BadgeField] {
        let fields = badgeFieldKeys.compactMap(BadgeField.init(rawValue:))
        return fields.isEmpty ? BadgeField.defaultSelection : fields
    }

    var badgeFieldRegionsMap: [String: NormalizedRect] {
        var map: [String: NormalizedRect] = [:]
        for region in badgeRegions {
            map[region.fieldKey] = region.normalizedRect
        }
        return map
    }
}


