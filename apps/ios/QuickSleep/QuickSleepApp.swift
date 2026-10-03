import SwiftUI

@main struct QuickSleepApp: App {
    @StateObject private var settings = SettingsStore()
    @StateObject private var audio = PlaybackController()
    var body: some Scene {
        WindowGroup {
            QuickSleepView()
                .environmentObject(settings)
                .environmentObject(audio)
                .preferredColorScheme(settings.colorScheme)
                .tint(Color(red: 0.60, green: 0.48, blue: 0.73))
        }
    }
}
