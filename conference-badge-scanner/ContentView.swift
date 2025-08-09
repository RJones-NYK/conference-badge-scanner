//
//  ContentView.swift
//  conference-badge-scanner
//
//  Created by Robert Jones on 08/08/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Query(sort: \Event.startDate, order: .reverse) private var events: [Event]
    var body: some View {
        TabView {
            NavigationStack {
                EventListView()
            }
            .tabItem { Label("Events", systemImage: "calendar") }

            NavigationStack {
                ConversationsListView()
            }
            .tabItem { Label("Conversations", systemImage: "text.bubble") }

            Group {
                if let event = events.first {
                    NewConversationView(event: event, dismissOnSave: false)
                } else {
                    ContentUnavailableView(
                        "No Events",
                        systemImage: "calendar.badge.plus",
                        description: Text("Create an event first on the Events tab.")
                    )
                }
            }
            .tabItem { Label("Capture", systemImage: "camera.viewfinder") }

            NavigationStack {
                AnalyticsView()
            }
            .tabItem { Label("Analytics", systemImage: "chart.bar") }

            NavigationStack {
                SettingsView()
            }
            .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}

#Preview {
    // In-memory SwiftData container so Preview matches runtime
    let schema = Schema([Event.self, Attendee.self, Conversation.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])

    // Seed sample data for visually representative preview
    let context = container.mainContext
    let event = Event(name: "Swift Summit 2025",
                      startDate: Date(),
                      endDate: Calendar.current.date(byAdding: .day, value: 2, to: Date()),
                      location: "San Jose",
                      details: "Networking, talks, and labs.",
                      website: "swift.example.com")
    context.insert(event)

    let attendee = Attendee()
    attendee.fullName = "Taylor Appleseed"
    attendee.company = "Fruit Co."
    attendee.attendeeType = "Speaker"
    context.insert(attendee)

    let convo = Conversation(event: event, attendee: attendee, notes: "Great chat about VisionKit!", followUp: true)
    context.insert(convo)

    return ContentView()
        .modelContainer(container)
}
