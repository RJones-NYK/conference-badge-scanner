import SwiftUI
import SwiftData

struct ConversationDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let conversation: Conversation
    @State private var isEditing = false

    @State private var fullName: String = ""
    @State private var title: String = ""
    @State private var company: String = ""
    @State private var email: String = ""
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
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedFullName != (conversation.attendee?.fullName ?? "") { return true }
        if trimmedTitle != (conversation.attendee?.title ?? "") { return true }
        if trimmedCompany != (conversation.attendee?.company ?? "") { return true }
        if trimmedEmail != (conversation.attendee?.email ?? "") { return true }
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
                    ClearableTextField("Company", text: $company)
                    ClearableTextField("Email", text: $email)
                } else {
                    LabeledContent("Name", value: fullName)
                    LabeledContent("Title", value: title)
                    LabeledContent("Company", value: company)
                    LabeledContent("Email", value: email)
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
        company = conversation.attendee?.company ?? ""
        email = conversation.attendee?.email ?? ""
        phone = ""
        website = ""
        linkedinURL = ""
        notes = conversation.notes
        createdAt = conversation.createdAt
        followUp = conversation.followUp
        attendeeType = AttendeeType(rawValue: conversation.attendee?.attendeeType ?? "Attendee") ?? .attendee
    }

    private func save() {
        if conversation.attendee == nil {
            conversation.attendee = Attendee()
        }
        conversation.attendee?.fullName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        conversation.attendee?.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        conversation.attendee?.company = company.trimmingCharacters(in: .whitespacesAndNewlines)
        conversation.attendee?.email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        // Phone/Website/LinkedIn removed from editing
        conversation.notes = notes
        conversation.createdAt = createdAt
        conversation.followUp = followUp
        conversation.attendee?.attendeeType = attendeeType.rawValue
    }
}


