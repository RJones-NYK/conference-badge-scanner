import SwiftUI
import SwiftData

struct EventDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.openURL) private var openURL

    let event: Event

    @State private var isEditing = false
    @State private var name: String = ""
    @State private var start: Date = Date()
    @State private var end: Date = Date()
    @State private var details: String = ""
    @State private var website: String = ""
    @State private var location: String = ""
    @State private var confirmDelete = false
    @State private var showingBadgeConfig = false

    var body: some View {
        Form {
            if !isEditing {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label(event.name, systemImage: "calendar")
                            .font(.headline)
                        HStack(spacing: 6) {
                            Text(start, format: .dateTime.month().day().year())
                            if let end = event.endDate {
                                Text("–")
                                Text(end, format: .dateTime.month().day().year())
                            }
                        }
                        .foregroundStyle(.secondary)
                        if let loc = event.location, !loc.isEmpty {
                            Label(loc, systemImage: "mappin.and.ellipse")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            Section("Event Name") {
                TextField("Event name", text: $name)
                    .disabled(!isEditing)
            }

            Section("Schedule") {
                DatePicker("Start", selection: $start, displayedComponents: [.date])
                    .disabled(!isEditing)
                DatePicker("End", selection: Binding(get: { max(end, start) }, set: { end = max($0, start) }), displayedComponents: [.date])
                    .disabled(!isEditing)
            }

            Section("Details") {
                TextField("Details", text: $details, axis: .vertical)
                    .lineLimit(3, reservesSpace: true)
                    .disabled(!isEditing)
            }

            Section("Website & Location") {
                if isEditing {
                    TextField("Website", text: $website)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                    TextField("Location (address)", text: $location)
                } else {
                    if let url = normalizedWebsiteURL() {
                        Link(destination: url) {
                            Label(websiteDisplayTitle(for: url), systemImage: "link")
                        }
                    }
                    if !location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Button {
                            if let url = mapsURL(for: location) { openURL(url) }
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Label("Open in Maps", systemImage: "map")
                                Text(location).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            Section {
                HStack {
                    Spacer()
                    Button {
                        showingBadgeConfig = true
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: "person.text.rectangle.fill")
                                .font(.system(size: 36, weight: .semibold))
                            Text("Configure Badge")
                                .font(.headline)
                        }
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .accessibilityLabel("Configure Badge")
                    Spacer()
                }
            }

            Section {
                Button(role: .destructive) {
                    confirmDelete = true
                } label: {
                    Label("Delete Event", systemImage: "trash")
                }
            }
        }
        .navigationTitle(event.name)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                if isEditing {
                    Button("Cancel") {
                        loadFromEvent()
                        isEditing = false
                    }
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button(isEditing ? "Save" : "Edit") {
                    if isEditing {
                        saveToEvent()
                    }
                    isEditing.toggle()
                }
            }
        }
        .onAppear(perform: loadFromEvent)
        .sheet(isPresented: $showingBadgeConfig) {
            BadgeConfigurationView(event: event)
        }
        .alert("Delete Event?", isPresented: $confirmDelete) {
            Button("Delete", role: .destructive) {
                context.delete(event)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove the event and its conversations.")
        }
    }

    private func loadFromEvent() {
        name = event.name
        start = event.startDate
        end = event.endDate ?? start
        details = event.details ?? ""
        website = event.website ?? ""
        location = event.location ?? ""
    }

    private func saveToEvent() {
        event.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        event.startDate = start
        event.endDate = end
        event.details = details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : details
        event.website = website.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : website
        event.location = location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : location
    }

    private func normalizedWebsiteURL() -> URL? {
        let trimmed = website.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if let url = URL(string: trimmed), url.scheme != nil { return url }
        return URL(string: "https://" + trimmed)
    }

    private func websiteDisplayTitle(for url: URL) -> String {
        if let host = url.host { return host }
        return url.absoluteString
    }

    private func mapsURL(for address: String) -> URL? {
        let q = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return nil }
        let esc = q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? q
        return URL(string: "http://maps.apple.com/?q=\(esc)")
    }
}


