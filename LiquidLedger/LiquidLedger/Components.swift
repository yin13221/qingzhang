import SwiftUI
import UIKit

struct NumberStepperField: View {
    @Binding var value: Double
    var step: Double
    var range: ClosedRange<Double>
    var width: CGFloat = 62

    var body: some View {
        HStack(spacing: 6) {
            stepButton("−") {
                apply(value - step)
            }
            TextField("0", value: $value, format: .number.precision(.fractionLength(0...3)))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .font(.system(size: 13, weight: .semibold).monospacedDigit())
                .foregroundStyle(Theme.ink)
                .frame(width: width)
            stepButton("+") {
                apply(value + step)
            }
        }
        .padding(4)
        .background(Capsule().fill(.white.opacity(0.55)))
        .overlay(Capsule().strokeBorder(.white.opacity(0.75), lineWidth: 1))
    }

    private func stepButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .frame(width: 26, height: 26)
                .background(Circle().fill(.white.opacity(0.85)))
        }
        .buttonStyle(.plain)
    }

    private func apply(_ raw: Double) {
        let rounded = (raw * 1000).rounded() / 1000
        value = min(range.upperBound, max(range.lowerBound, rounded))
        UISelectionFeedbackGenerator().selectionChanged()
    }
}

struct SheetBackground: View {
    var body: some View {
        AuroraBackground()
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 40,
                    topTrailingRadius: 40,
                    style: .continuous
                )
            )
            .ignoresSafeArea()
    }
}

struct ChipView: View {
    let title: String
    var dotColor: Color?
    let selected: Bool
    let action: () -> Void

    init(_ title: String, dotColor: Color? = nil, selected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.dotColor = dotColor
        self.selected = selected
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let dotColor {
                    Circle()
                        .fill(dotColor)
                        .frame(width: 7, height: 7)
                }
                Text(title)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundStyle(selected ? Color.white : Theme.ink)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background {
                Capsule().fill(
                    selected
                        ? AnyShapeStyle(Theme.accent.gradient)
                        : AnyShapeStyle(Color.white.opacity(0.55))
                )
            }
            .overlay {
                Capsule().strokeBorder(
                    selected ? Color.clear : Color.white.opacity(0.75),
                    lineWidth: 1
                )
            }
        }
        .buttonStyle(.plain)
    }
}

struct PressScaleStyle: ButtonStyle {
    var scale: CGFloat = 0.9

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.snappy(duration: 0.15), value: configuration.isPressed)
    }
}

struct FilterSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.secondary)
            content
        }
    }
}

struct ChipGrid<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 70), spacing: 8)],
            alignment: .leading,
            spacing: 8
        ) {
            content
        }
    }
}

extension View {
    func keyboardDoneButton() -> some View {
        toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("完成") {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil,
                        from: nil,
                        for: nil
                    )
                }
            }
        }
    }

    func edgeSwipeBack(_ action: @escaping () -> Void) -> some View {
        modifier(EdgeSwipeBackModifier(action: action))
    }
}

private struct EdgeSwipeBackModifier: ViewModifier {
    let action: () -> Void

    func body(content: Content) -> some View {
        content.simultaneousGesture(
            DragGesture(minimumDistance: 20, coordinateSpace: .global)
                .onEnded { value in
                    guard value.startLocation.x < 40,
                          value.translation.width > 80,
                          abs(value.translation.height) < 120 else { return }
                    action()
                }
        )
    }
}