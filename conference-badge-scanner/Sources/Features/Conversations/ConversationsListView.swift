import SwiftUI
import SwiftData

struct ConversationsListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Event.startDate, order: .reverse) private var events: [Event]
    @State private var selectedEvent: Event? = nil
    @State private var showingScanner = false

    @Query(sort: \Conversation.createdAt, order: .reverse) private var conversations: [Conversation]

    var body: some View {
        VStack(spacing: 0) {
            // Event selector
            if events.isEmpty {
                ContentUnavailableView("No events", systemImage: "calendar", description: Text("Create an event first on the Events tab."))
            } else {
                Picker("Event", selection: Binding(get: { selectedEvent ?? events.first }, set: { selectedEvent = $0 })) {
                    ForEach(events) { event in
                        Text(event.name).tag(Optional(event))
                    }
                }
                .pickerStyle(.menu)
                .padding([.horizontal, .top])

                List(filteredConversations) { convo in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(convo.attendee?.fullName ?? "Unknown").font(.headline)
                        if let company = convo.attendee?.company {
                            Text(company).font(.subheadline).foregroundStyle(.secondary)
                        }
                        Text(convo.notes).font(.body).lineLimit(2)
                    }
                }
            }
        }
        .navigationTitle("Conversations")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    guard let _ = selectedEvent ?? events.first else { return }
                    showingScanner = true
                } label: { Label("Scan", systemImage: "camera.viewfinder") }
            }
        }
        .onAppear {
            if selectedEvent == nil { selectedEvent = events.first }
        }
        .sheet(isPresented: $showingScanner) {
            if let event = selectedEvent ?? events.first {
                ScanBadgeView { raw in
                    let parsed = TextParsingService.parse(from: raw)
                    let attendee = DedupeService.findExistingAttendee(email: parsed.email, phone: parsed.phone, context: context)
                        ?? {
                            let a = Attendee()
                            a.fullName = parsed.fullName
                            a.title = parsed.title
                            a.company = parsed.company
                            a.email = parsed.email
                            a.phone = parsed.phone
                            a.website = parsed.website
                            a.linkedinURL = parsed.linkedinURL
                            context.insert(a)
                            return a
                        }()
                    let convo = Conversation(event: event, attendee: attendee, notes: "", followUp: false)
                    context.insert(convo)
                } onCancel: {}
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            } else {
                Text("No event available")
            }
        }
    }

    private var filteredConversations: [Conversation] {
        let base = conversations
        if let event = selectedEvent {
            return base.filter { $0.event?.persistentModelID == event.persistentModelID }
        }
        return base
    }
}


