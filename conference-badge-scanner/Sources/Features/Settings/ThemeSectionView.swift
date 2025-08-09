import SwiftUI

struct ThemeSectionView: View {
    let selectedTheme: AppTheme
    let onSelect: (AppTheme) -> Void

    private let themeOptions: [AppTheme] = [.light, .dark, .system]

    var body: some View {
        GroupBox("Theme") {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(themeOptions) { theme in
                    Button {
                        onSelect(theme)
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: theme.symbolName)
                                .foregroundStyle(.secondary)
                                .frame(width: 22)
                                .padding(.top, 2)
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(theme.title)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    if theme == selectedTheme {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.tint)
                                    }
                                }
                                Text(theme.subtitle)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(theme == selectedTheme ? Color.accentColor.opacity(0.12) : Color.clear)
                        )
                    }
                    .buttonStyle(.plain)
                    if theme != themeOptions.last {
                        Divider().padding(.leading, 34)
                    }
                }
            }
        }
    }
}

#Preview {
    ThemeSectionView(selectedTheme: .system, onSelect: { _ in })
        .padding()
}


