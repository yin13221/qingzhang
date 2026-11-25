import SwiftUI
import Foundation

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}

enum Theme {
    static let ink = Color(hex: 0x1B2434)
    static let secondary = Color(hex: 0x8A93A6)
    static let accent = Color(hex: 0x4C6FFF)
    static let violet = Color(hex: 0x8A5CFF)
    static let mint = Color(hex: 0x23B98B)
}

extension Decimal {
    var asDouble: Double { NSDecimalNumber(decimal: self).doubleValue }
}

func money(_ value: Decimal) -> String {
    let n = NSDecimalNumber(decimal: value).doubleValue
    return "¥" + n.formatted(.number.grouping(.automatic).precision(.fractionLength(2)))
}

func money(_ value: Double) -> String {
    money(Decimal(value))
}

extension View {
    @ViewBuilder
    func glassCard(_ radius: CGFloat = 28) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular, in: shape)
        } else {
            self
                .background(.ultraThinMaterial, in: shape)
                .overlay(shape.strokeBorder(.white.opacity(0.65), lineWidth: 1))
                .shadow(color: Theme.ink.opacity(0.07), radius: 24, y: 12)
        }
    }

    @ViewBuilder
    func glassCapsule() -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular.interactive(), in: Capsule())
        } else {
            self
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().strokeBorder(.white.opacity(0.75), lineWidth: 1))
                .shadow(color: Theme.ink.opacity(0.06), radius: 12, y: 6)
        }
    }
}

struct AuroraBackground: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24.0)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            ZStack {
                Color(hex: 0xF5F6FA)
                blob(0xC9D5FF, 440, x: -70 + sin(t * 0.16) * 46, y: -300 + cos(t * 0.12) * 36, o: 0.85)
                blob(0xC4F0E1, 400, x: 150 + cos(t * 0.11) * 52, y: 280 + sin(t * 0.15) * 44, o: 0.75)
                blob(0xFFD9C2, 320, x: -160 + sin(t * 0.09) * 34, y: 100 + cos(t * 0.17) * 40, o: 0.6)
                blob(0xDCCBFF, 300, x: 120 + sin(t * 0.13) * 40, y: -60 + cos(t * 0.10) * 30, o: 0.5)
            }
            .ignoresSafeArea()
        }
    }

    private func blob(_ hex: UInt32, _ size: CGFloat, x: CGFloat, y: CGFloat, o: Double) -> some View {
        Circle()
            .fill(Color(hex: hex))
            .frame(width: size, height: size)
            .blur(radius: 90)
            .opacity(o)
            .offset(x: x, y: y)
    }
}

func makeDateFormatter(_ format: String) -> DateFormatter {
    let f = DateFormatter()
    f.locale = Locale(identifier: "zh_CN")
    f.dateFormat = format
    return f
}