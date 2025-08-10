import SwiftUI
import SwiftData
import Charts

struct AnalyticsView: View {
    @Query private var events: [Event]
    @Query private var conversationsThisYear: [Conversation]

    @State private var eventsFilter: EventsFilter = .upcoming

    init() {
        // Configure queries (sorted events; conversations filtered to the current year and not soft-deleted)
        let calendar = Calendar.current
        let now = Date()
        let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: now)) ?? now
        let startOfNextYear = calendar.date(byAdding: .year, value: 1, to: startOfYear) ?? now

        _events = Query(sort: \Event.startDate, order: .forward)
        _conversationsThisYear = Query(filter: #Predicate<Conversation> { conv in
            conv.deletedAt == nil && conv.createdAt >= startOfYear && conv.createdAt < startOfNextYear
        })
    }

    var body: some View {
        List {
            // KPI CARDS
            Section("Overview") {
                KPIGrid(
                    eventsThisYear: eventsThisYearCount,
                    conversationsThisYear: conversationsThisYear.count,
                    avgConversationsPerEvent: averageConversationsPerEvent,
                    topEvent: topEventThisYear
                )
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }

            // MONTHLY CHART
            Section("Conversations by Month (This Year)") {
                if monthlyCounts.isEmpty {
                    Text("No conversations yet this year.")
                        .foregroundStyle(.secondary)
                } else {
                    Chart(monthlyCounts) { item in
                        BarMark(
                            x: .value("Month", item.monthStart, unit: .month),
                            y: .value("Conversations", item.count)
                        )
                        .foregroundStyle(.blue.gradient)
                    }
                    .frame(height: 180)
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .month)) { _ in
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel(format: .dateTime.month(.abbreviated))
                        }
                    }
                }
            }

            // EVENTS LIST
            Section {
                Picker("Filter", selection: $eventsFilter) {
                    Text("Upcoming").tag(EventsFilter.upcoming)
                    Text("Past").tag(EventsFilter.past)
                }
                .pickerStyle(.segmented)
            }

            Section(eventsFilter == .upcoming ? "Upcoming Events" : "Past Events") {
                let list = eventsFilter == .upcoming ? upcomingEvents : pastEvents
                if list.isEmpty {
                    Text(eventsFilter == .upcoming ? "No upcoming events" : "No past events")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(list) { event in
                        NavigationLink(destination: EventDetailView(event: event)) {
                            EventRow(event: event, totalConversations: totalConversations(for: event))
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Analytics")
    }

    // MARK: - Derived Data

    private var eventsThisYearCount: Int {
        let cal = Calendar.current
        let year = cal.component(.year, from: Date())
        return events.filter { cal.component(.year, from: $0.startDate) == year }.count
    }

    private var averageConversationsPerEvent: Double {
        let evCount = max(eventsThisYearCount, 1)
        return Double(conversationsThisYear.count) / Double(evCount)
    }

    private var topEventThisYear: (name: String, count: Int)? {
        let cal = Calendar.current
        let year = cal.component(.year, from: Date())
        let pairs: [(Event, Int)] = events
            .filter { cal.component(.year, from: $0.startDate) == year }
            .map { ev in
                let count = ev.conversations.filter { conv in
                    conv.deletedAt == nil && cal.component(.year, from: conv.createdAt) == year
                }.count
                return (ev, count)
            }
        guard let best = pairs.max(by: { $0.1 < $1.1 }), best.1 > 0 else { return nil }
        return (best.0.name, best.1)
    }

    private var monthlyCounts: [MonthlyCount] {
        let cal = Calendar.current
        var buckets: [Date: Int] = [:]
        for conv in conversationsThisYear {
            let comps = cal.dateComponents([.year, .month], from: conv.createdAt)
            if let monthStart = cal.date(from: comps) {
                buckets[monthStart, default: 0] += 1
            }
        }
        let sorted = buckets.keys.sorted()
        return sorted.map { MonthlyCount(monthStart: $0, count: buckets[$0] ?? 0) }
    }

    private var upcomingEvents: [Event] {
        let today = Calendar.current.startOfDay(for: Date())
        return events.filter { effectiveEndDate(for: $0) >= today }
    }

    private var pastEvents: [Event] {
        let today = Calendar.current.startOfDay(for: Date())
        return events.filter { effectiveEndDate(for: $0) < today }
    }

    private func effectiveEndDate(for event: Event) -> Date {
        event.endDate ?? event.startDate
    }

    private func totalConversations(for event: Event) -> Int {
        event.conversations.filter { $0.deletedAt == nil }.count
    }
}

// MARK: - Types & Subviews

private enum EventsFilter: Hashable { case upcoming, past }

private struct MonthlyCount: Identifiable {
    var id: Date { monthStart }
    let monthStart: Date
    let count: Int
}

    private struct KPIGrid: View {
    let eventsThisYear: Int
    let conversationsThisYear: Int
    let avgConversationsPerEvent: Double
    let topEvent: (name: String, count: Int)?

        private var columns: [GridItem] {
            [GridItem(.flexible(minimum: 100), spacing: 12), GridItem(.flexible(minimum: 100), spacing: 12)]
        }

    var body: some View {
            LazyVGrid(columns: columns, spacing: 12) {
            AnalyticsCard(title: "Events this year",
                          value: "\(eventsThisYear)",
                          systemImage: "calendar",
                          tint: .purple)
            AnalyticsCard(title: "Conversations this year",
                          value: "\(conversationsThisYear)",
                          systemImage: "person.2",
                          tint: .blue)
            AnalyticsCard(title: "Avg conv/event",
                          value: String(format: "%.1f", avgConversationsPerEvent),
                          systemImage: "chart.bar.xaxis",
                          tint: .orange)
            AnalyticsCard(title: "Top event",
                          value: topEvent.map { "\($0.count)" } ?? "—",
                          systemImage: "star.fill",
                          tint: .yellow)
        }
    }
}

private struct EventRow: View {
    let event: Event
    let totalConversations: Int

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(event.name)
                    .font(.headline)
                HStack(spacing: 4) {
                    Text(event.startDate, format: Date.FormatStyle(date: .abbreviated, time: .omitted))
                    if let end = event.endDate { Text("–"); Text(end, format: Date.FormatStyle(date: .abbreviated, time: .omitted)) }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            Spacer()
            if totalConversations > 0 {
                Label("\(totalConversations)", systemImage: "bubble.left.and.bubble.right")
                    .labelStyle(.titleAndIcon)
                    .font(.subheadline)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.thinMaterial, in: Capsule())
            }
        }
    }
}

#Preview {
    NavigationStack { AnalyticsView() }
}


