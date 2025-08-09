import SwiftUI
import SwiftData

struct ConversationDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let conversation: Conversation
    @State private var isEditing = false

    @State private var fullName: String = ""
    @State private var title: String = ""
    @State private var role: String = ""
    @State private var company: String = ""
    @State private var department: String = ""
    @State private var email: String = ""
    @State private var other: String = ""
    @State private var phone: String = ""
    @State private var website: String = ""
    @State private var linkedinURL: String = ""
    @State private var notes: String = ""
    @State private var createdAt: Date = Date()
    @State private var followUp: Bool = false
    @State private var attendeeType: AttendeeType = .attendee
    @State private var confirmDelete = false

    private var hasChanges: Bool {
        let trimmedFullName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCompany = company.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedRole = role.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDepartment = department.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedOther = other.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedWebsite = website.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLinkedIn = linkedinURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedFullName != (conversation.attendee?.fullName ?? "") { return true }
        if trimmedTitle != (conversation.attendee?.title ?? "") { return true }
        if trimmedRole != (conversation.attendee?.role ?? "") { return true }
        if trimmedCompany != (conversation.attendee?.company ?? "") { return true }
        if trimmedDepartment != (conversation.attendee?.department ?? "") { return true }
        if trimmedEmail != (conversation.attendee?.email ?? "") { return true }
        if trimmedOther != (conversation.attendee?.other ?? "") { return true }
        if trimmedPhone != (conversation.attendee?.phone ?? "") { return true }
        if trimmedWebsite != (conversation.attendee?.website ?? "") { return true }
        if trimmedLinkedIn != (conversation.attendee?.linkedinURL ?? "") { return true }
        if trimmedNotes != conversation.notes { return true }
        if createdAt != conversation.createdAt { return true }
        if followUp != conversation.followUp { return true }
        if attendeeType.rawValue != (conversation.attendee?.attendeeType ?? AttendeeType.attendee.rawValue) { return true }
        return false
    }

    var body: some View {
        Form {
            Section("Attendee") {
                if isEditing {
                    ClearableTextField("Name", text: $fullName)
                    ClearableTextField("Title", text: $title)
                    ClearableTextField("Role", text: $role)
                    ClearableTextField("Company", text: $company)
                    ClearableTextField("Department", text: $department)
                    ClearableTextField("Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .keyboardType(.emailAddress)
                    ClearableTextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                    ClearableTextField("Website", text: $website)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .keyboardType(.URL)
                    ClearableTextField("LinkedIn", text: $linkedinURL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .keyboardType(.URL)
                    ClearableTextField("Other", text: $other)
                } else {
                    if !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        LabeledContent("Name", value: fullName)
                    }
                    if !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        LabeledContent("Title", value: title)
                    }
                    if !role.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        LabeledContent("Role", value: role)
                    }
                    if !company.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        LabeledContent("Company", value: company)
                    }
                    if !department.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        LabeledContent("Department", value: department)
                    }
                    if !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        LabeledContent("Email", value: email)
                    }
                    if !phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        LabeledContent("Phone", value: phone)
                    }
                    if !website.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        LabeledContent("Website", value: website)
                    }
                    if !linkedinURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        LabeledContent("LinkedIn", value: linkedinURL)
                    }
                    if !other.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        LabeledContent("Other", value: other)
                    }
                }
            }
            Section("Notes") {
                if isEditing {
                    ClearableTextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(6, reservesSpace: true)
                } else {
                    if notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("None").foregroundStyle(.secondary)
                    } else {
                        Text(notes)
                    }
                }
            }
            Section("When") {
                if isEditing {
                    DatePicker("Date & Time", selection: $createdAt, displayedComponents: [.date, .hourAndMinute])
                } else {
                    LabeledContent("Date & Time", value: createdAt.formatted(date: .abbreviated, time: .shortened))
                }
            }
            Section("Details") {
                AttendeeTypePickerView(selection: $attendeeType, isEnabled: isEditing)
                if isEditing {
                    Toggle("Needs follow-up", isOn: $followUp)
                } else {
                    LabeledContent("Needs follow-up", value: followUp ? "Yes" : "No")
                }
            }
            Section {
                Button(role: .destructive) {
                    confirmDelete = true
                } label: {
                    Label("Delete Conversation", systemImage: "trash")
                }
            }
        }
        .navigationTitle(conversation.attendee?.fullName ?? "Conversation")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                if isEditing { Button("Cancel") { load() ; isEditing = false } }
            }
            ToolbarItem(placement: .primaryAction) {
                Button(isEditing ? "Save" : "Edit") {
                    if isEditing { save() }
                    isEditing.toggle()
                }
                .disabled(isEditing && !hasChanges)
            }
        }
        .onAppear(perform: load)
        .alert("Delete Conversation?", isPresented: $confirmDelete) {
            Button("Delete", role: .destructive) {
                context.delete(conversation)
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: { Text("This will remove the conversation permanently.") }
    }

    private func load() {
        fullName = conversation.attendee?.fullName ?? ""
        title = conversation.attendee?.title ?? ""
        role = conversation.attendee?.role ?? ""
        company = conversation.attendee?.company ?? ""
        department = conversation.attendee?.department ?? ""
        email = conversation.attendee?.email ?? ""
        phone = conversation.attendee?.phone ?? ""
        website = conversation.attendee?.website ?? ""
        linkedinURL = conversation.attendee?.linkedinURL ?? ""
        other = conversation.attendee?.other ?? ""
        notes = conversation.notes
        createdAt = conversation.createdAt
        followUp = conversation.followUp
        attendeeType = AttendeeType(rawValue: conversation.attendee?.attendeeType ?? "Attendee") ?? .attendee
    }

    private func save() {
        if conversation.attendee == nil {
            conversation.attendee = Attendee()
        }
        conversation.attendee?.fullName = fullName.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        conversation.attendee?.title = title.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        conversation.attendee?.role = role.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        conversation.attendee?.company = company.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        conversation.attendee?.department = department.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        conversation.attendee?.email = email.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        conversation.attendee?.other = other.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        conversation.attendee?.phone = phone.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        conversation.attendee?.website = website.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        conversation.attendee?.linkedinURL = linkedinURL.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        conversation.notes = notes
        conversation.createdAt = createdAt
        conversation.followUp = followUp
        conversation.attendee?.attendeeType = attendeeType.rawValue
    }
}


