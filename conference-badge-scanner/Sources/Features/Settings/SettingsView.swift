import SwiftUI

struct SettingsView: View {
    var body: some View {
        Form {
            Section("General") {
                Label("Settings coming soon", systemImage: "gear")
            }
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    NavigationStack { SettingsView() }
}


