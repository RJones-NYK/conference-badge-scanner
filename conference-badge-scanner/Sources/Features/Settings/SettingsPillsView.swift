import SwiftUI

struct SettingsPillsView: View {
    let aboutAction: () -> Void
    let privacyAction: () -> Void

    var body: some View {
        GroupBox {
            HStack(spacing: 16) {
                Button(action: aboutAction) {
                    Text("About")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .controlSize(.small)

                Button(action: privacyAction) {
                    Text("Privacy Policy")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .controlSize(.small)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    SettingsPillsView(aboutAction: {}, privacyAction: {})
        .padding()
}


