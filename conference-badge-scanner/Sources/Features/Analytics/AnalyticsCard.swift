import SwiftUI

struct AnalyticsCard: View {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(alignment: .center, spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(tint)

            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .frame(height: 100)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(tint.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(tint.opacity(0.25), lineWidth: 1)
        )
    }
}

#Preview {
    VStack(spacing: 12) {
        AnalyticsCard(title: "Events this year", value: "7", systemImage: "calendar", tint: .purple)
        AnalyticsCard(title: "Conversations", value: "42", systemImage: "person.2", tint: .blue)
    }
    .padding()
}


