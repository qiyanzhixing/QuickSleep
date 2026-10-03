import SwiftUI

struct SleepPalette {
    let background: Color
    let surface: Color
    let accent: Color
    let text: Color
    let secondary: Color
    let ink: Color
    static func forScheme(_ scheme: ColorScheme) -> SleepPalette {
        scheme == .dark ? .init(background: Color(hex: 0x080D1B), surface: Color(hex: 0x131A2C), accent: Color(hex: 0xB6A2EF), text: Color(hex: 0xE9E5FB), secondary: Color(hex: 0xBBB5D7), ink: Color(hex: 0x19132B)) :
            .init(background: Color(hex: 0xF7F4F0), surface: Color(hex: 0xEDE7EF), accent: Color(hex: 0x78618F), text: Color(hex: 0x332C3F), secondary: Color(hex: 0x60536F), ink: Color(hex: 0xFCF8FF))
    }
}
extension Color {
    init(hex: UInt32) { self.init(red: Double((hex >> 16) & 255)/255, green: Double((hex >> 8) & 255)/255, blue: Double(hex & 255)/255) }
}

struct PrimaryButton: View {
    let title: String
    let palette: SleepPalette
    let action: () -> Void
    var body: some View {
        Button(action: action) { Text(title).frame(maxWidth: .infinity).padding(.vertical, 18).foregroundStyle(palette.ink) }
            .background(palette.accent, in: RoundedRectangle(cornerRadius: 18))
    }
}

struct BreathingOrb: View {
    var frame: Frame? = nil
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private static let night: UIImage? = image("orb_night")
    private static let light: UIImage? = image("orb_light")
    private static func image(_ name: String) -> UIImage? {
        Bundle.main.resourceURL.map { UIImage(contentsOfFile: $0.appendingPathComponent("assets/visual/\(name).png").path) } ?? nil
    }
    private var scale: Double {
        guard let frame, !reduceMotion else { return 1 }
        let local = frame.elapsed.truncatingRemainder(dividingBy: 19)
        switch frame.phase {
        case .inhale: return 0.8 + 0.2 * local / 4
        case .hold: return 1
        case .exhale: return 1 - 0.2 * (local - 11) / 8
        default: return 0.9
        }
    }
    var body: some View {
        Group {
            if let image = scheme == .dark ? Self.night : Self.light {
                Image(uiImage: image).resizable().interpolation(.high).scaledToFit()
            }
        }
        .frame(width: 164, height: 164).scaleEffect(scale).frame(width: 134, height: 134)
        .opacity(frame?.phase == .complete ? 0.5 : 1)
        .padding(.vertical, 14).accessibilityHidden(true)
    }
}
