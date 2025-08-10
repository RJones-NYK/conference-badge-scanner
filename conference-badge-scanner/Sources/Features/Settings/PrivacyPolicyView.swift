import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Privacy Policy")
                        .font(.title2).bold()
                        .padding(.top, 24)

                    Text("We value your privacy. This app processes images locally to extract badge information. No data is sent to external servers without your consent.")
                    Text("You can delete captured images and conversations at any time.")
                    Text("For questions, contact support@example.com.")
                }
                .padding()
            }
            .navigationTitle("Privacy Policy")
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
    PrivacyPolicyView()
}


