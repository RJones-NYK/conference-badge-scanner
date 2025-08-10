import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Image(systemName: "person.crop.rectangle.stack")
                        .font(.system(size: 48))
                        .frame(maxWidth: .infinity)
                        .padding(.top, 24)

                    Text("Conference Badge Scanner")
                        .font(.title2).bold()
                    Text("Version 1.0.0")
                        .foregroundStyle(.secondary)

                    Text("This app helps you quickly scan, parse, and manage conversations and attendees at conferences.")
                }
                .padding()
            }
            .navigationTitle("About")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .interactiveDismissDisabled(false)
    }
}

#Preview {
    AboutView()
}


