import Foundation
import SwiftData

@Model
final class Attendee {
    var fullName: String?
    var firstName: String?
    var lastName: String?
    var title: String?
    var role: String?
    var company: String?
    var department: String?
    var email: String?
    var phone: String?
    var website: String?
    var linkedinURL: String?
    var attendeeType: String?
    var other: String?
    @Relationship(deleteRule: .cascade) var conversations: [Conversation] = []

    init(fullName: String? = nil,
         firstName: String? = nil,
         lastName: String? = nil,
         title: String? = nil,
         role: String? = nil,
         company: String? = nil,
         department: String? = nil,
         email: String? = nil,
         phone: String? = nil,
         website: String? = nil,
         linkedinURL: String? = nil,
         attendeeType: String? = nil,
         other: String? = nil) {
        self.fullName = fullName
        self.firstName = firstName
        self.lastName = lastName
        self.title = title
        self.role = role
        self.company = company
        self.department = department
        self.email = email
        self.phone = phone
        self.website = website
        self.linkedinURL = linkedinURL
        self.attendeeType = attendeeType
        self.other = other
    }
}


