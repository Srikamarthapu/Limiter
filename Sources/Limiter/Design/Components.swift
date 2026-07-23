import SwiftUI

struct SurfaceCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        let palette = LimiterPalette.resolve(colorScheme)
        content
            .padding(18)
            .background(palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(palette.border, lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.14 : 0.045), radius: 10, y: 4)
    }
}

struct QuietPanel<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        let palette = LimiterPalette.resolve(colorScheme)
        content
            .padding(18)
            .background(palette.elevatedSurface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(palette.border, lineWidth: 1)
            }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        let palette = LimiterPalette.resolve(colorScheme)
        configuration.label
            .font(.system(.body, design: .rounded, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .frame(minHeight: 44)
            .background(isEnabled ? palette.pine : palette.pine.opacity(0.42))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .opacity(configuration.isPressed ? 0.82 : 1)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.985 : 1)
            .animation(reduceMotion ? nil : LimiterMotion.quick, value: configuration.isPressed)
    }
}

struct AmberButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        let palette = LimiterPalette.resolve(colorScheme)
        configuration.label
            .font(.system(.body, design: .rounded, weight: .semibold))
            .foregroundStyle(Color(hex: 0x172321))
            .padding(.horizontal, 20)
            .frame(minHeight: 44)
            .background(isEnabled ? palette.amber : palette.amber.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .opacity(configuration.isPressed ? 0.82 : 1)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.985 : 1)
            .animation(reduceMotion ? nil : LimiterMotion.quick, value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        let palette = LimiterPalette.resolve(colorScheme)
        configuration.label
            .font(.system(.body, design: .rounded, weight: .medium))
            .foregroundStyle(isEnabled ? palette.ink : palette.secondaryInk.opacity(0.6))
            .padding(.horizontal, 16)
            .frame(minHeight: 44)
            .background(palette.elevatedSurface.opacity(configuration.isPressed ? 0.7 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(palette.border, lineWidth: 1)
            }
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.985 : 1)
            .animation(reduceMotion ? nil : LimiterMotion.quick, value: configuration.isPressed)
    }
}

struct StatusPill: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let systemImage: String
    let isPositive: Bool

    var body: some View {
        let palette = LimiterPalette.resolve(colorScheme)
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(isPositive ? palette.success : palette.amber)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background((isPositive ? palette.success : palette.amber).opacity(0.12))
            .clipShape(Capsule())
    }
}

struct MetricCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let value: String
    let systemImage: String
    let tint: Color

    var body: some View {
        let palette = LimiterPalette.resolve(colorScheme)
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                Image(systemName: systemImage)
                    .font(.title2)
                    .foregroundStyle(tint)
                    .frame(width: 38, height: 38)
                    .background(tint.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .accessibilityHidden(true)
                Text(value)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(palette.ink)
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(palette.secondaryInk)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(value)")
    }
}

struct InlineMetric: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let value: String
    let systemImage: String
    let tint: Color

    var body: some View {
        let palette = LimiterPalette.resolve(colorScheme)
        HStack(spacing: 11) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(tint.opacity(0.11), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                Text(title)
                    .font(.caption)
                    .foregroundStyle(palette.secondaryInk)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(value)")
    }
}

struct SectionHeader: View {
    @Environment(\.colorScheme) private var colorScheme
    let eyebrow: String
    let title: String
    let subtitle: String

    var body: some View {
        let palette = LimiterPalette.resolve(colorScheme)
        VStack(alignment: .leading, spacing: 6) {
            Text(eyebrow.uppercased())
                .font(.caption2.weight(.bold))
                .tracking(1.4)
                .foregroundStyle(palette.amber)
            Text(title)
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(palette.ink)
            Text(subtitle)
                .font(.body)
                .foregroundStyle(palette.secondaryInk)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct EmptyStateView: View {
    @Environment(\.colorScheme) private var colorScheme
    let systemImage: String
    let title: String
    let message: String

    var body: some View {
        let palette = LimiterPalette.resolve(colorScheme)
        VStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 34, weight: .medium))
                .foregroundStyle(palette.pine)
                .accessibilityHidden(true)
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(palette.ink)
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundStyle(palette.secondaryInk)
                .frame(maxWidth: 420)
        }
        .padding(40)
    }
}
