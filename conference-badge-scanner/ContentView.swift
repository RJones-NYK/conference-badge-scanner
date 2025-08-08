//
//  ContentView.swift
//  conference-badge-scanner
//
//  Created by Robert Jones on 08/08/2025.
//

import SwiftUI

struct ContentView: View {
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
        }
    }
}

#Preview {
    ContentView()
}
