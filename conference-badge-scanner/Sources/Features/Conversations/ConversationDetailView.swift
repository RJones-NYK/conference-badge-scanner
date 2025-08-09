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

    var body: some View {
        Form {
            Section("Attendee") {
                TextField("Name", text: $fullName).disabled(!isEditing)
                TextField("Title", text: $title).disabled(!isEditing)
                TextField("Company", text: $company).disabled(!isEditing)
                TextField("Email", text: $email).disabled(!isEditing)
            }
            Section("Notes") {
                TextField("Notes", text: $notes, axis: .vertical)
                    .lineLimit(6, reservesSpace: true)
                    .disabled(!isEditing)
            }
            Section("When") {
                DatePicker("Date & Time", selection: $createdAt, displayedComponents: [.date, .hourAndMinute])
                    .disabled(!isEditing)
            }
            Section("Details") {
                AttendeeTypePickerView(selection: $attendeeType, isEnabled: isEditing)
                Toggle("Needs follow-up", isOn: $followUp).disabled(!isEditing)
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


