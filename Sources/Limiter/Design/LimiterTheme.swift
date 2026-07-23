import AppKit
import SwiftUI

struct LimiterPalette {
    let background: Color
    let surface: Color
    let elevatedSurface: Color
    let ink: Color
    let secondaryInk: Color
    let pine: Color
    let amber: Color
    let success: Color
    let danger: Color
    let border: Color

    static func resolve(_ colorScheme: ColorScheme) -> LimiterPalette {
        if colorScheme == .dark {
            return LimiterPalette(
                background: Color(hex: 0x111816),
                surface: Color(hex: 0x192321),
                elevatedSurface: Color(hex: 0x22302D),
                ink: Color(hex: 0xF5F2EA),
                secondaryInk: Color(hex: 0xC5CBC6),
                pine: Color(hex: 0x79A99C),
                amber: Color(hex: 0xF0B353),
                success: Color(hex: 0x7EC4B2),
                danger: Color(hex: 0xFF8E8E),
                border: Color.white.opacity(0.12)
            )
        }
        return LimiterPalette(
            background: Color(hex: 0xF6F2EA),
            surface: .white,
            elevatedSurface: Color(hex: 0xFFFCF6),
            ink: Color(hex: 0x172321),
            secondaryInk: Color(hex: 0x52605D),
            pine: Color(hex: 0x315B52),
            amber: Color(hex: 0xD58B26),
            success: Color(hex: 0x2E6E60),
            danger: Color(hex: 0xB84242),
            border: Color(hex: 0x172321).opacity(0.10)
        )
    }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

enum LimiterMotion {
    static let quick = Animation.easeOut(duration: 0.18)
    static let standard = Animation.spring(duration: 0.26, bounce: 0.12)
}

struct AppBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        LimiterPalette.resolve(colorScheme).background
            .ignoresSafeArea()
    }
}

struct AppIconView: View {
    let path: String?
    let size: CGFloat
    var fallbackSystemImage = "app.fill"

    var body: some View {
        Group {
            if let path, !path.isEmpty {
                Image(nsImage: NSWorkspace.shared.icon(forFile: path))
                    .resizable()
                    .interpolation(.high)
            } else {
                Image(systemName: fallbackSystemImage)
                    .resizable()
                    .scaledToFit()
                    .padding(size * 0.18)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
