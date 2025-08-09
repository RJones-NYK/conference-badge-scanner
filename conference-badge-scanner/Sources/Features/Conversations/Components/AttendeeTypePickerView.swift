import SwiftUI

struct AttendeeTypePickerView: View {
    @Binding var selection: AttendeeType
    var isEnabled: Bool = true

    private func color(for type: AttendeeType) -> Color {
        switch type {
        case .speaker: return .purple
        case .attendee: return .green
        case .vendor: return .orange
        case .organiser: return .blue
        case .other: return .teal
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Attendee Type")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(AttendeeType.allCases) { type in
                        VStack(spacing: 6) {
                            let isSelected = selection == type
                            let baseSize: CGFloat = isSelected ? 64 : 52

                            ZStack {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill((isSelected ? color(for: type) : .gray).opacity(isSelected ? 0.18 : 0.10))
                                Image(systemName: type.iconName)
                                    .font(.system(size: isSelected ? 26 : 22, weight: .semibold))
                                    .foregroundStyle(isSelected ? color(for: type) : .gray)
                            }
                            .frame(width: baseSize, height: baseSize)
                            .scaleEffect(isSelected ? 1.06 : 1.0)
                            .animation(.spring(response: 0.30, dampingFraction: 0.75), value: selection)
                            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .onTapGesture { if isEnabled { withAnimation { selection = type } } }

                            if isSelected {
                                Text(type.displayName)
                                    .font(.caption)
                                    .foregroundStyle(color(for: type))
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(Text(type.displayName))
                        .accessibilityAddTraits(selection == type ? .isSelected : [])
                        .opacity(isEnabled ? 1.0 : 0.5)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}


