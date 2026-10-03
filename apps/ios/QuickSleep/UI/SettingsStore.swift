import Foundation
import CoreFoundation
import SwiftUI

struct AppSettings: Codable {
    var minutes = 10
    var mode = SoundMode.moon
    var theme = "system"
    var language = "system"
}

@MainActor final class SettingsStore: ObservableObject {
    @Published private(set) var value: AppSettings
    init() {
        let defaults = UserDefaults.standard
        let data = defaults.data(forKey: "preferences")
        // Read fields independently so a corrupt field doesn't erase valid settings.
        let raw = data.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] } ?? [:]
        var settings = AppSettings()
        if let number = raw["minutes"] as? NSNumber, CFGetTypeID(number) != CFBooleanGetTypeID(),
           number.doubleValue == Double(number.intValue), (2...60).contains(number.intValue) { settings.minutes = number.intValue }
        if let mode = raw["mode"] as? String, let valid = SoundMode(rawValue: mode) { settings.mode = valid }
        if let theme = raw["theme"] as? String, ["system", "night", "light"].contains(theme) { settings.theme = theme }
        if let language = raw["language"] as? String, ["system", "zh", "en"].contains(language) { settings.language = language }
        value = settings
    }
    func update(_ change: (inout AppSettings) -> Void) {
        var next = value
        change(&next)
        guard let data = try? JSONEncoder().encode(next) else { return }
        UserDefaults.standard.set(data, forKey: "preferences")
        value = next
    }
    var language: AppLanguage {
        if let manual = AppLanguage(rawValue: value.language) { return manual }
        let first = Locale.preferredLanguages.first ?? "en"
        return first.lowercased().hasPrefix("zh") ? .zh : .en
    }
    var colorScheme: ColorScheme? { value.theme == "night" ? .dark : value.theme == "light" ? .light : nil }
}

func localized(_ key: String, language: AppLanguage, parameter: String? = nil) -> String {
    let bundle = Bundle.main.path(forResource: language.rawValue, ofType: "lproj").flatMap(Bundle.init(path:)) ?? Bundle.main
    let text = bundle.localizedString(forKey: key, value: key, table: nil)
    return parameter.map { text.replacingOccurrences(of: "{count}", with: $0).replacingOccurrences(of: "{time}", with: $0) } ?? text
}

extension SoundMode {
    var nameKey: String { "mode" + rawValue.prefix(1).uppercased() + rawValue.dropFirst() }
    var descriptionKey: String { "desc" + rawValue.prefix(1).uppercased() + rawValue.dropFirst() }
}
