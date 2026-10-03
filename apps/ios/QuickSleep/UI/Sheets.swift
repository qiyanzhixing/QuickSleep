import SwiftUI

struct SoundPickerSheet: View {
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var audio: PlaybackController
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    private func t(_ key: String) -> String { localized(key, language: settings.language) }
    var body: some View {
        let p = SleepPalette.forScheme(scheme)
        ScrollView {
            VStack(spacing: 16) {
                Text(t("soundMode")).font(.custom("NotoSerifSC-ExtraLight", size: 24, relativeTo: .title))
                Text(t("soundHint")).multilineTextAlignment(.center)
                ForEach(SoundMode.allCases, id: \.self) { mode in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .center) {
                            Button { settings.update { $0.mode = mode } } label: {
                                HStack {
                                    Image(systemName: settings.value.mode == mode ? "largecircle.fill.circle" : "circle")
                                    Text(t(mode.nameKey)).font(.custom("NotoSerifSC-ExtraLight", size: 20, relativeTo: .title3))
                                }.frame(minHeight: 44)
                            }.accessibilityAddTraits(settings.value.mode == mode ? .isSelected : [])
                            Spacer(minLength: 8)
                            Button(t(audio.previewMode == mode ? "stopPreview" : "preview")) {
                                if audio.previewMode == mode { audio.closePreview() } else { audio.preview(mode, language: settings.language) }
                            }.frame(minHeight: 44)
                        }
                        Text(t(mode.descriptionKey)).foregroundStyle(p.secondary)
                    }.padding(16).background(p.background, in: RoundedRectangle(cornerRadius: 18))
                }
                if audio.status == .error { Text(t("previewError")) }
                Button(t("close")) { audio.closePreview(); dismiss() }.frame(minHeight: 48)
            }.padding(24)
        }.background(p.surface).foregroundStyle(p.text).tint(p.accent)
            .font(.custom("NotoSansSC-Thin", size: 17, relativeTo: .body))
    }
}

struct SettingsSheet: View {
    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    private func t(_ key: String) -> String { localized(key, language: settings.language) }
    var body: some View {
        let p = SleepPalette.forScheme(scheme)
        ScrollView {
            VStack(spacing: 12) {
                Text(t("settings")).font(.custom("NotoSerifSC-ExtraLight", size: 24, relativeTo: .title))
                Text(t("language")).padding(.top, 12)
                ForEach(["system", "zh", "en"], id: \.self) { value in
                    option(t(value == "zh" ? "chinese" : value == "en" ? "english" : "system"), selected: settings.value.language == value) { settings.update { $0.language = value } }
                }
                Text(t("theme")).padding(.top, 12)
                ForEach(["system", "night", "light"], id: \.self) { value in
                    option(t(value), selected: settings.value.theme == value) { settings.update { $0.theme = value } }
                }
                Text(t("nextSessionHint")).multilineTextAlignment(.center).padding(.top, 12)
                Text(t("offlineNote")).foregroundStyle(p.secondary).padding(.top, 16)
                Text(t("syntheticNote")).foregroundStyle(p.secondary).multilineTextAlignment(.center)
                Button(t("close")) { dismiss() }.frame(minHeight: 48)
            }.padding(24)
        }.background(p.surface).foregroundStyle(p.text).tint(p.accent)
            .font(.custom("NotoSansSC-Thin", size: 17, relativeTo: .body))
    }
    private func option(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) { HStack { Text(title); Spacer(); Image(systemName: selected ? "checkmark.circle.fill" : "circle") }.frame(minHeight: 48) }
            .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

struct DurationSheet: View {
    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @State private var text = ""
    @State private var invalid = false
    private func t(_ key: String) -> String { localized(key, language: settings.language) }
    var body: some View {
        let p = SleepPalette.forScheme(scheme)
        ScrollView {
            VStack(spacing: 20) {
                Text(t("customTitle")).font(.custom("NotoSerifSC-ExtraLight", size: 24, relativeTo: .title))
                TextField(t("customHint"), text: $text).keyboardType(.numberPad).textFieldStyle(.roundedBorder)
                    .onChange(of: text) { _ in invalid = false }
                Text(t(invalid ? "customError" : "customHint")).multilineTextAlignment(.center)
                PrimaryButton(title: t("save"), palette: p) {
                    guard let minutes = parseMinutes(text) else { invalid = true; return }
                    settings.update { $0.minutes = minutes }; dismiss()
                }
                Button(t("cancel")) { dismiss() }.frame(minHeight: 48)
            }.padding(24)
        }.background(p.surface).foregroundStyle(p.text).tint(p.accent)
            .font(.custom("NotoSansSC-Thin", size: 17, relativeTo: .body))
            .onAppear { text = "\(settings.value.minutes)" }
    }
}

