import SwiftUI
import SwiftData

struct EventListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Event.startDate, order: .forward) private var events: [Event]
    @State private var showingNew = false

    var body: some View {
        List {
            ForEach(events) { event in
                NavigationLink(destination: EventDetailView(event: event)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(event.name)
                            .font(.headline)

                        HStack(spacing: 4) {
                            Text(event.startDate, format: Date.FormatStyle(date: .abbreviated, time: .omitted))
                            if let end = event.endDate {
                                Text("–")
                                Text(end, format: Date.FormatStyle(date: .abbreviated, time: .omitted))
                            }
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                        if let details = event.details, !details.isEmpty {
                            Text(details)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                }
            }
            .onDelete(perform: delete)
        }
        .navigationTitle("Events")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingNew = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showingNew) {
            NewEventView { name, start, end, location, details, website in
                let ev = Event(name: name,
                               startDate: start,
                               endDate: end,
                               location: location,
                               details: details,
                               website: website)
                modelContext.insert(ev)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        // Taps navigate to Event detail for view/edit/delete
    }

    private func delete(at offsets: IndexSet) {
        for idx in offsets { modelContext.delete(events[idx]) }
    }
}


