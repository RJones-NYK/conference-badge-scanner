import SwiftUI

struct ConfidencePill: View {
    let confidence: Double // 0...1

    private var color: Color {
        switch confidence {
        case ..<0.5: return .red
        case 0.5..<0.75: return .orange
        default: return .green
        }
    }

    private var label: String {
        let pct = Int((confidence * 100).rounded())
        return "\(pct)%"
    }

    var body: some View {
        Text(label)
            .font(.caption2)
            .bold()
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(color.opacity(0.15), in: Capsule())
            .foregroundStyle(color)
            .accessibilityLabel(Text("Confidence \(Int((confidence * 100).rounded())) percent"))
    }
}



