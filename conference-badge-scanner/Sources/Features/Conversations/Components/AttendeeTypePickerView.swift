import SwiftUI

struct AttendeeTypePickerView: View {
    @Binding var selection: AttendeeType
    var isEnabled: Bool = true

    private func color(for type: AttendeeType) -> Color {
        switch type {
        case .speaker: return .purple
        case .attendee: return .gray
        case .vendor: return .orange
        case .organiser: return .blue
        case .other: return .secondary
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Attendee Type").font(.subheadline).foregroundStyle(.secondary)
            HStack(spacing: 20) {
                ForEach(AttendeeType.allCases) { type in
                    VStack(spacing: 6) {
                        Image(systemName: type.iconName)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(selection == type ? color(for: type) : .gray)
                        Text(type.displayName)
                            .font(.caption)
                            .foregroundStyle(selection == type ? color(for: type) : .gray)
                    }
                    .padding(8)
                    .background(selection == type ? color(for: type).opacity(0.12) : Color.gray.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .onTapGesture { if isEnabled { selection = type } }
                }
            }
            .padding(.vertical, 4)
        }
    }
}


