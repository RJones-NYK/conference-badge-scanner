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
    @State private var roleOrTitle: String = ""
    @State private var company: String = ""
    @State private var email: String = ""
    // Email is kept; Phone/Website/LinkedIn removed

    @State private var notes: String = ""
    @State private var followUp: Bool = false
    @State private var occurredAt: Date = Date()

    @State private var showingScanner = false

    private var selected: Set<BadgeField> { Set(event.selectedBadgeFields) }

    private var showName: Bool { selected.contains(.name) }
    private var showTitle: Bool { selected.contains(.title) && !selected.contains(.role) }
    private var showRole: Bool { selected.contains(.role) || (selected.contains(.title) && selected.contains(.role)) }
    private var showCompany: Bool { selected.contains(.company) }
    private var showEmail: Bool { true }
    private var showAttendeeType: Bool { selected.contains(.attendeeType) }
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
                    if showName {
                        TextField("Name", text: $fullName)
                    }
                    if showTitle {
                        TextField("Title", text: $roleOrTitle)
                    }
                    if showRole {
                        TextField("Role", text: $roleOrTitle)
                    }
                    if showCompany {
                        TextField("Company", text: $company)
                    }
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                    if showAttendeeType {
                        AttendeeTypePickerView(selection: $attendeeType)
                    }
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

    private var canSave: Bool {
        if showName { !fullName.trimmingCharacters(in: .whitespaces).isEmpty } else { true }
    }

    private func apply(_ parsed: ParsedAttendee) {
        if showName, fullName.isEmpty { fullName = parsed.fullName ?? fullName }
        if (showTitle || showRole), roleOrTitle.isEmpty { roleOrTitle = parsed.title ?? roleOrTitle }
        if showCompany, company.isEmpty { company = parsed.company ?? company }
        if email.isEmpty { email = parsed.email ?? email }
    }

    private func save() {
        // Try to dedupe by email or phone
        let existing = DedupeService.findExistingAttendee(email: email.isEmpty ? nil : email, phone: nil, context: context)
        let attendee: Attendee = existing ?? {
            let a = Attendee()
            context.insert(a)
            return a
        }()

        if showName { attendee.fullName = fullName.trimmingCharacters(in: .whitespacesAndNewlines) }
        if showTitle || showRole { attendee.title = roleOrTitle.trimmingCharacters(in: .whitespacesAndNewlines) }
        if showCompany { attendee.company = company.trimmingCharacters(in: .whitespacesAndNewlines) }
        if showEmail { attendee.email = email.trimmingCharacters(in: .whitespacesAndNewlines) }
        // Phone/Website/LinkedIn removed from capture

        attendee.attendeeType = showAttendeeType ? attendeeType.rawValue : attendee.attendeeType

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
        fullName = ""
        roleOrTitle = ""
        company = ""
        email = ""
        notes = ""
        followUp = false
        occurredAt = Date()
        attendeeType = .attendee
        showingScanner = false
    }
}


