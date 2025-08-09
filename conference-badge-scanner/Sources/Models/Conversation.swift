import Foundation
import SwiftData

@Model
final class Conversation {
    var createdAt: Date = Date()
    var notes: String = ""
    var followUp: Bool = false
    var deletedAt: Date? = nil
    var event: Event?
    var attendee: Attendee?

    init(event: Event? = nil, attendee: Attendee? = nil, notes: String = "", followUp: Bool = false) {
        self.event = event
        self.attendee = attendee
        self.notes = notes
        self.followUp = followUp
    }
}


