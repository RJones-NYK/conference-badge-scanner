import SwiftUI

struct SettingsView: View {
    @AppStorage(AppTheme.storageKey) private var appThemeRaw: String = AppTheme.system.rawValue
    @AppStorage("hapticsStrength") private var hapticsStrength: Double = 0.5

    @State private var activeFullScreen: ActiveSheet?

    private var selectedTheme: AppTheme {
        get { AppTheme(rawValue: appThemeRaw) ?? .system }
        set { appThemeRaw = newValue.rawValue }
    }

    private enum ActiveSheet: Identifiable {
        case about
        case privacy

        var id: String {
            switch self {
            case .about: return "about"
            case .privacy: return "privacy"
            }
        }
    }
    
    // Hoist constants out of the view builder to reduce type-checking load
    private let themeOptions: [AppTheme] = [.light, .dark, .system]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ThemeSectionView(selectedTheme: selectedTheme, onSelect: { theme in
                    appThemeRaw = theme.rawValue
                })

                InteractionSectionView(hapticsStrength: $hapticsStrength)

                SettingsPillsView(
                    aboutAction: { activeFullScreen = .about },
                    privacyAction: { activeFullScreen = .privacy }
                )
            }
            .padding(.horizontal)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .navigationTitle("Settings")
        .fullScreenCover(item: $activeFullScreen) { item in
            switch item {
            case .about:
                AboutView()
            case .privacy:
                PrivacyPolicyView()
            }
        }
    }
}

#Preview {
    NavigationStack { SettingsView() }
}


