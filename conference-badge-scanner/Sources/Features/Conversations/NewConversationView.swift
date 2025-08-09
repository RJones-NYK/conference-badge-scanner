import SwiftUI
import SwiftData
import UIKit

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
    // Scanner results preview
    @State private var lastScannedImage: UIImage? = nil
    @State private var lastExtractedText: String = ""
    @State private var confirmCancel = false

    // Center HUD feedback (large check or X)
    private enum CenterHUD { case saved, cancelled }
    @State private var centerHUD: CenterHUD? = nil

    // Focus handling to dismiss keyboard when saving/cancelling
    private enum FocusField: Hashable { case title, name, role, company, department, email, other, notes }
    @FocusState private var focusedField: FocusField?

    // Conversations always show all fields now
    @State private var attendeeType: AttendeeType = .attendee

    // Events list and selection
    @Query(sort: \Event.startDate, order: .reverse) private var events: [Event]
    @State private var selectedEvent: Event? = nil
    @State private var eventManuallySelected: Bool = false

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                Form {
                // Event selection & Scan action
                Section {
                    EmptyView()
                } header: {
                    HStack {
                        Spacer()
                        Button {
                            showingScanner = true
                        } label: {
                            HStack {
                                Image(systemName: "camera.viewfinder")
                                Text("Scan Badge")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        Spacer()
                    }
                    .padding(.top, 4)
                }
                .id("top")

                if !events.isEmpty {
                    Section("Event") {
                        Picker("Event", selection: Binding<Event?>(
                            get: { selectedEvent ?? event },
                            set: { newValue in
                                selectedEvent = newValue
                                eventManuallySelected = true
                            }
                        )) {
                            ForEach(events) { ev in
                                Text(ev.name).tag(ev as Event?)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }

                if !lastExtractedText.isEmpty || lastScannedImage != nil {
                    Section("Scan Result") {
                        HStack(alignment: .top, spacing: 12) {
                            if let img = lastScannedImage {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 140)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .strokeBorder(Color.secondary.opacity(0.2))
                                    )
                            }
                            ScrollView {
                                Text(lastExtractedText)
                                    .font(.footnote)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .frame(minHeight: 100)
                        }
                    }
                }

                Section("Details") {
                    TextField("Title", text: $titleText)
                        .focused($focusedField, equals: .title)
                    TextField("Name", text: $nameText)
                        .focused($focusedField, equals: .name)
                    TextField("Role", text: $roleText)
                        .focused($focusedField, equals: .role)
                    TextField("Company", text: $companyText)
                        .focused($focusedField, equals: .company)
                    TextField("Department", text: $departmentText)
                        .focused($focusedField, equals: .department)
                    TextField("Email", text: $emailText)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .focused($focusedField, equals: .email)
                    TextField("Other", text: $otherText)
                        .focused($focusedField, equals: .other)
                    AttendeeTypePickerView(selection: $attendeeType)
                }

                Section("Notes") {
                    TextField("What did you discuss?", text: $notes, axis: .vertical)
                        .lineLimit(5, reservesSpace: true)
                        .focused($focusedField, equals: .notes)
                }

                Section("When") {
                    DatePicker("Date & Time", selection: $occurredAt, displayedComponents: [.date, .hourAndMinute])
                }

                // Attendee type is shown as the chip picker in Details above when enabled
                }
                .navigationTitle("New Conversation")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel", role: .destructive) { confirmCancel = true }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") { save(proxy: proxy) }.disabled(!canSave)
                    }
                }
                .alert("Are you sure?", isPresented: $confirmCancel) {
                    Button("Discard", role: .destructive) {
                        if dismissOnSave {
                            dismiss()
                        } else {
                            resetForm()
                            endEditingAndScrollTop(proxy)
                            showHUD(.cancelled)
                        }
                    }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text("This will clear the form and discard any entered information.")
                }
                .overlay { centerHUDView }
                .fullScreenCover(isPresented: $showingScanner) {
                    ScanBadgeView(event: selectedEvent ?? event) { image, raw in
                        lastScannedImage = image
                        lastExtractedText = raw
                        let parsed = TextParsingService.parse(from: raw)
                        apply(parsed)
                        showingScanner = false
                    } onCancel: {
                        showingScanner = false
                    }
                    .ignoresSafeArea()
                }
            }
        }
        .onAppear {
            // Initialize selected event and auto-pick by date if appropriate
            selectedEvent = event
            autoSelectEventIfNeeded(for: occurredAt)
        }
        .onChange(of: occurredAt) { _, newValue in
            if !eventManuallySelected { autoSelectEventIfNeeded(for: newValue) }
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

    private func save(proxy: ScrollViewProxy) {
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

        let convo = Conversation(event: selectedEvent ?? event, attendee: attendee, notes: notes, followUp: followUp)
        convo.createdAt = occurredAt
        context.insert(convo)

        onComplete?()
        if dismissOnSave {
            dismiss()
        } else {
            resetForm()
            endEditingAndScrollTop(proxy)
            showHUD(.saved)
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
        lastScannedImage = nil
        lastExtractedText = ""
    }

    private func endEditingAndScrollTop(_ proxy: ScrollViewProxy) {
        focusedField = nil
        withAnimation { proxy.scrollTo("top", anchor: .top) }
    }

    @ViewBuilder
    private var centerHUDView: some View {
        if let centerHUD, !dismissOnSave {
            ZStack {
                Color.clear.contentShape(Rectangle()).ignoresSafeArea()
                VStack(spacing: 12) {
                    Image(systemName: centerHUD == .saved ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 56, weight: .semibold))
                        .foregroundStyle(centerHUD == .saved ? .green : .red)
                    Text(centerHUD == .saved ? "Conversation Saved" : "Cancelled")
                        .font(.headline)
                        .bold()
                }
                .padding(24)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            .transition(.opacity.combined(with: .scale))
            .onTapGesture { hideHUD() }
        }
    }

    private func showHUD(_ kind: CenterHUD) {
        withAnimation { centerHUD = kind }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            hideHUD()
        }
    }

    private func hideHUD() {
        withAnimation { centerHUD = nil }
    }

    private func autoSelectEventIfNeeded(for date: Date) {
        // Prefer event whose date range contains the occurredAt date
        if let match = events.first(where: { eventContainsDate($0, date: date) }) {
            selectedEvent = match
        }
    }

    private func eventContainsDate(_ ev: Event, date: Date) -> Bool {
        if let end = ev.endDate {
            return ev.startDate <= date && date <= end
        } else {
            return ev.startDate <= date
        }
    }
}


