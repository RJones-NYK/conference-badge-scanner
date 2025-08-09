import SwiftUI
import SwiftData

struct NewConversationView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let event: Event
    // Optional completion action (e.g., to close a presenting sheet)
    let onComplete: (() -> Void)?
    // Controls whether the view should dismiss after save. When false, the form resets for rapid entry.
    let dismissOnSave: Bool

    @State private var fullName: String = ""
    @State private var titleText: String = ""
    @State private var nameText: String = ""
    @State private var roleText: String = ""
    @State private var companyText: String = ""
    @State private var departmentText: String = ""
    @State private var emailText: String = ""
    @State private var otherText: String = ""
    // Email is kept; Phone/Website/LinkedIn removed

    @State private var notes: String = ""
    @State private var followUp: Bool = false
    @State private var occurredAt: Date = Date()

    @State private var showingScanner = false

    // Conversations always show all fields now
    @State private var attendeeType: AttendeeType = .attendee

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button {
                        showingScanner = true
                    } label: {
                        HStack {
                            Image(systemName: "camera.viewfinder")
                            Text("Scan Badge with Camera")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }

                Section("Details") {
                    TextField("Title", text: $titleText)
                    TextField("Name", text: $nameText)
                    TextField("Role", text: $roleText)
                    TextField("Company", text: $companyText)
                    TextField("Department", text: $departmentText)
                    TextField("Email", text: $emailText)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                    TextField("Other", text: $otherText)
                    AttendeeTypePickerView(selection: $attendeeType)
                }

                Section("Notes") {
                    TextField("What did you discuss?", text: $notes, axis: .vertical)
                        .lineLimit(5, reservesSpace: true)
                }

                Section("When") {
                    DatePicker("Date & Time", selection: $occurredAt, displayedComponents: [.date, .hourAndMinute])
                }

                // Attendee type is shown as the chip picker in Details above when enabled
            }
            .navigationTitle("New Conversation")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(!canSave)
                }
            }
            .sheet(isPresented: $showingScanner) {
                ScanBadgeView(event: event) { raw in
                    let parsed = TextParsingService.parse(from: raw)
                    apply(parsed)
                    showingScanner = false
                } onCancel: {
                    showingScanner = false
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
    }

    init(event: Event, onComplete: (() -> Void)? = nil, dismissOnSave: Bool = true) {
        self.event = event
        self.onComplete = onComplete
        self.dismissOnSave = dismissOnSave
    }

    private var canSave: Bool { true }

    private func apply(_ parsed: ParsedAttendee) {
        if nameText.isEmpty { nameText = parsed.fullName ?? nameText }
        if titleText.isEmpty { titleText = parsed.title ?? titleText }
        if roleText.isEmpty { roleText = parsed.title ?? roleText }
        if companyText.isEmpty { companyText = parsed.company ?? companyText }
        if emailText.isEmpty { emailText = parsed.email ?? emailText }
    }

    private func save() {
        // Try to dedupe by email or phone
        let existing = DedupeService.findExistingAttendee(email: emailText.isEmpty ? nil : emailText, phone: nil, context: context)
        let attendee: Attendee = existing ?? {
            let a = Attendee()
            context.insert(a)
            return a
        }()

        attendee.title = titleText.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        attendee.fullName = nameText.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        attendee.role = roleText.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        attendee.company = companyText.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        attendee.department = departmentText.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        attendee.email = emailText.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        attendee.other = otherText.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty

        attendee.attendeeType = attendeeType.rawValue

        let convo = Conversation(event: event, attendee: attendee, notes: notes, followUp: followUp)
        convo.createdAt = occurredAt
        context.insert(convo)

        onComplete?()
        if dismissOnSave {
            dismiss()
        } else {
            resetForm()
        }
    }

    private func resetForm() {
        titleText = ""
        nameText = ""
        roleText = ""
        companyText = ""
        departmentText = ""
        emailText = ""
        otherText = ""
        notes = ""
        followUp = false
        occurredAt = Date()
        attendeeType = .attendee
        showingScanner = false
    }
}


