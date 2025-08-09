import SwiftUI
import SwiftData

struct ConversationsListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Event.startDate, order: .reverse) private var events: [Event]
    @State private var selectedEvent: Event? = nil
    @State private var showingNewConversation = false
    // Multi-select state
    @State private var isSelecting = false
    @State private var selectedConversationIDs: Set<PersistentIdentifier> = []
    @State private var showingMoveSheet = false
    @State private var moveTargetEvent: Event? = nil
    @State private var confirmDelete = false

    @Query(sort: \Conversation.createdAt, order: .reverse) private var conversations: [Conversation]
    @State private var search: String = ""

    // Extracted bindings to simplify type inference in Pickers
    private var selectedEventBinding: Binding<Event?> {
        Binding<Event?>(
            get: { selectedEvent ?? events.first },
            set: { selectedEvent = $0 }
        )
    }

    private var moveTargetBinding: Binding<Event?> {
        Binding<Event?>(
            get: { moveTargetEvent ?? events.first },
            set: { moveTargetEvent = $0 }
        )
    }

    var body: some View {
        Group {
            if events.isEmpty {
                ContentUnavailableView("No events", systemImage: "calendar", description: Text("Create an event first on the Events tab."))
            } else {
                conversationsList
                    .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Conversations")
        .toolbarTitleMenu {
            Picker("Event", selection: $selectedEvent) {
                Text("All Events").tag(nil as Event?)
                ForEach(events) { event in
                    Text(event.name).tag(event as Event?)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(isSelecting ? "Cancel" : "Select") {
                    if isSelecting {
                        isSelecting = false
                        selectedConversationIDs.removeAll()
                    } else {
                        isSelecting = true
                    }
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    if isSelecting {
                        isSelecting = false
                        selectedConversationIDs.removeAll()
                    } else {
                        guard let _ = selectedEvent ?? events.first else { return }
                        showingNewConversation = true
                    }
                } label: { Label(isSelecting ? "Done" : "New", systemImage: isSelecting ? "checkmark" : "plus") }
            }
            ToolbarItemGroup(placement: .bottomBar) {
                if isSelecting {
                    Button(role: .destructive) {
                        confirmDelete = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    .disabled(selectedConversationIDs.isEmpty)

                    Spacer()

                    Button {
                        moveTargetEvent = nextMoveTarget()
                        showingMoveSheet = true
                    } label: {
                        Label("Move", systemImage: "arrowshape.right")
                    }
                    .disabled(selectedConversationIDs.isEmpty || (events.count <= 1))
                }
            }
        }
        .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search name, company, notes")
        .navigationDestination(for: Conversation.self) { convo in
            ConversationDetailView(conversation: convo)
        }
        .sheet(isPresented: $showingNewConversation) {
            if let event = selectedEvent ?? events.first {
                NewConversationView(event: event, onComplete: { showingNewConversation = false })
            } else {
                Text("No event available")
            }
        }
        .sheet(isPresented: $showingMoveSheet) {
            moveSheetView
        }
        .alert("Delete \(selectedConversationIDs.count) conversation(s)?", isPresented: $confirmDelete) {
            Button("Delete", role: .destructive) { deleteSelected() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently remove the selected conversations.")
        }
        .overlay(alignment: .bottom) {
            undoToast
        }
    }

    private var eventPicker: some View {
        Picker("Event", selection: selectedEventBinding) {
            ForEach(events) { event in
                Text(event.name).tag(event as Event?)
            }
        }
        .pickerStyle(.menu)
        .padding([.horizontal, .top])
    }

    private var conversationsList: some View {
        List {
            Section(header: filterHeader) {
                ForEach(filteredConversations) { convo in
                    conversationRow(convo)
                }
            }
        }
        .overlay {
            if filteredConversations.isEmpty {
                if selectedEvent != nil {
                    ContentUnavailableView(
                        "No Conversations",
                        systemImage: "text.bubble",
                        description: Text("No conversations for this event.\nUse the Conversations title menu to switch to ‘All Events’ or tap New.")
                    )
                } else {
                    ContentUnavailableView(
                        "No Conversations",
                        systemImage: "text.bubble",
                        description: Text("Tap New to add your first conversation.")
                    )
                }
            }
        }
    }

    private var filterHeader: some View {
        HStack(spacing: 8) {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .foregroundStyle(.secondary)
            Text(selectedEvent?.name ?? "All Events")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func conversationRow(_ convo: Conversation) -> some View {
        if isSelecting {
            // Selection mode: tapping toggles selection; chevron is hidden
            HStack(alignment: .top, spacing: 12) {
                let selected = selectedConversationIDs.contains(convo.persistentModelID)
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selected ? Color.accentColor : Color.secondary)
                    .font(.system(size: 22))
                    .padding(.top, 3)

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(convo.attendee?.fullName ?? "Unknown").font(.headline)
                        Spacer()
                    }
                    if let company = convo.attendee?.company {
                        Text(company).font(.subheadline).foregroundStyle(.secondary)
                    }
                    HStack(spacing: 8) {
                        if let type = convo.attendee?.attendeeType, !type.isEmpty {
                            let color = attendeeTypeColor(for: type)
                            Text(type)
                                .font(.caption).bold()
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(color.opacity(0.15))
                                .foregroundStyle(color)
                                .clipShape(Capsule())
                        }
                        Text(convo.createdAt, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text(convo.notes).font(.body).lineLimit(2)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { toggleSelection(for: convo) }
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                // No move in selection mode to avoid confusion
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) { deleteConversation(convo) } label: { Label("Delete", systemImage: "trash") }
            }
        } else {
            // Normal mode: entire row navigates to detail. Chevron is a visual affordance only.
            HStack(alignment: .top, spacing: 12) {
                // No selection indicator
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(convo.attendee?.fullName ?? "Unknown").font(.headline)
                        if convo.followUp {
                            Image(systemName: "flag.fill")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.red, .clear)
                                .accessibilityLabel("Needs follow-up")
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                    }
                    if let company = convo.attendee?.company {
                        Text(company).font(.subheadline).foregroundStyle(.secondary)
                    }
                    HStack(spacing: 8) {
                        if let type = convo.attendee?.attendeeType, !type.isEmpty {
                            let color = attendeeTypeColor(for: type)
                            Text(type)
                                .font(.caption).bold()
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(color.opacity(0.15))
                                .foregroundStyle(color)
                                .clipShape(Capsule())
                        }
                        Text(convo.createdAt, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text(convo.notes).font(.body).lineLimit(2)
                }
            }
            .contentShape(Rectangle())
            .background(
                NavigationLink(value: convo) { EmptyView() }
                    .opacity(0)
            )
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                Button { beginMove(for: convo) } label: { Label("Move", systemImage: "arrowshape.right") }
                    .tint(.blue)
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) { deleteConversation(convo) } label: { Label("Delete", systemImage: "trash") }
            }
        }
    }

    private func attendeeTypeColor(for type: String) -> Color {
        switch type.lowercased() {
        case "speaker": return .purple
        case "vendor": return .orange
        case "organiser": return .blue
        case "attendee": return .gray
        default: return .secondary
        }
    }

    private var moveSheetView: some View {
        NavigationStack {
            Form {
                Section("Move to Event") {
                    Picker("Event", selection: moveTargetBinding) {
                        ForEach(events) { e in
                            if e.persistentModelID != (selectedEvent ?? events.first)?.persistentModelID {
                                Text(e.name).tag(e as Event?)
                            }
                        }
                    }
                    .pickerStyle(.navigationLink)
                }
            }
            .navigationTitle("Move Conversations")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingMoveSheet = false } }
                ToolbarItem(placement: .confirmationAction) { Button("Move") { performMove() }.disabled(moveTargetEvent == nil) }
            }
        }
        .presentationDetents([.medium])
    }

    @ViewBuilder
    private var undoToast: some View {
        if showingUndoToast {
            HStack(spacing: 12) {
                Image(systemName: "trash")
                Text("Conversation deleted")
                Spacer()
                Button("Undo") { undoDeletion() }
                    .buttonStyle(.bordered)
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding()
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private var filteredConversations: [Conversation] {
        let base = conversations
        let active = base.filter { $0.deletedAt == nil }
        let scoped: [Conversation]
        if let event = selectedEvent {
            scoped = active.filter { $0.event?.persistentModelID == event.persistentModelID }
        } else {
            scoped = active
        }
        if !search.isEmpty {
            let q = search.lowercased()
            return scoped.filter {
                let name = $0.attendee?.fullName?.lowercased() ?? ""
                let company = $0.attendee?.company?.lowercased() ?? ""
                let notes = $0.notes.lowercased()
                return name.contains(q) || company.contains(q) || notes.contains(q)
            }
        }
        return scoped
    }

    private func toggleSelection(for convo: Conversation) {
        let id = convo.persistentModelID
        if selectedConversationIDs.contains(id) {
            selectedConversationIDs.remove(id)
        } else {
            selectedConversationIDs.insert(id)
        }
    }

    private func deleteSelected() {
        lastDeletedIDs = Array(selectedConversationIDs)
        let toDelete = filteredConversations.filter { selectedConversationIDs.contains($0.persistentModelID) }
        for c in toDelete { c.deletedAt = Date() }
        selectedConversationIDs.removeAll()
        isSelecting = false
        showUndoToast()
    }

    private func nextMoveTarget() -> Event? {
        let current = selectedEvent ?? events.first
        return events.first(where: { $0.persistentModelID != current?.persistentModelID })
    }

    private func performMove() {
        guard let target = moveTargetEvent else { return }
        let toMove = filteredConversations.filter { selectedConversationIDs.contains($0.persistentModelID) }
        for c in toMove { c.event = target }
        selectedConversationIDs.removeAll()
        isSelecting = false
        showingMoveSheet = false
    }

    private func beginMove(for convo: Conversation) {
        moveTargetEvent = nextMoveTarget()
        selectedConversationIDs = [convo.persistentModelID]
        showingMoveSheet = true
    }

    private func deleteConversation(_ convo: Conversation) {
        convo.deletedAt = Date()
        lastDeletedIDs = [convo.persistentModelID]
        showUndoToast()
    }

    @State private var showingUndoToast = false
    @State private var lastDeletedIDs: [PersistentIdentifier] = []
    private func showUndoToast() {
        showingUndoToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
            if showingUndoToast {
                // Finalize deletions after the undo window
                permanentlyPurgeDeleted()
                showingUndoToast = false
            }
        }
    }

    private func permanentlyPurgeDeleted() {
        let purgables = conversations.filter { $0.deletedAt != nil }
        for c in purgables { context.delete(c) }
    }

    private func undoDeletion() {
        let ids = lastDeletedIDs
        for convo in conversations where ids.contains(convo.persistentModelID) {
            convo.deletedAt = nil
        }
        showingUndoToast = false
        lastDeletedIDs.removeAll()
    }
}


