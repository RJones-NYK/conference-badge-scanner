//
//  conference_badge_scannerApp.swift
//  conference-badge-scanner
//
//  Created by Robert Jones on 08/08/2025.
//

import SwiftUI
import SwiftData

@main
struct ConferenceBadgeScannerApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Event.self,
            Attendee.self,
            Conversation.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}

