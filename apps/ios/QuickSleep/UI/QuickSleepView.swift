import SwiftUI

private enum Sheet: String, Identifiable { case settings, sounds, duration; var id: String { rawValue } }

struct QuickSleepView: View {
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var audio: PlaybackController
    @Environment(\.colorScheme) private var scheme
    @State private var sheet: Sheet?
    private var palette: SleepPalette { .forScheme(scheme) }
    private func t(_ key: String, _ parameter: String? = nil) -> String { localized(key, language: settings.language, parameter: parameter) }
    private var inSession: Bool { audio.config != nil && [.loading, .active, .complete, .error].contains(audio.status) }

    var body: some View {
        ZStack {
            palette.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {
                    ZStack {
                        Text(inSession ? localized("sessionTitle", language: audio.config?.language ?? settings.language) : "QuickSleep")
                            .font(.custom("NotoSerifSC-ExtraLight", size: 18, relativeTo: .headline)).padding(.horizontal, 48)
                        HStack {
                            Spacer()
                            Button { sheet = .settings } label: { Image(systemName: "slider.horizontal.3") }.accessibilityLabel(t("settings")).frame(minWidth: 44, minHeight: 48)
                        }
                    }
                    .padding(.bottom, 18)
                    if inSession, let config = audio.config { session(config) } else { home }
                }
                .frame(maxWidth: 478).padding(.horizontal, 24).padding(.vertical, 16)
                .frame(maxWidth: .infinity)
            }
        }
        .foregroundStyle(palette.text)
        .font(.custom("NotoSansSC-Thin", size: 17, relativeTo: .body))
        .tint(palette.accent)
        .sheet(item: $sheet, onDismiss: { audio.closePreview() }) { current in
            Group {
                switch current {
                case .sounds: SoundPickerSheet()
                case .settings: SettingsSheet()
                case .duration: DurationSheet()
                }
            }
            .environmentObject(settings).environmentObject(audio)
            .preferredColorScheme(settings.colorScheme)
        }
    }

    private var home: some View {
        VStack(spacing: 0) {
            Text(t("introTitle")).font(.custom("NotoSerifSC-ExtraLight", size: 32, relativeTo: .largeTitle)).multilineTextAlignment(.center)
            Text(t("introSubtitle")).foregroundStyle(palette.secondary).padding(.top, 4).multilineTextAlignment(.center)
            BreathingOrb()
            Text(t("durationTitle"))
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 74))], spacing: 8) {
                ForEach([5, 10, 15, 0], id: \.self) { minutes in
                    let customSelected = ![5,10,15].contains(settings.value.minutes)
                    let selected = minutes == 0 ? customSelected : settings.value.minutes == minutes
                    Button {
                        if minutes == 0 { sheet = .duration } else { settings.update { $0.minutes = minutes } }
                    } label: {
                        Text(minutes == 0 ? (customSelected ? t("minutes", "\(settings.value.minutes)") : t("customDuration")) : t("minutes", "\(minutes)"))
                            .frame(maxWidth: .infinity).padding(.vertical, 12)
                            .foregroundStyle(selected ? palette.ink : palette.secondary)
                            .background(selected ? palette.accent : Color.clear, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
            }
            .padding(8).background(palette.surface, in: RoundedRectangle(cornerRadius: 16)).padding(.top, 12)
            Text(t("durationHint")).font(.custom("NotoSansSC-Thin", size: 13, relativeTo: .footnote)).foregroundStyle(palette.secondary).multilineTextAlignment(.center).padding(.top, 8)
            Button { sheet = .sounds } label: {
                VStack(alignment: .leading, spacing: 8) {
                    HStack { Text(t("soundMode")); Spacer(); Text(t("change") + " ›").foregroundStyle(palette.accent) }
                    Text(t(settings.value.mode.nameKey)).font(.custom("NotoSerifSC-ExtraLight", size: 18, relativeTo: .headline))
                    Text(t(settings.value.mode.descriptionKey)).foregroundStyle(palette.secondary)
                    Text(t("mixedHint")).font(.custom("NotoSansSC-Thin", size: 12, relativeTo: .caption)).foregroundStyle(palette.secondary)
                }.font(.custom("NotoSansSC-Thin", size: 13, relativeTo: .footnote)).frame(maxWidth: .infinity, alignment: .leading).padding(16).background(palette.surface, in: RoundedRectangle(cornerRadius: 20))
            }.buttonStyle(.plain).padding(.top, 12)
            PrimaryButton(title: t("start"), palette: palette) {
                audio.start(.init(minutes: settings.value.minutes, mode: settings.value.mode, language: settings.language))
            }.padding(.top, 56)
            HStack(spacing: 8) {
                Image(systemName: "lock").accessibilityHidden(true)
                Text(t("lockHint"))
            }.font(.custom("NotoSansSC-Thin", size: 13, relativeTo: .footnote)).foregroundStyle(palette.secondary).padding(.top, 14)
            if audio.status == .error { Text(t("audioError")).padding(.top, 16).multilineTextAlignment(.center) }
        }
        .padding(.bottom, 24)
    }

    private func session(_ config: SessionConfig) -> some View {
        let plan = try! SessionPlan(config: config) // Config was validated before status becomes loading.
        let frame = plan.frame(at: audio.elapsed)
        func copy(_ key: String, _ parameter: String? = nil) -> String { localized(key, language: config.language, parameter: parameter) }
        let phaseKey: String
        switch frame.phase {
        case .inhale: phaseKey = "inhale"
        case .hold: phaseKey = "hold"
        case .exhale: phaseKey = "exhale"
        case .fade: phaseKey = "fading"
        default: phaseKey = "natural"
        }
        let title = audio.status == .loading ? "loading" : audio.status == .error ? "audioError" : audio.status == .complete ? "completed" : !audio.playing ? "paused" : phaseKey
        let remaining = Int(ceil(frame.remaining))
        return VStack(spacing: 0) {
            Text(copy(config.mode.nameKey)).foregroundStyle(palette.secondary)
            BreathingOrb(frame: frame)
            Text(copy(title)).font(.custom("NotoSerifSC-ExtraLight", size: 32, relativeTo: .largeTitle)).multilineTextAlignment(.center)
            if let count = frame.count, audio.status == .active {
                Text("\(count)").font(.custom("NotoSansSC-Thin", size: 48, relativeTo: .largeTitle)).foregroundStyle(palette.accent)
                Text(copy("round", "\(frame.cycle ?? 1)"))
            }
            Text(copy("remaining", String(format: "%02d:%02d", remaining / 60, remaining % 60))).padding(.vertical, 24)
            if audio.status == .active {
                PrimaryButton(title: copy(audio.playing ? "pause" : "resume"), palette: palette) { if audio.playing { audio.pause() } else { audio.play() } }
            }
            Button(copy([.error, .complete].contains(audio.status) ? "backHome" : "end")) { audio.stop() }.frame(minHeight: 48).padding(.top, 8)
            Text(copy("safetyHint")).font(.custom("NotoSansSC-Thin", size: 13, relativeTo: .footnote)).foregroundStyle(palette.secondary).multilineTextAlignment(.center).padding(.top, 24)
        }.padding(.bottom, 24)
    }
}
