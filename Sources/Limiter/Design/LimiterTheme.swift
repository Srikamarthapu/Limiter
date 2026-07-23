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
                background: Color(hex: 0x0D1513),
                surface: Color(hex: 0x14211E),
                elevatedSurface: Color(hex: 0x1D302B),
                ink: Color(hex: 0xF3EFE6),
                secondaryInk: Color(hex: 0xAEBAB4),
                pine: Color(hex: 0x91B7AB),
                amber: Color(hex: 0xE3A33B),
                success: Color(hex: 0x8FC9B8),
                danger: Color(hex: 0xFF8E8E),
                border: Color.white.opacity(0.13)
            )
        }
        return LimiterPalette(
            background: Color(hex: 0xF6F2EA),
            surface: Color(hex: 0xFFFCF6),
            elevatedSurface: Color(hex: 0xEFE9DD),
            ink: Color(hex: 0x172321),
            secondaryInk: Color(hex: 0x52605D),
            pine: Color(hex: 0x315B52),
            amber: Color(hex: 0xC97916),
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
