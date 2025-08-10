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

    private let iconColumnWidth: CGFloat = 20
    private let iconSize: CGFloat = 16

    private var hasChanges: Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDetails = details.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedWebsite = website.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLocation = location.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedName != event.name { return true }
        if start != event.startDate { return true }
        if end != (event.endDate ?? start) { return true }
        if (trimmedDetails.isEmpty ? nil : trimmedDetails) != event.details { return true }
        if (trimmedWebsite.isEmpty ? nil : trimmedWebsite) != event.website { return true }
        if (trimmedLocation.isEmpty ? nil : trimmedLocation) != event.location { return true }
        return false
    }

    var body: some View {
        VStack(spacing: 12) {
            Form {
            if !isEditing {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        // Event name row (icon + text), centered and uniform icon sizing
                        HStack(alignment: .center, spacing: 6) {
                            Image(systemName: "lanyardcard")
                                .foregroundStyle(.blue)
                                .font(.system(size: iconSize))
                                .frame(width: iconColumnWidth, alignment: .center)
                            Text(event.name)
                                .font(.body)
                        }

                        // Date row with calendar icon left, centered and uniform icon sizing
                        HStack(alignment: .center, spacing: 6) {
                            Image(systemName: "calendar")
                                .foregroundStyle(.red)
                                .font(.system(size: iconSize))
                                .frame(width: iconColumnWidth, alignment: .center)
                            Text(dateRangeDisplay)
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }

                        // Location row with existing symbol, centered and uniform icon sizing
                        if let loc = event.location, !loc.isEmpty {
                            HStack(alignment: .center, spacing: 6) {
                                Image(systemName: "mappin.and.ellipse")
                                    .foregroundStyle(.green)
                                    .font(.system(size: iconSize))
                                    .frame(width: iconColumnWidth, alignment: .center)
                                Text(loc)
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            Section("Event Name") {
                if isEditing {
                    ClearableTextField("Event name", text: $name)
                } else {
                    LabeledContent("Event Name", value: name)
                }
            }

            Section("Schedule") {
                if isEditing {
                    if #available(iOS 16.0, *) {
                        let binding = Binding<DateInterval?>(
                            get: {
                                DateInterval(start: start, end: end)
                            },
                            set: { newValue in
                                if let v = newValue {
                                    start = v.start
                                    end = max(v.end, v.start)
                                }
                            }
                        )
                        GroupBox {
                            CalendarRangePicker(range: binding)
                                .scaleEffect(0.92)
                                .contentShape(Rectangle())
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 2)
                        }
                        .listRowInsets(EdgeInsets(top: 2, leading: 28, bottom: 2, trailing: 28))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    } else {
                        DatePicker("Start", selection: $start, displayedComponents: [.date])
                        DatePicker("End", selection: Binding(get: { max(end, start) }, set: { end = max($0, start) }), displayedComponents: [.date])
                    }
                } else {
                    LabeledContent("Start", value: start.formatted(.dateTime.month().day().year()))
                    if let endDate = event.endDate {
                        LabeledContent("End", value: endDate.formatted(.dateTime.month().day().year()))
                    }
                }
            }

            Section("Details") {
                if isEditing {
                    ClearableTextField("Details", text: $details, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                } else {
                    if details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("None").foregroundStyle(.secondary)
                    } else {
                        Text(details)
                    }
                }
            }

            Section("Website & Location") {
                if isEditing {
                    ClearableTextField("Website", text: $website)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                    ClearableTextField("Location (address)", text: $location)
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

            }

            // Standalone Configure Badge button outside the form
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
            .padding(.horizontal)
            .padding(.top, 4)

            Section {
                Button(role: .destructive) {
                    confirmDelete = true
                } label: {
                    Label("Delete Event", systemImage: "trash")
                }
            }
        }
        .navigationTitle("Event Details")
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
                .disabled(isEditing && !hasChanges)
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

    private var dateRangeDisplay: String {
        let startText = start.formatted(.dateTime.month().day().year())
        if let endDate = event.endDate {
            let endText = endDate.formatted(.dateTime.month().day().year())
            return "\(startText) – \(endText)"
        }
        return startText
    }
}


