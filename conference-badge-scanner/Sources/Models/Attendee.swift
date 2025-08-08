import Foundation
import SwiftData

@Model
final class Attendee {
    var fullName: String?
    var firstName: String?
    var lastName: String?
    var title: String?
    var company: String?
    var email: String?
    var phone: String?
    var website: String?
    var linkedinURL: String?
    @Relationship(deleteRule: .cascade) var conversations: [Conversation] = []

    init(fullName: String? = nil,
         firstName: String? = nil,
         lastName: String? = nil,
         title: String? = nil,
         company: String? = nil,
         email: String? = nil,
         phone: String? = nil,
         website: String? = nil,
         linkedinURL: String? = nil) {
        self.fullName = fullName
        self.firstName = firstName
        self.lastName = lastName
        self.title = title
        self.company = company
        self.email = email
        self.phone = phone
        self.website = website
        self.linkedinURL = linkedinURL
    }
}


