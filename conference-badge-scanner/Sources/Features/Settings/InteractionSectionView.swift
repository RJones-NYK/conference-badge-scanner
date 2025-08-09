import SwiftUI

struct InteractionSectionView: View {
    @Binding var hapticsStrength: Double

    var body: some View {
        GroupBox("Feedback & Interaction") {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        Image(systemName: "iphone.radiowaves.left.and.right")
                            .foregroundStyle(.blue)
                        Text("Haptic Feedback")
                            .font(.headline)
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { hapticsStrength > 0 },
                            set: { isOn in hapticsStrength = isOn ? max(hapticsStrength, 0.5) : 0 }
                        ))
                        .labelsHidden()
                    }
                    Text("Subtle vibration feedback for key actions. You can turn this off if you prefer a silent experience.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var strength: Double = 0.5
    return InteractionSectionView(hapticsStrength: $strength)
        .padding()
}


